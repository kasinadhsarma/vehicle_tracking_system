import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';

/// Advanced geofencing service for vehicle tracking
/// Implements circular and polygonal geofences with smart notifications
class GeofenceService {
  static GeofenceService? _instance;
  static GeofenceService get instance => _instance ??= GeofenceService._();
  
  GeofenceService._();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Active geofences
  final Map<String, Geofence> _activeGeofences = {};
  final Map<String, GeofenceStatus> _geofenceStatuses = {};
  
  // Notification callbacks
  final List<Function(GeofenceEvent)> _eventListeners = [];
  
  // Stream controllers
  final StreamController<GeofenceEvent> _eventController = 
      StreamController<GeofenceEvent>.broadcast();
  
  bool _isInitialized = false;
  bool _isMonitoring = false;

  // Public getters
  bool get isInitialized => _isInitialized;
  bool get isMonitoring => _isMonitoring;
  Stream<GeofenceEvent> get eventStream => _eventController.stream;
  List<Geofence> get activeGeofences => _activeGeofences.values.toList();

  /// Initialize the geofencing service
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      // Load existing geofences from Firestore
      await _loadGeofencesFromFirestore();
      
      _isInitialized = true;
      debugPrint('GeofenceService: Initialized with ${_activeGeofences.length} geofences');
      
