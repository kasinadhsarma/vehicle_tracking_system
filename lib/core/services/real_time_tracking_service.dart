import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';
import 'location_service.dart';
import 'google_maps_service.dart';
import 'geofence_service.dart';
import 'driver_behavior_service.dart';

/// Comprehensive real-time tracking service
/// Orchestrates location tracking, mapping, geofencing, and behavior analysis
class RealTimeTrackingService {
  static RealTimeTrackingService? _instance;
  static RealTimeTrackingService get instance => _instance ??= RealTimeTrackingService._();
  
  RealTimeTrackingService._();

  // Core services
  final LocationService _locationService = LocationService.instance;
  final GoogleMapsService _mapsService = GoogleMapsService.instance;
  final GeofenceService _geofenceService = GeofenceService.instance;
  final DriverBehaviorService _behaviorService = DriverBehaviorService.instance;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream controllers for real-time updates
  final StreamController<TrackingUpdate> _trackingController = 
      StreamController<TrackingUpdate>.broadcast();
  final StreamController<TripSummary> _tripController = 
      StreamController<TripSummary>.broadcast();
  
  // Current tracking state
  TrackingSession? _currentSession;
  Trip? _currentTrip;
  Timer? _heartbeatTimer;
  Timer? _syncTimer;
  
  // Configuration
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _syncInterval = Duration(minutes: 5);
  static const int _locationBufferSize = 100;
  
  bool _isInitialized = false;
  bool _isTracking = false;

  // Public getters
  bool get isInitialized => _isInitialized;
  bool get isTracking => _isTracking;
  TrackingSession? get currentSession => _currentSession;
  Trip? get currentTrip => _currentTrip;
  Stream<TrackingUpdate> get trackingStream => _trackingController.stream;
  Stream<TripSummary> get tripStream => _tripController.stream;

  /// Initialize the real-time tracking service
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      // Initialize all core services
      // Location service doesn't need initialization
      await _mapsService.initialize();
      await _geofenceService.initialize();
      await _behaviorService.initialize();
      
      _isInitialized = true;
      debugPrint('RealTimeTrackingService: Initialized successfully');
      
