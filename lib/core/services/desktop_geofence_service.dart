import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/location_model.dart';

// Simple point class for desktop geofencing
class LocationPoint {
  final double latitude;
  final double longitude;

  const LocationPoint({
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

/// Desktop-compatible geofencing service that works without Firebase
/// Implements local geofencing for development and testing
class DesktopGeofenceService {
  static DesktopGeofenceService? _instance;
  static DesktopGeofenceService get instance => _instance ??= DesktopGeofenceService._();
  
  DesktopGeofenceService._();

  // Active geofences stored locally
  final Map<String, Geofence> _activeGeofences = {};
  final Map<String, GeofenceStatus> _geofenceStatuses = {};
  
  // Notification callbacks
  final List<Function(GeofenceEvent)> _eventListeners = [];
  
  // Stream controllers
  final StreamController<GeofenceEvent> _eventController = 
      StreamController<GeofenceEvent>.broadcast();
  
  bool _isInitialized = false;
  bool _isMonitoring = false;

  /// Initialize the desktop geofence service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('Initializing desktop geofence service...');
      
      // Load mock geofences for testing
      await _loadMockGeofences();
      
      _isInitialized = true;
      debugPrint('Desktop geofence service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing desktop geofence service: $e');
      rethrow;
    }
  }

  /// Load some mock geofences for testing
  Future<void> _loadMockGeofences() async {
    // Add some sample geofences for testing
    final mockGeofences = [
      Geofence(
        id: 'home_zone',
        name: 'Home Zone',
        center: const LocationPoint(latitude: 40.7128, longitude: -74.0060),
        radius: 100,
        type: GeofenceType.circular,
        triggers: [GeofenceTrigger.enter, GeofenceTrigger.exit],
        isActive: true,
        metadata: {'priority': 'high', 'description': 'Home office area'},
      ),
      Geofence(
        id: 'downtown_zone',
        name: 'Downtown Zone',
        center: const LocationPoint(latitude: 40.7589, longitude: -73.9851),
        radius: 200,
        type: GeofenceType.circular,
        triggers: [GeofenceTrigger.enter, GeofenceTrigger.exit],
        isActive: true,
        metadata: {'priority': 'medium', 'description': 'City center area'},
      ),
    ];

    for (final geofence in mockGeofences) {
      _activeGeofences[geofence.id] = geofence;
      _geofenceStatuses[geofence.id] = GeofenceStatus(
        geofenceId: geofence.id,
        status: GeofenceStatusType.outside,
        lastUpdate: DateTime.now(),
      );
    }
  }

  /// Add a new geofence
  Future<void> addGeofence(Geofence geofence) async {
    try {
      _activeGeofences[geofence.id] = geofence;
      _geofenceStatuses[geofence.id] = GeofenceStatus(
        geofenceId: geofence.id,
        status: GeofenceStatusType.outside,
        lastUpdate: DateTime.now(),
      );
      
      debugPrint('Geofence added locally: ${geofence.name}');
    } catch (e) {
      debugPrint('Error adding geofence: $e');
      rethrow;
    }
  }

  /// Remove a geofence
  Future<void> removeGeofence(String geofenceId) async {
    try {
      _activeGeofences.remove(geofenceId);
      _geofenceStatuses.remove(geofenceId);
      
      debugPrint('Geofence removed: $geofenceId');
    } catch (e) {
      debugPrint('Error removing geofence: $e');
      rethrow;
    }
  }

  /// Check location against all active geofences
  Future<List<GeofenceEvent>> checkLocation(LocationPoint location) async {
    final events = <GeofenceEvent>[];
    
    for (final geofence in _activeGeofences.values) {
      if (!geofence.isActive) continue;
      
      final currentStatus = _geofenceStatuses[geofence.id]!;
      final isInside = _isLocationInsideGeofence(location, geofence);
      final newStatus = isInside ? GeofenceStatusType.inside : GeofenceStatusType.outside;
      
      if (currentStatus.status != newStatus) {
        final event = GeofenceEvent(
          geofenceId: geofence.id,
          geofenceName: geofence.name,
          trigger: isInside ? GeofenceTrigger.enter : GeofenceTrigger.exit,
          location: location,
          timestamp: DateTime.now(),
          metadata: geofence.metadata,
        );
        
        events.add(event);
        
        // Update status
        _geofenceStatuses[geofence.id] = GeofenceStatus(
          geofenceId: geofence.id,
          status: newStatus,
          lastUpdate: DateTime.now(),
        );
        
        // Notify listeners
        _notifyListeners(event);
      }
    }
    
    return events;
  }

  /// Check if location is inside a geofence
  bool _isLocationInsideGeofence(LocationPoint location, Geofence geofence) {
    switch (geofence.type) {
      case GeofenceType.circular:
        return _isLocationInsideCircle(location, geofence.center, geofence.radius);
      case GeofenceType.polygon:
        return geofence.polygon != null ? 
               _isLocationInsidePolygon(location, geofence.polygon!) : false;
    }
  }

  /// Check if location is inside a circular geofence
  bool _isLocationInsideCircle(LocationPoint location, LocationPoint center, double radius) {
    final distance = _calculateDistance(location, center);
    return distance <= radius;
  }

  /// Check if location is inside a polygonal geofence
  bool _isLocationInsidePolygon(LocationPoint location, List<LocationPoint> polygon) {
    int intersections = 0;
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];
      
      if (((p1.latitude > location.latitude) != (p2.latitude > location.latitude)) &&
          (location.longitude < (p2.longitude - p1.longitude) * 
           (location.latitude - p1.latitude) / (p2.latitude - p1.latitude) + p1.longitude)) {
        intersections++;
      }
    }
    return intersections % 2 == 1;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(LocationPoint point1, LocationPoint point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
              cos(lat1Rad) * cos(lat2Rad) *
              sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Notify all event listeners
  void _notifyListeners(GeofenceEvent event) {
    for (final listener in _eventListeners) {
      try {
        listener(event);
      } catch (e) {
        debugPrint('Error in geofence event listener: $e');
      }
    }
    
    _eventController.add(event);
  }

  /// Add event listener
  void addEventListener(Function(GeofenceEvent) listener) {
    _eventListeners.add(listener);
  }

  /// Remove event listener
  void removeEventListener(Function(GeofenceEvent) listener) {
    _eventListeners.remove(listener);
  }

  /// Get stream of geofence events
  Stream<GeofenceEvent> get eventStream => _eventController.stream;

  /// Get all active geofences
  List<Geofence> getActiveGeofences() {
    return _activeGeofences.values.where((g) => g.isActive).toList();
  }

  /// Get geofence status
  GeofenceStatus? getGeofenceStatus(String geofenceId) {
    return _geofenceStatuses[geofenceId];
  }

  /// Start monitoring
  Future<void> startMonitoring() async {
    _isMonitoring = true;
    debugPrint('Desktop geofence monitoring started');
  }

  /// Stop monitoring
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    debugPrint('Desktop geofence monitoring stopped');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Dispose resources
  void dispose() {
    _eventController.close();
    _eventListeners.clear();
    _activeGeofences.clear();
    _geofenceStatuses.clear();
    _isInitialized = false;
    _isMonitoring = false;
  }
}

// Data classes for geofencing
class Geofence {
  final String id;
  final String name;
  final LocationPoint center;
  final double radius;
  final GeofenceType type;
  final List<GeofenceTrigger> triggers;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final List<LocationPoint>? polygon;

  const Geofence({
    required this.id,
    required this.name,
    required this.center,
    required this.radius,
    required this.type,
    required this.triggers,
    required this.isActive,
    required this.metadata,
    this.polygon,
  });
}

class GeofenceEvent {
  final String geofenceId;
  final String geofenceName;
  final GeofenceTrigger trigger;
  final LocationPoint location;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const GeofenceEvent({
    required this.geofenceId,
    required this.geofenceName,
    required this.trigger,
    required this.location,
    required this.timestamp,
    required this.metadata,
  });
}

class GeofenceStatus {
  final String geofenceId;
  final GeofenceStatusType status;
  final DateTime lastUpdate;

  const GeofenceStatus({
    required this.geofenceId,
    required this.status,
    required this.lastUpdate,
  });
}

enum GeofenceType { circular, polygon }
enum GeofenceTrigger { enter, exit, dwell }
enum GeofenceStatusType { inside, outside, unknown }
