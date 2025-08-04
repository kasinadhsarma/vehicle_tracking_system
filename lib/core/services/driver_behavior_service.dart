import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';

// Temporary sensor event classes (replace with sensors_plus when added)
class AccelerometerEvent {
  final double x, y, z;
  AccelerometerEvent(this.x, this.y, this.z);
}

class GyroscopeEvent {
  final double x, y, z;
  GyroscopeEvent(this.x, this.y, this.z);
}

/// Advanced driver behavior analysis service
/// Monitors driving patterns, detects harsh events, and provides safety scoring
class DriverBehaviorService {
  static DriverBehaviorService? _instance;
  static DriverBehaviorService get instance => _instance ??= DriverBehaviorService._();
  
  DriverBehaviorService._();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Sensor streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // Data buffers
  final List<AccelerometerEvent> _accelerometerBuffer = [];
  final List<GyroscopeEvent> _gyroscopeBuffer = [];
  final List<LocationModel> _locationBuffer = [];
  
  // Behavior analysis results
  final List<DrivingEvent> _drivingEvents = [];
  final Map<String, DriverScore> _driverScores = {};
  
  // Stream controllers
  final StreamController<DrivingEvent> _eventController = 
      StreamController<DrivingEvent>.broadcast();
  final StreamController<DriverScore> _scoreController = 
      StreamController<DriverScore>.broadcast();
  
  // Configuration
  static const int _bufferSize = 50; // Number of readings to keep
  static const double _harshAccelerationThreshold = 3.0; // m/s²
  static const double _harshBrakingThreshold = -3.0; // m/s²
  static const double _harshTurningThreshold = 2.5; // rad/s
  static const double _speedingThreshold = 10.0; // km/h over limit
  static const Duration _analysisInterval = Duration(seconds: 5);
  
  bool _isInitialized = false;
  bool _isMonitoring = false;
  Timer? _analysisTimer;
  String? _currentDriverId;
  String? _currentVehicleId;

  // Public getters
  bool get isInitialized => _isInitialized;
  bool get isMonitoring => _isMonitoring;
  Stream<DrivingEvent> get eventStream => _eventController.stream;
  Stream<DriverScore> get scoreStream => _scoreController.stream;

  /// Initialize the driver behavior service
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      // Initialize sensor streams
      _initializeSensors();
      
      _isInitialized = true;
      debugPrint('DriverBehaviorService: Initialized successfully');
      