      return true;
      
    } catch (e) {
      debugPrint('RealTimeTrackingService: Initialization failed: $e');
      return false;
    }
  }

  /// Start comprehensive tracking session
  Future<bool> startTracking({
    required String vehicleId,
    required String driverId,
    TrackingMode mode = TrackingMode.normal,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_isInitialized) {
        throw Exception('RealTimeTrackingService not initialized');
      }

      if (_isTracking) {
        debugPrint('RealTimeTrackingService: Already tracking');
        return true;
      }

      // Create new tracking session
      _currentSession = TrackingSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        vehicleId: vehicleId,
        driverId: driverId,
        mode: mode,
        startTime: DateTime.now(),
        metadata: metadata,
      );

      // Start location tracking
      await _locationService.startTracking(driverId, vehicleId: vehicleId);
      
      // Start geofence monitoring
      await _geofenceService.startMonitoring();
      
      // Start driver behavior monitoring
      await _behaviorService.startMonitoring(
        driverId: driverId,
        vehicleId: vehicleId,
      );

      // Set up location updates listener
      _locationService.getLocationStream(driverId).listen((location) {
        if (location != null) {
          _handleLocationUpdate(location);
        }
      });
      
      // Set up geofence events listener
      _geofenceService.eventStream.listen(_handleGeofenceEvent);
      
      // Set up behavior events listener
      _behaviorService.eventStream.listen(_handleBehaviorEvent);

      // Start heartbeat timer
      _startHeartbeat();
      
      // Start sync timer
      _startSync();

      _isTracking = true;
      
      // Store session in Firestore
      await _storeTrackingSession(_currentSession!);
      
      debugPrint('RealTimeTrackingService: Started tracking for vehicle $vehicleId');
      return true;
      
    } catch (e) {
      debugPrint('RealTimeTrackingService: Error starting tracking: $e');
      return false;
    }
  }

  /// Stop tracking session
  Future<bool> stopTracking() async {
    try {
      if (!_isTracking) return true;

      // Stop all core services
      await _locationService.stopTracking();
      await _geofenceService.stopMonitoring();
      await _behaviorService.stopMonitoring();

      // Cancel timers
      _heartbeatTimer?.cancel();
      _syncTimer?.cancel();

      // Finalize current trip if exists
      if (_currentTrip != null) {
        await _finalizeTrip();
      }

      // Update session end time
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(endTime: DateTime.now());
        await _updateTrackingSession(_currentSession!);
      }

      _isTracking = false;
      _currentSession = null;
      _currentTrip = null;

      debugPrint('RealTimeTrackingService: Stopped tracking');
      return true;
      
    } catch (e) {
      debugPrint('RealTimeTrackingService: Error stopping tracking: $e');
      return false;
    }
  }

  /// Get live tracking data for a vehicle
  Stream<LiveTrackingData> getLiveTrackingData(String vehicleId) {
    return _firestore
        .collection('live_tracking')
        .doc(vehicleId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return LiveTrackingData.fromMap(snapshot.data()!);
          } else {
            return LiveTrackingData.empty(vehicleId);
          }
        });
  }

  /// Get trip history for a vehicle
  Future<List<Trip>> getTripHistory(
    String vehicleId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      Query query = _firestore
          .collection('trips')
          .where('vehicleId', isEqualTo: vehicleId)
          .where('startTime', isGreaterThanOrEqualTo: startDate)
          .where('startTime', isLessThanOrEqualTo: endDate)
          .orderBy('startTime', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => Trip.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
          
    } catch (e) {
      debugPrint('RealTimeTrackingService: Error getting trip history: $e');
      return [];
    }
  }

  /// Get fleet overview data
  Future<FleetOverview> getFleetOverview() async {
    try {
      // Get active tracking sessions
      final sessionsSnapshot = await _firestore
          .collection('tracking_sessions')
          .where('isActive', isEqualTo: true)
          .get();

      // Get recent trips
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('startTime', isGreaterThan: DateTime.now().subtract(const Duration(hours: 24)))
          .get();

      // Get live tracking data
      final liveSnapshot = await _firestore
          .collection('live_tracking')
          .get();

      return FleetOverview(
        activeVehicles: sessionsSnapshot.docs.length,
        totalTripsToday: tripsSnapshot.docs.length,
        liveTrackingData: liveSnapshot.docs
            .map((doc) => LiveTrackingData.fromMap(doc.data()))
            .toList(),
        lastUpdated: DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('RealTimeTrackingService: Error getting fleet overview: $e');
      return FleetOverview.empty();
    }
  }

  /// Dispose of all resources
  void dispose() {
    _heartbeatTimer?.cancel();
    _syncTimer?.cancel();
    _trackingController.close();
    _tripController.close();
    _isInitialized = false;
    _isTracking = false;
  }

  // Private methods

  void _handleLocationUpdate(LocationModel location) {
    if (!_isTracking || _currentSession == null) return;

    try {
      // Update current trip or create new one
      _updateTrip(location);
      
      // Send location to behavior analysis
      _behaviorService.addLocationData(location);
      
      // Check geofences
      _geofenceService.checkLocation(location);
      
      // Update live tracking data
      _updateLiveTracking(location);
      
      // Create tracking update
      final update = TrackingUpdate(
        sessionId: _currentSession!.id,
        location: location,
        timestamp: DateTime.now(),
        status: TrackingStatus.active,
      );
      
      _trackingController.add(update);
      
    } catch (e) {
      debugPrint('RealTimeTrackingService: Error handling location update: $e');
    }
  }

  void _handleGeofenceEvent(GeofenceEvent event) {
    if (!_isTracking) return;
    
    debugPrint('RealTimeTrackingService: Geofence event: ${event.eventType} at ${event.geofenceName}');
    
    // Add geofence event to current trip
    if (_currentTrip != null) {
      _currentTrip = _currentTrip!.copyWith(
        geofenceEvents: [..._currentTrip!.geofenceEvents, event],
      );
    }
  }

  void _handleBehaviorEvent(DrivingEvent event) {
    if (!_isTracking) return;
    
    debugPrint('RealTimeTrackingService: Behavior event: ${event.eventType} with severity ${event.severity}');
    
    // Add behavior event to current trip
    if (_currentTrip != null) {
      _currentTrip = _currentTrip!.copyWith(
        behaviorEvents: [..._currentTrip!.behaviorEvents, event],
      );
    }
  }

  void _updateTrip(LocationModel location) {
    if (_currentTrip == null) {
      // Start new trip
      _currentTrip = Trip(
        id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _currentSession!.id,
        vehicleId: _currentSession!.vehicleId,
        driverId: _currentSession!.driverId,
        startTime: DateTime.now(),
        startLocation: location,
        locations: [location],
        geofenceEvents: [],
        behaviorEvents: [],
      );
    } else {
      // Update existing trip
      _currentTrip = _currentTrip!.copyWith(
        endLocation: location,
        locations: [..._currentTrip!.locations, location],
      );
      
      // Keep location buffer manageable
      if (_currentTrip!.locations.length > _locationBufferSize) {
        final newLocations = _currentTrip!.locations.sublist(
          _currentTrip!.locations.length - _locationBufferSize
        );
        _currentTrip = _currentTrip!.copyWith(locations: newLocations);
      }
    }
  }

  Future<void> _updateLiveTracking(LocationModel location) async {
    try {
      final liveData = LiveTrackingData(
        vehicleId: _currentSession!.vehicleId,
        driverId: _currentSession!.driverId,
        currentLocation: location,
        lastUpdate: DateTime.now(),
        isActive: true,
        speed: location.speed ?? 0.0,
        heading: location.heading ?? 0.0,
        tripId: _currentTrip?.id,
      );

      await _firestore
          .collection('live_tracking')
          .doc(_currentSession!.vehicleId)
          .set(liveData.toMap());
          
    } catch (e) {
      debugPrint('RealTimeTrackingService: Error updating live tracking: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      try {
        // Update session heartbeat
        if (_currentSession != null) {
          await _firestore
              .collection('tracking_sessions')
              .doc(_currentSession!.id)
              .update({'lastHeartbeat': DateTime.now().toIso8601String()});
        }
      } catch (e) {
        debugPrint('RealTimeTrackingService: Heartbeat error: $e');
      }
    });
  }

  void _startSync() {
    _syncTimer = Timer.periodic(_syncInterval, (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      try {
        // Sync current trip to Firestore
        if (_currentTrip != null) {
          await _syncTripToFirestore(_currentTrip!);
        }
      } catch (e) {
        debugPrint('RealTimeTrackingService: Sync error: $e');
      }
    });
  }

  Future<void> _syncTripToFirestore(Trip trip) async {
    try {
      await _firestore
          .collection('trips')
          .doc(trip.id)
          .set(trip.toMap());
          
    } catch (e) {
      debugPrint('RealTimeTrackingService: Error syncing trip: $e');
    }
  }

  Future<void> _finalizeTrip() async {
    if (_currentTrip == null) return;

    try {
      // Calculate trip summary
      final summary = TripSummary.fromTrip(_currentTrip!);
      
      // Update trip with final data
      _currentTrip = _currentTrip!.copyWith(
        endTime: DateTime.now(),
        isCompleted: true,
        summary: summary,
      );

      // Save final trip to Firestore
      await _syncTripToFirestore(_currentTrip!);
      
      // Notify listeners
      _tripController.add(summary);
      
    } catch (e) {
      debugPrint('RealTimeTrackingService: Error finalizing trip: $e');
    }
  }

  Future<void> _storeTrackingSession(TrackingSession session) async {
    try {
      await _firestore
          .collection('tracking_sessions')
          .doc(session.id)
          .set(session.toMap());
          
    } catch (e) {
      debugPrint('RealTimeTrackingService: Error storing session: $e');
    }
  }

  Future<void> _updateTrackingSession(TrackingSession session) async {
    try {
      await _firestore
          .collection('tracking_sessions')
          .doc(session.id)
          .update(session.toMap());
          
    } catch (e) {
      debugPrint('RealTimeTrackingService: Error updating session: $e');
    }
  }
}