      return true;
      
    } catch (e) {
      debugPrint('GeofenceService: Initialization failed: $e');
      return false;
    }
  }

  /// Start monitoring geofences
  Future<void> startMonitoring() async {
    if (!_isInitialized) {
      throw Exception('GeofenceService not initialized');
    }
    
    _isMonitoring = true;
    debugPrint('GeofenceService: Started monitoring ${_activeGeofences.length} geofences');
  }

  /// Stop monitoring geofences
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    debugPrint('GeofenceService: Stopped monitoring geofences');
  }

  /// Add a new geofence
  Future<bool> addGeofence(Geofence geofence) async {
    try {
      // Save to Firestore
      await _firestore
          .collection('geofences')
          .doc(geofence.id)
          .set(geofence.toMap());
      
      // Add to local cache
      _activeGeofences[geofence.id] = geofence;
      _geofenceStatuses[geofence.id] = GeofenceStatus.outside;
      
      debugPrint('GeofenceService: Added geofence ${geofence.name}');
      return true;
      
    } catch (e) {
      debugPrint('GeofenceService: Error adding geofence: $e');
      return false;
    }
  }

  /// Remove a geofence
  Future<bool> removeGeofence(String geofenceId) async {
    try {
      // Remove from Firestore
      await _firestore
          .collection('geofences')
          .doc(geofenceId)
          .delete();
      
      // Remove from local cache
      _activeGeofences.remove(geofenceId);
      _geofenceStatuses.remove(geofenceId);
      
      debugPrint('GeofenceService: Removed geofence $geofenceId');
      return true;
      
    } catch (e) {
      debugPrint('GeofenceService: Error removing geofence: $e');
      return false;
    }
  }

  /// Update an existing geofence
  Future<bool> updateGeofence(Geofence geofence) async {
    try {
      // Update in Firestore
      await _firestore
          .collection('geofences')
          .doc(geofence.id)
          .update(geofence.toMap());
      
      // Update local cache
      _activeGeofences[geofence.id] = geofence;
      
      debugPrint('GeofenceService: Updated geofence ${geofence.name}');
      return true;
      
    } catch (e) {
      debugPrint('GeofenceService: Error updating geofence: $e');
      return false;
    }
  }

  /// Check location against all active geofences
  Future<List<GeofenceEvent>> checkLocation(LocationModel location) async {
    if (!_isMonitoring) return [];
    
    final events = <GeofenceEvent>[];
    final currentTime = DateTime.now();
    
    for (final geofence in _activeGeofences.values) {
      if (!geofence.isActive) continue;
      
      final currentStatus = _geofenceStatuses[geofence.id] ?? GeofenceStatus.outside;
      final isInside = _isLocationInsideGeofence(location, geofence);
      final newStatus = isInside ? GeofenceStatus.inside : GeofenceStatus.outside;
      
      // Check for status change
      if (currentStatus != newStatus) {
        final eventType = newStatus == GeofenceStatus.inside 
            ? GeofenceEventType.enter 
            : GeofenceEventType.exit;
        
        final event = GeofenceEvent(
          id: '${geofence.id}_${currentTime.millisecondsSinceEpoch}',
          geofenceId: geofence.id,
          geofenceName: geofence.name,
          eventType: eventType,
          location: location,
          timestamp: currentTime,
          vehicleId: location.vehicleId,
          driverId: location.driverId,
        );
        
        events.add(event);
        _geofenceStatuses[geofence.id] = newStatus;
        
        // Store event in Firestore
        await _storeGeofenceEvent(event);
        
        // Notify listeners
        _notifyListeners(event);
        _eventController.add(event);
        
        debugPrint('GeofenceService: ${eventType.toString()} event for ${geofence.name}');
      }
      
      // Check for dwelling (staying inside for extended period)
      if (newStatus == GeofenceStatus.inside && geofence.enableDwellNotification) {
        await _checkDwellTime(geofence, location, currentTime);
      }
    }
    
    return events;
  }

  /// Get geofence statistics
  Future<GeofenceStats> getGeofenceStats(String geofenceId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();
      
      Query query = _firestore
          .collection('geofence_events')
          .where('geofenceId', isEqualTo: geofenceId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate);
      
      final snapshot = await query.get();
      final events = snapshot.docs
          .map((doc) => GeofenceEvent.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      return GeofenceStats.fromEvents(events);
      
    } catch (e) {
      debugPrint('GeofenceService: Error getting stats: $e');
      return GeofenceStats.empty();
    }
  }

  /// Get all geofence events for a vehicle
  Future<List<GeofenceEvent>> getVehicleGeofenceHistory(
    String vehicleId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 7));
      endDate ??= DateTime.now();
      
      Query query = _firestore
          .collection('geofence_events')
          .where('vehicleId', isEqualTo: vehicleId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => GeofenceEvent.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
    } catch (e) {
      debugPrint('GeofenceService: Error getting vehicle history: $e');
      return [];
    }
  }

  /// Add event listener
  void addEventListener(Function(GeofenceEvent) listener) {
    _eventListeners.add(listener);
  }

  /// Remove event listener
  void removeEventListener(Function(GeofenceEvent) listener) {
    _eventListeners.remove(listener);
  }

  /// Dispose of all resources
  void dispose() {
    _eventController.close();
    _activeGeofences.clear();
    _geofenceStatuses.clear();
    _eventListeners.clear();
    _isInitialized = false;
    _isMonitoring = false;
  }

  // Private methods

  Future<void> _loadGeofencesFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('geofences')
          .where('isActive', isEqualTo: true)
          .get();
      
      for (final doc in snapshot.docs) {
        final geofence = Geofence.fromMap(doc.data());
        _activeGeofences[geofence.id] = geofence;
        _geofenceStatuses[geofence.id] = GeofenceStatus.outside;
      }
      
    } catch (e) {
      debugPrint('GeofenceService: Error loading geofences: $e');
    }
  }

  bool _isLocationInsideGeofence(LocationModel location, Geofence geofence) {
    switch (geofence.type) {
      case GeofenceType.circular:
        return _isLocationInsideCircle(location, geofence);
      case GeofenceType.polygon:
        return _isLocationInsidePolygon(location, geofence);
    }
  }

  bool _isLocationInsideCircle(LocationModel location, Geofence geofence) {
    final distance = _calculateDistance(
      location.latitude,
      location.longitude,
      geofence.centerLatitude!,
      geofence.centerLongitude!,
    );
    
    return distance <= geofence.radius!;
  }

  bool _isLocationInsidePolygon(LocationModel location, Geofence geofence) {
    final vertices = geofence.polygonVertices!;
    if (vertices.length < 3) return false;
    
    bool inside = false;
    int j = vertices.length - 1;
    
    for (int i = 0; i < vertices.length; i++) {
      final xi = vertices[i].latitude;
      final yi = vertices[i].longitude;
      final xj = vertices[j].latitude;
      final yj = vertices[j].longitude;
      
      if (((yi > location.longitude) != (yj > location.longitude)) &&
          (location.latitude < (xj - xi) * (location.longitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    
    return inside;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _checkDwellTime(Geofence geofence, LocationModel location, DateTime currentTime) async {
    // Implementation for dwell time checking
    // This would track how long a vehicle has been inside a geofence
    // and trigger events if it exceeds the threshold
  }

  Future<void> _storeGeofenceEvent(GeofenceEvent event) async {
    try {
      await _firestore
          .collection('geofence_events')
          .doc(event.id)
          .set(event.toMap());
          
    } catch (e) {
      debugPrint('GeofenceService: Error storing event: $e');
    }
  }

  void _notifyListeners(GeofenceEvent event) {
    for (final listener in _eventListeners) {
      try {
        listener(event);
      } catch (e) {
        debugPrint('GeofenceService: Error in event listener: $e');
      }
    }
  }
}

// Enums
enum GeofenceType { circular, polygon }
enum GeofenceStatus { inside, outside }
enum GeofenceEventType { enter, exit, dwell }

// Data classes
class Geofence {
  final String id;
  final String name;
  final String description;
  final GeofenceType type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Circular geofence properties
  final double? centerLatitude;
  final double? centerLongitude;
  final double? radius;
  
  // Polygon geofence properties
  final List<LocationPoint>? polygonVertices;
  
  // Notification settings
  final bool enableEnterNotification;
  final bool enableExitNotification;
  final bool enableDwellNotification;
  final int dwellTimeThreshold; // seconds
  
  // Metadata
  final String? createdBy;
  final Map<String, dynamic>? metadata;

  Geofence({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.centerLatitude,
    this.centerLongitude,
    this.radius,
    this.polygonVertices,
    this.enableEnterNotification = true,
    this.enableExitNotification = true,
    this.enableDwellNotification = false,
    this.dwellTimeThreshold = 300,
    this.createdBy,
    this.metadata,
  });

  factory Geofence.circular({
    required String id,
    required String name,
    required String description,
    required double centerLatitude,
    required double centerLongitude,
    required double radius,
    bool isActive = true,
    bool enableEnterNotification = true,
    bool enableExitNotification = true,
    bool enableDwellNotification = false,
    int dwellTimeThreshold = 300,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return Geofence(
      id: id,
      name: name,
      description: description,
      type: GeofenceType.circular,
      isActive: isActive,
      createdAt: DateTime.now(),
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      radius: radius,
      enableEnterNotification: enableEnterNotification,
      enableExitNotification: enableExitNotification,
      enableDwellNotification: enableDwellNotification,
      dwellTimeThreshold: dwellTimeThreshold,
      createdBy: createdBy,
      metadata: metadata,
    );
  }

  factory Geofence.polygon({
    required String id,
    required String name,
    required String description,
    required List<LocationPoint> vertices,
    bool isActive = true,
    bool enableEnterNotification = true,
    bool enableExitNotification = true,
    bool enableDwellNotification = false,
    int dwellTimeThreshold = 300,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return Geofence(
      id: id,
      name: name,
      description: description,
      type: GeofenceType.polygon,
      isActive: isActive,
      createdAt: DateTime.now(),
      polygonVertices: vertices,
      enableEnterNotification: enableEnterNotification,
      enableExitNotification: enableExitNotification,
      enableDwellNotification: enableDwellNotification,
      dwellTimeThreshold: dwellTimeThreshold,
      createdBy: createdBy,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'radius': radius,
      'polygonVertices': polygonVertices?.map((v) => v.toMap()).toList(),
      'enableEnterNotification': enableEnterNotification,
      'enableExitNotification': enableExitNotification,
      'enableDwellNotification': enableDwellNotification,
      'dwellTimeThreshold': dwellTimeThreshold,
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  factory Geofence.fromMap(Map<String, dynamic> map) {
    return Geofence(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: GeofenceType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => GeofenceType.circular,
      ),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      centerLatitude: map['centerLatitude']?.toDouble(),
      centerLongitude: map['centerLongitude']?.toDouble(),
      radius: map['radius']?.toDouble(),
      polygonVertices: map['polygonVertices'] != null
          ? (map['polygonVertices'] as List)
              .map((v) => LocationPoint.fromMap(v))
              .toList()
          : null,
      enableEnterNotification: map['enableEnterNotification'] ?? true,
      enableExitNotification: map['enableExitNotification'] ?? true,
      enableDwellNotification: map['enableDwellNotification'] ?? false,
      dwellTimeThreshold: map['dwellTimeThreshold'] ?? 300,
      createdBy: map['createdBy'],
      metadata: map['metadata']?.cast<String, dynamic>(),
    );
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;

  LocationPoint({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      latitude: map['latitude'].toDouble(),
      longitude: map['longitude'].toDouble(),
    );
  }
}

class GeofenceEvent {
  final String id;
  final String geofenceId;
  final String geofenceName;
  final GeofenceEventType eventType;
  final LocationModel location;
  final DateTime timestamp;
  final String? vehicleId;
  final String? driverId;
  final Map<String, dynamic>? metadata;

  GeofenceEvent({
    required this.id,
    required this.geofenceId,
    required this.geofenceName,
    required this.eventType,
    required this.location,
    required this.timestamp,
    this.vehicleId,
    this.driverId,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'geofenceId': geofenceId,
      'geofenceName': geofenceName,
      'eventType': eventType.toString(),
      'location': location.toMap(),
      'timestamp': timestamp.toIso8601String(),
      'vehicleId': vehicleId,
      'driverId': driverId,
      'metadata': metadata,
    };
  }

  factory GeofenceEvent.fromMap(Map<String, dynamic> map) {
    return GeofenceEvent(
      id: map['id'],
      geofenceId: map['geofenceId'],
      geofenceName: map['geofenceName'],
      eventType: GeofenceEventType.values.firstWhere(
        (e) => e.toString() == map['eventType'],
      ),
      location: LocationModel.fromMap(map['location'], map['location']['id'] ?? ''),
      timestamp: DateTime.parse(map['timestamp']),
      vehicleId: map['vehicleId'],
      driverId: map['driverId'],
      metadata: map['metadata']?.cast<String, dynamic>(),
    );
  }
}

class GeofenceStats {
  final int totalEnterEvents;
  final int totalExitEvents;
  final int totalDwellEvents;
  final Duration totalTimeInside;
  final Duration averageVisitDuration;
  final int uniqueVehicles;
  final DateTime? lastActivity;

  GeofenceStats({
    required this.totalEnterEvents,
    required this.totalExitEvents,
    required this.totalDwellEvents,
    required this.totalTimeInside,
    required this.averageVisitDuration,
    required this.uniqueVehicles,
    this.lastActivity,
  });

  factory GeofenceStats.fromEvents(List<GeofenceEvent> events) {
    if (events.isEmpty) return GeofenceStats.empty();

    int enterEvents = 0;
    int exitEvents = 0;
    int dwellEvents = 0;
    final Set<String> vehicles = {};
    DateTime? lastActivity;

    for (final event in events) {
      switch (event.eventType) {
        case GeofenceEventType.enter:
          enterEvents++;
          break;
        case GeofenceEventType.exit:
          exitEvents++;
          break;
        case GeofenceEventType.dwell:
          dwellEvents++;
          break;
      }

      if (event.vehicleId != null) {
        vehicles.add(event.vehicleId!);
      }

      if (lastActivity == null || event.timestamp.isAfter(lastActivity)) {
        lastActivity = event.timestamp;
      }
    }

    return GeofenceStats(
      totalEnterEvents: enterEvents,
      totalExitEvents: exitEvents,
      totalDwellEvents: dwellEvents,
      totalTimeInside: Duration.zero, // Would need more complex calculation
      averageVisitDuration: Duration.zero, // Would need more complex calculation
      uniqueVehicles: vehicles.length,
      lastActivity: lastActivity,
    );
  }

  factory GeofenceStats.empty() {
    return GeofenceStats(
      totalEnterEvents: 0,
      totalExitEvents: 0,
      totalDwellEvents: 0,
      totalTimeInside: Duration.zero,
      averageVisitDuration: Duration.zero,
      uniqueVehicles: 0,
    );
  }
}