      return true;
      
    } catch (e) {
      debugPrint('DriverBehaviorService: Initialization failed: $e');
      return false;
    }
  }

  /// Start monitoring driver behavior
  Future<void> startMonitoring({
    required String driverId,
    required String vehicleId,
  }) async {
    if (!_isInitialized) {
      throw Exception('DriverBehaviorService not initialized');
    }
    
    _currentDriverId = driverId;
    _currentVehicleId = vehicleId;
    _isMonitoring = true;
    
    // Start sensor monitoring
    _startSensorMonitoring();
    
    // Start periodic analysis
    _analysisTimer = Timer.periodic(_analysisInterval, (_) => _analyzeDriverBehavior());
    
    debugPrint('DriverBehaviorService: Started monitoring for driver $driverId');
  }

  /// Stop monitoring driver behavior
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _analysisTimer?.cancel();
    
    // Stop sensor monitoring
    _stopSensorMonitoring();
    
    // Process final analysis
    if (_drivingEvents.isNotEmpty) {
      await _processFinalAnalysis();
    }
    
    debugPrint('DriverBehaviorService: Stopped monitoring');
  }

  /// Add location data for analysis
  void addLocationData(LocationModel location) {
    if (!_isMonitoring) return;
    
    _locationBuffer.add(location);
    
    // Keep buffer size manageable
    if (_locationBuffer.length > _bufferSize) {
      _locationBuffer.removeAt(0);
    }
  }

  /// Get driver behavior score
  Future<DriverScore?> getDriverScore(String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();
      
      final events = await _getDrivingEvents(driverId, startDate, endDate);
      return _calculateDriverScore(driverId, events);
      
    } catch (e) {
      debugPrint('DriverBehaviorService: Error getting driver score: $e');
      return null;
    }
  }

  /// Get driving events for a driver
  Future<List<DrivingEvent>> getDrivingEvents(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
    EventType? eventType,
    int limit = 100,
  }) async {
    return await _getDrivingEvents(driverId, startDate, endDate, eventType, limit);
  }

  /// Get fleet behavior summary
  Future<FleetBehaviorSummary> getFleetBehaviorSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();
      
      Query query = _firestore
          .collection('driving_events')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate);
      
      final snapshot = await query.get();
      final events = snapshot.docs
          .map((doc) => DrivingEvent.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      return FleetBehaviorSummary.fromEvents(events);
      
    } catch (e) {
      debugPrint('DriverBehaviorService: Error getting fleet summary: $e');
      return FleetBehaviorSummary.empty();
    }
  }

  /// Dispose of all resources
  void dispose() {
    _stopSensorMonitoring();
    _analysisTimer?.cancel();
    _eventController.close();
    _scoreController.close();
    _accelerometerBuffer.clear();
    _gyroscopeBuffer.clear();
    _locationBuffer.clear();
    _drivingEvents.clear();
    _isInitialized = false;
    _isMonitoring = false;
  }

  // Private methods

  void _initializeSensors() {
    // Sensors will be started when monitoring begins
  }

  void _startSensorMonitoring() {
    // Placeholder implementation - will be replaced with actual sensor integration
    // Start accelerometer monitoring
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      // Simulate accelerometer data (replace with real sensor data)
      final event = AccelerometerEvent(0.0, 0.0, 9.8);
      _accelerometerBuffer.add(event);
      
      // Keep buffer size manageable
      if (_accelerometerBuffer.length > _bufferSize) {
        _accelerometerBuffer.removeAt(0);
      }
    });
    
    // Start gyroscope monitoring
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      // Simulate gyroscope data (replace with real sensor data)
      final event = GyroscopeEvent(0.0, 0.0, 0.0);
      _gyroscopeBuffer.add(event);
      
      // Keep buffer size manageable
      if (_gyroscopeBuffer.length > _bufferSize) {
        _gyroscopeBuffer.removeAt(0);
      }
    });
  }

  void _stopSensorMonitoring() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
  }

  void _analyzeDriverBehavior() {
    if (!_isMonitoring || _locationBuffer.length < 2) return;
    
    try {
      // Analyze acceleration/deceleration
      _analyzeAcceleration();
      
      // Analyze turning behavior
      _analyzeTurning();
      
      // Analyze speeding
      _analyzeSpeeding();
      
      // Analyze phone usage (if available)
      _analyzeDistraction();
      
    } catch (e) {
      debugPrint('DriverBehaviorService: Error in behavior analysis: $e');
    }
  }

  void _analyzeAcceleration() {
    if (_locationBuffer.length < 3) return;
    
    final recent = _locationBuffer.sublist(_locationBuffer.length - 3);
    
    // Calculate acceleration from speed changes
    for (int i = 1; i < recent.length; i++) {
      final current = recent[i];
      final previous = recent[i - 1];
      
      if (current.speed != null && previous.speed != null) {
        final timeDiff = current.timestamp.difference(previous.timestamp).inMilliseconds / 1000.0;
        if (timeDiff > 0) {
          final speedDiff = (current.speed! - previous.speed!) * (1000.0 / 3600.0); // Convert km/h to m/s
          final acceleration = speedDiff / timeDiff;
          
          if (acceleration > _harshAccelerationThreshold) {
            _recordDrivingEvent(
              EventType.harshAcceleration,
              current,
              severity: _calculateSeverity(acceleration, _harshAccelerationThreshold),
              value: acceleration,
            );
          } else if (acceleration < _harshBrakingThreshold) {
            _recordDrivingEvent(
              EventType.harshBraking,
              current,
              severity: _calculateSeverity(acceleration.abs(), _harshBrakingThreshold.abs()),
              value: acceleration,
            );
          }
        }
      }
    }
  }

  void _analyzeTurning() {
    if (_gyroscopeBuffer.length < 5) return;
    
    final recent = _gyroscopeBuffer.sublist(_gyroscopeBuffer.length - 5);
    
    // Calculate average angular velocity
    double totalAngularVelocity = 0;
    for (final event in recent) {
      totalAngularVelocity += sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    }
    
    final avgAngularVelocity = totalAngularVelocity / recent.length;
    
    if (avgAngularVelocity > _harshTurningThreshold && _locationBuffer.isNotEmpty) {
      _recordDrivingEvent(
        EventType.harshTurning,
        _locationBuffer.last,
        severity: _calculateSeverity(avgAngularVelocity, _harshTurningThreshold),
        value: avgAngularVelocity,
      );
    }
  }

  void _analyzeSpeeding() {
    if (_locationBuffer.isEmpty) return;
    
    final current = _locationBuffer.last;
    
    // This would typically involve checking against speed limits from mapping service
    // For now, we'll use a simple speed threshold
    if (current.speed != null && current.speed! > 120.0) { // 120 km/h threshold
      _recordDrivingEvent(
        EventType.speeding,
        current,
        severity: _calculateSeverity(current.speed! - 120.0, _speedingThreshold),
        value: current.speed!,
      );
    }
  }

  void _analyzeDistraction() {
    // This would analyze phone usage patterns, but requires additional sensors/permissions
    // Placeholder for future implementation
  }

  void _recordDrivingEvent(
    EventType eventType,
    LocationModel location, {
    required EventSeverity severity,
    required double value,
  }) {
    final event = DrivingEvent(
      id: '${eventType.toString()}_${DateTime.now().millisecondsSinceEpoch}',
      driverId: _currentDriverId!,
      vehicleId: _currentVehicleId!,
      eventType: eventType,
      severity: severity,
      location: location,
      timestamp: DateTime.now(),
      value: value,
      sensorData: _getCurrentSensorData(),
    );
    
    _drivingEvents.add(event);
    _eventController.add(event);
    
    // Store in Firestore
    _storeDrivingEvent(event);
    
    debugPrint('DriverBehaviorService: Recorded ${eventType.toString()} event');
  }

  EventSeverity _calculateSeverity(double value, double threshold) {
    final ratio = value / threshold;
    
    if (ratio < 1.5) return EventSeverity.low;
    if (ratio < 2.0) return EventSeverity.medium;
    if (ratio < 3.0) return EventSeverity.high;
    return EventSeverity.critical;
  }

  Map<String, dynamic> _getCurrentSensorData() {
    return {
      'accelerometer': _accelerometerBuffer.isNotEmpty 
          ? {
              'x': _accelerometerBuffer.last.x,
              'y': _accelerometerBuffer.last.y,
              'z': _accelerometerBuffer.last.z,
            }
          : null,
      'gyroscope': _gyroscopeBuffer.isNotEmpty
          ? {
              'x': _gyroscopeBuffer.last.x,
              'y': _gyroscopeBuffer.last.y,
              'z': _gyroscopeBuffer.last.z,
            }
          : null,
    };
  }

  Future<void> _storeDrivingEvent(DrivingEvent event) async {
    try {
      await _firestore
          .collection('driving_events')
          .doc(event.id)
          .set(event.toMap());
          
    } catch (e) {
      debugPrint('DriverBehaviorService: Error storing event: $e');
    }
  }

  Future<List<DrivingEvent>> _getDrivingEvents(
    String driverId,
    DateTime? startDate,
    DateTime? endDate, [
    EventType? eventType,
    int limit = 100,
  ]) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();
      
      Query query = _firestore
          .collection('driving_events')
          .where('driverId', isEqualTo: driverId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate);
      
      if (eventType != null) {
        query = query.where('eventType', isEqualTo: eventType.toString());
      }
      
      query = query.orderBy('timestamp', descending: true).limit(limit);
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => DrivingEvent.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
          
    } catch (e) {
      debugPrint('DriverBehaviorService: Error getting driving events: $e');
      return [];
    }
  }

  DriverScore _calculateDriverScore(String driverId, List<DrivingEvent> events) {
    if (events.isEmpty) {
      return DriverScore(
        driverId: driverId,
        overallScore: 100,
        accelerationScore: 100,
        brakingScore: 100,
        turningScore: 100,
        speedingScore: 100,
        distractionScore: 100,
        totalEvents: 0,
        totalDistance: 0,
        totalTime: Duration.zero,
        calculatedAt: DateTime.now(),
      );
    }
    
    // Calculate component scores
    final accelerationEvents = events.where((e) => e.eventType == EventType.harshAcceleration).length;
    final brakingEvents = events.where((e) => e.eventType == EventType.harshBraking).length;
    final turningEvents = events.where((e) => e.eventType == EventType.harshTurning).length;
    final speedingEvents = events.where((e) => e.eventType == EventType.speeding).length;
    
    // Simple scoring algorithm (can be made more sophisticated)
    final accelerationScore = max(0, 100 - (accelerationEvents * 5));
    final brakingScore = max(0, 100 - (brakingEvents * 5));
    final turningScore = max(0, 100 - (turningEvents * 5));
    final speedingScore = max(0, 100 - (speedingEvents * 3));
    
    final overallScore = (accelerationScore + brakingScore + turningScore + speedingScore) ~/ 4;
    
    return DriverScore(
      driverId: driverId,
      overallScore: overallScore,
      accelerationScore: accelerationScore,
      brakingScore: brakingScore,
      turningScore: turningScore,
      speedingScore: speedingScore,
      distractionScore: 100, // Placeholder
      totalEvents: events.length,
      totalDistance: 0, // Would need to calculate from trips
      totalTime: Duration.zero, // Would need to calculate from trips
      calculatedAt: DateTime.now(),
    );
  }

  Future<void> _processFinalAnalysis() async {
    if (_currentDriverId == null) return;
    
    final score = _calculateDriverScore(_currentDriverId!, _drivingEvents);
    _driverScores[_currentDriverId!] = score;
    _scoreController.add(score);
    
    // Store score in Firestore
    try {
      await _firestore
          .collection('driver_scores')
          .doc('${_currentDriverId}_${DateTime.now().millisecondsSinceEpoch}')
          .set(score.toMap());
    } catch (e) {
      debugPrint('DriverBehaviorService: Error storing score: $e');
    }
  }
}