// Enums
enum TrackingMode { normal, highAccuracy, powerSaver, background }
enum TrackingStatus { active, paused, stopped, error }

// Data classes
class TrackingSession {
  final String id;
  final String vehicleId;
  final String driverId;
  final TrackingMode mode;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic>? metadata;

  TrackingSession({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.mode,
    required this.startTime,
    this.endTime,
    this.metadata,
  });

  bool get isActive => endTime == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'mode': mode.toString(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
      'lastHeartbeat': DateTime.now().toIso8601String(),
    };
  }

  TrackingSession copyWith({
    String? id,
    String? vehicleId,
    String? driverId,
    TrackingMode? mode,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, dynamic>? metadata,
  }) {
    return TrackingSession(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      mode: mode ?? this.mode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Trip {
  final String id;
  final String sessionId;
  final String vehicleId;
  final String driverId;
  final DateTime startTime;
  final DateTime? endTime;
  final LocationModel startLocation;
  final LocationModel? endLocation;
  final List<LocationModel> locations;
  final List<GeofenceEvent> geofenceEvents;
  final List<DrivingEvent> behaviorEvents;
  final bool isCompleted;
  final TripSummary? summary;

  Trip({
    required this.id,
    required this.sessionId,
    required this.vehicleId,
    required this.driverId,
    required this.startTime,
    this.endTime,
    required this.startLocation,
    this.endLocation,
    required this.locations,
    required this.geofenceEvents,
    required this.behaviorEvents,
    this.isCompleted = false,
    this.summary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startLocation': startLocation.toMap(),
      'endLocation': endLocation?.toMap(),
      'locations': locations.map((l) => l.toMap()).toList(),
      'geofenceEvents': geofenceEvents.map((e) => e.toMap()).toList(),
      'behaviorEvents': behaviorEvents.map((e) => e.toMap()).toList(),
      'isCompleted': isCompleted,
      'summary': summary?.toMap(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      sessionId: map['sessionId'],
      vehicleId: map['vehicleId'],
      driverId: map['driverId'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      startLocation: LocationModel.fromMap(map['startLocation'], map['startLocation']['id'] ?? ''),
      endLocation: map['endLocation'] != null ? LocationModel.fromMap(map['endLocation'], map['endLocation']['id'] ?? '') : null,
      locations: (map['locations'] as List)
          .map((l) => LocationModel.fromMap(l, l['id'] ?? ''))
          .toList(),
      geofenceEvents: (map['geofenceEvents'] as List? ?? [])
          .map((e) => GeofenceEvent.fromMap(e))
          .toList(),
      behaviorEvents: (map['behaviorEvents'] as List? ?? [])
          .map((e) => DrivingEvent.fromMap(e))
          .toList(),
      isCompleted: map['isCompleted'] ?? false,
      summary: map['summary'] != null ? TripSummary.fromMap(map['summary']) : null,
    );
  }

  Trip copyWith({
    String? id,
    String? sessionId,
    String? vehicleId,
    String? driverId,
    DateTime? startTime,
    DateTime? endTime,
    LocationModel? startLocation,
    LocationModel? endLocation,
    List<LocationModel>? locations,
    List<GeofenceEvent>? geofenceEvents,
    List<DrivingEvent>? behaviorEvents,
    bool? isCompleted,
    TripSummary? summary,
  }) {
    return Trip(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      locations: locations ?? this.locations,
      geofenceEvents: geofenceEvents ?? this.geofenceEvents,
      behaviorEvents: behaviorEvents ?? this.behaviorEvents,
      isCompleted: isCompleted ?? this.isCompleted,
      summary: summary ?? this.summary,
    );
  }
}

class TrackingUpdate {
  final String sessionId;
  final LocationModel location;
  final DateTime timestamp;
  final TrackingStatus status;

  TrackingUpdate({
    required this.sessionId,
    required this.location,
    required this.timestamp,
    required this.status,
  });
}

class LiveTrackingData {
  final String vehicleId;
  final String driverId;
  final LocationModel currentLocation;
  final DateTime lastUpdate;
  final bool isActive;
  final double speed;
  final double heading;
  final String? tripId;

  LiveTrackingData({
    required this.vehicleId,
    required this.driverId,
    required this.currentLocation,
    required this.lastUpdate,
    required this.isActive,
    required this.speed,
    required this.heading,
    this.tripId,
  });

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'driverId': driverId,
      'currentLocation': currentLocation.toMap(),
      'lastUpdate': lastUpdate.toIso8601String(),
      'isActive': isActive,
      'speed': speed,
      'heading': heading,
      'tripId': tripId,
    };
  }

  factory LiveTrackingData.fromMap(Map<String, dynamic> map) {
    return LiveTrackingData(
      vehicleId: map['vehicleId'],
      driverId: map['driverId'],
      currentLocation: LocationModel.fromMap(map['currentLocation'], map['currentLocation']['id'] ?? ''),
      lastUpdate: DateTime.parse(map['lastUpdate']),
      isActive: map['isActive'],
      speed: map['speed'].toDouble(),
      heading: map['heading'].toDouble(),
      tripId: map['tripId'],
    );
  }

  factory LiveTrackingData.empty(String vehicleId) {
    return LiveTrackingData(
      vehicleId: vehicleId,
      driverId: '',
      currentLocation: LocationModel(
        id: '',
        userId: '',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
      ),
      lastUpdate: DateTime.now(),
      isActive: false,
      speed: 0.0,
      heading: 0.0,
    );
  }
}

class TripSummary {
  final double totalDistance;
  final Duration totalTime;
  final double averageSpeed;
  final double maxSpeed;
  final int behaviorEvents;
  final int geofenceEvents;
  final double score;

  TripSummary({
    required this.totalDistance,
    required this.totalTime,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.behaviorEvents,
    required this.geofenceEvents,
    required this.score,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalDistance': totalDistance,
      'totalTime': totalTime.inMilliseconds,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'behaviorEvents': behaviorEvents,
      'geofenceEvents': geofenceEvents,
      'score': score,
    };
  }

  factory TripSummary.fromMap(Map<String, dynamic> map) {
    return TripSummary(
      totalDistance: map['totalDistance'].toDouble(),
      totalTime: Duration(milliseconds: map['totalTime']),
      averageSpeed: map['averageSpeed'].toDouble(),
      maxSpeed: map['maxSpeed'].toDouble(),
      behaviorEvents: map['behaviorEvents'],
      geofenceEvents: map['geofenceEvents'],
      score: map['score'].toDouble(),
    );
  }

  factory TripSummary.fromTrip(Trip trip) {
    double totalDistance = 0.0;
    double maxSpeed = 0.0;
    double totalSpeed = 0.0;
    int speedCount = 0;

    // Calculate distance and speed metrics
    for (int i = 1; i < trip.locations.length; i++) {
      final current = trip.locations[i];
      final previous = trip.locations[i - 1];
      
      totalDistance += current.distanceTo(previous);
      
      if (current.speed != null) {
        maxSpeed = max(maxSpeed, current.speed!);
        totalSpeed += current.speed!;
        speedCount++;
      }
    }

    final averageSpeed = speedCount > 0 ? totalSpeed / speedCount : 0.0;
    final totalTime = trip.endTime?.difference(trip.startTime) ?? Duration.zero;
    
    // Simple scoring algorithm
    final score = max(0, 100 - (trip.behaviorEvents.length * 10));

    return TripSummary(
      totalDistance: totalDistance,
      totalTime: totalTime,
      averageSpeed: averageSpeed,
      maxSpeed: maxSpeed,
      behaviorEvents: trip.behaviorEvents.length,
      geofenceEvents: trip.geofenceEvents.length,
      score: score.toDouble(),
    );
  }
}

class FleetOverview {
  final int activeVehicles;
  final int totalTripsToday;
  final List<LiveTrackingData> liveTrackingData;
  final DateTime lastUpdated;

  FleetOverview({
    required this.activeVehicles,
    required this.totalTripsToday,
    required this.liveTrackingData,
    required this.lastUpdated,
  });

  factory FleetOverview.empty() {
    return FleetOverview(
      activeVehicles: 0,
      totalTripsToday: 0,
      liveTrackingData: [],
      lastUpdated: DateTime.now(),
    );
  }
}