// Enums
enum EventType {
  harshAcceleration,
  harshBraking,
  harshTurning,
  speeding,
  phoneUsage,
  fatigueDriving,
}

enum EventSeverity { low, medium, high, critical }

// Data classes
class DrivingEvent {
  final String id;
  final String driverId;
  final String vehicleId;
  final EventType eventType;
  final EventSeverity severity;
  final LocationModel location;
  final DateTime timestamp;
  final double value;
  final Map<String, dynamic>? sensorData;
  final String? description;

  DrivingEvent({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.eventType,
    required this.severity,
    required this.location,
    required this.timestamp,
    required this.value,
    this.sensorData,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'eventType': eventType.toString(),
      'severity': severity.toString(),
      'location': location.toMap(),
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'sensorData': sensorData,
      'description': description,
    };
  }

  factory DrivingEvent.fromMap(Map<String, dynamic> map) {
    return DrivingEvent(
      id: map['id'],
      driverId: map['driverId'],
      vehicleId: map['vehicleId'],
      eventType: EventType.values.firstWhere(
        (e) => e.toString() == map['eventType'],
      ),
      severity: EventSeverity.values.firstWhere(
        (e) => e.toString() == map['severity'],
      ),
      location: LocationModel.fromMap(map['location'], map['location']['id'] ?? ''),
      timestamp: DateTime.parse(map['timestamp']),
      value: map['value'].toDouble(),
      sensorData: map['sensorData']?.cast<String, dynamic>(),
      description: map['description'],
    );
  }
}

class DriverScore {
  final String driverId;
  final int overallScore;
  final int accelerationScore;
  final int brakingScore;
  final int turningScore;
  final int speedingScore;
  final int distractionScore;
  final int totalEvents;
  final double totalDistance;
  final Duration totalTime;
  final DateTime calculatedAt;

  DriverScore({
    required this.driverId,
    required this.overallScore,
    required this.accelerationScore,
    required this.brakingScore,
    required this.turningScore,
    required this.speedingScore,
    required this.distractionScore,
    required this.totalEvents,
    required this.totalDistance,
    required this.totalTime,
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'overallScore': overallScore,
      'accelerationScore': accelerationScore,
      'brakingScore': brakingScore,
      'turningScore': turningScore,
      'speedingScore': speedingScore,
      'distractionScore': distractionScore,
      'totalEvents': totalEvents,
      'totalDistance': totalDistance,
      'totalTime': totalTime.inMilliseconds,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory DriverScore.fromMap(Map<String, dynamic> map) {
    return DriverScore(
      driverId: map['driverId'],
      overallScore: map['overallScore'],
      accelerationScore: map['accelerationScore'],
      brakingScore: map['brakingScore'],
      turningScore: map['turningScore'],
      speedingScore: map['speedingScore'],
      distractionScore: map['distractionScore'],
      totalEvents: map['totalEvents'],
      totalDistance: map['totalDistance'].toDouble(),
      totalTime: Duration(milliseconds: map['totalTime']),
      calculatedAt: DateTime.parse(map['calculatedAt']),
    );
  }
}

class FleetBehaviorSummary {
  final int totalDrivers;
  final int totalEvents;
  final double averageScore;
  final int harshAccelerationEvents;
  final int harshBrakingEvents;
  final int harshTurningEvents;
  final int speedingEvents;
  final Map<EventSeverity, int> eventsBySeverity;
  final DateTime calculatedAt;

  FleetBehaviorSummary({
    required this.totalDrivers,
    required this.totalEvents,
    required this.averageScore,
    required this.harshAccelerationEvents,
    required this.harshBrakingEvents,
    required this.harshTurningEvents,
    required this.speedingEvents,
    required this.eventsBySeverity,
    required this.calculatedAt,
  });

  factory FleetBehaviorSummary.fromEvents(List<DrivingEvent> events) {
    if (events.isEmpty) return FleetBehaviorSummary.empty();

    final Set<String> drivers = events.map((e) => e.driverId).toSet();
    final Map<EventSeverity, int> severityCount = {};
    
    int accelerationEvents = 0;
    int brakingEvents = 0;
    int turningEvents = 0;
    int speedingEvents = 0;

    for (final event in events) {
      severityCount[event.severity] = (severityCount[event.severity] ?? 0) + 1;
      
      switch (event.eventType) {
        case EventType.harshAcceleration:
          accelerationEvents++;
          break;
        case EventType.harshBraking:
          brakingEvents++;
          break;
        case EventType.harshTurning:
          turningEvents++;
          break;
        case EventType.speeding:
          speedingEvents++;
          break;
        default:
          break;
      }
    }

    return FleetBehaviorSummary(
      totalDrivers: drivers.length,
      totalEvents: events.length,
      averageScore: 85.0, // Would calculate based on actual scores
      harshAccelerationEvents: accelerationEvents,
      harshBrakingEvents: brakingEvents,
      harshTurningEvents: turningEvents,
      speedingEvents: speedingEvents,
      eventsBySeverity: severityCount,
      calculatedAt: DateTime.now(),
    );
  }

  factory FleetBehaviorSummary.empty() {
    return FleetBehaviorSummary(
      totalDrivers: 0,
      totalEvents: 0,
      averageScore: 0,
      harshAccelerationEvents: 0,
      harshBrakingEvents: 0,
      harshTurningEvents: 0,
      speedingEvents: 0,
      eventsBySeverity: {},
      calculatedAt: DateTime.now(),
    );
  }
}
