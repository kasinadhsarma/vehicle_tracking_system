import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Desktop-compatible tracking service that works without Firebase
/// Implements local tracking for development and testing
class DesktopTrackingService {
  static DesktopTrackingService? _instance;
  static DesktopTrackingService get instance => _instance ??= DesktopTrackingService._();
  
  DesktopTrackingService._();

  // Stream controllers for fake data
  final StreamController<TrackingUpdate> _trackingController = 
      StreamController<TrackingUpdate>.broadcast();
  final StreamController<LiveTrackingData> _liveDataController = 
      StreamController<LiveTrackingData>.broadcast();
  
  bool _isInitialized = false;
  bool _isTracking = false;
  Timer? _mockDataTimer;

  /// Initialize the desktop tracking service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('Initializing desktop tracking service...');
      _isInitialized = true;
      debugPrint('Desktop tracking service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing desktop tracking service: $e');
      rethrow;
    }
  }

  /// Start tracking simulation
  Future<void> startTracking(String vehicleId, String driverId) async {
    if (_isTracking) return;
    
    _isTracking = true;
    _startMockDataGeneration(vehicleId, driverId);
    debugPrint('Desktop tracking started for vehicle: $vehicleId');
  }

  /// Stop tracking simulation
  Future<void> stopTracking() async {
    _isTracking = false;
    _mockDataTimer?.cancel();
    debugPrint('Desktop tracking stopped');
  }

  /// Start generating mock location data
  void _startMockDataGeneration(String vehicleId, String driverId) {
    double lat = 40.7128; // Start in NYC
    double lng = -74.0060;
    double speed = 0.0;
    double heading = 0.0;
    
    _mockDataTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      
      // Simulate movement
      lat += (Random().nextDouble() - 0.5) * 0.001; // Small random movement
      lng += (Random().nextDouble() - 0.5) * 0.001;
      speed = Random().nextDouble() * 60; // Speed 0-60 km/h
      heading = Random().nextDouble() * 360; // Random heading
      
      final mockLocation = MockLocationModel(
        id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
        userId: driverId,
        vehicleId: vehicleId,
        latitude: lat,
        longitude: lng,
        speed: speed,
        heading: heading,
        timestamp: DateTime.now(),
      );
      
      // Emit tracking update
      final trackingUpdate = TrackingUpdate(
        sessionId: 'session_$vehicleId',
        location: mockLocation,
        timestamp: DateTime.now(),
        status: TrackingStatus.active,
      );
      
      _trackingController.add(trackingUpdate);
      
      // Emit live tracking data
      final liveData = LiveTrackingData(
        vehicleId: vehicleId,
        driverId: driverId,
        currentLocation: mockLocation,
        lastUpdate: DateTime.now(),
        isActive: true,
        speed: speed,
        heading: heading,
      );
      
      _liveDataController.add(liveData);
    });
  }

  /// Get live tracking data stream
  Stream<LiveTrackingData> getLiveTrackingData(String vehicleId) {
    return _liveDataController.stream
        .where((data) => data.vehicleId == vehicleId);
  }

  /// Get tracking updates stream
  Stream<TrackingUpdate> get trackingStream => _trackingController.stream;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Get fleet overview with mock data
  Future<FleetOverview> getFleetOverview() async {
    // Return mock fleet data
    final mockVehicles = [
      LiveTrackingData(
        vehicleId: 'VH-001',
        driverId: 'driver_001',
        currentLocation: MockLocationModel(
          id: 'loc_1',
          userId: 'driver_001',
          vehicleId: 'VH-001',
          latitude: 40.7128,
          longitude: -74.0060,
          speed: 25.0,
          heading: 90.0,
          timestamp: DateTime.now(),
        ),
        lastUpdate: DateTime.now(),
        isActive: true,
        speed: 25.0,
        heading: 90.0,
      ),
      LiveTrackingData(
        vehicleId: 'VH-002',
        driverId: 'driver_002',
        currentLocation: MockLocationModel(
          id: 'loc_2',
          userId: 'driver_002',
          vehicleId: 'VH-002',
          latitude: 40.7589,
          longitude: -73.9851,
          speed: 0.0,
          heading: 0.0,
          timestamp: DateTime.now(),
        ),
        lastUpdate: DateTime.now(),
        isActive: false,
        speed: 0.0,
        heading: 0.0,
      ),
    ];

    return FleetOverview(
      activeVehicles: mockVehicles.where((v) => v.isActive).length,
      totalTripsToday: 5,
      liveTrackingData: mockVehicles,
      lastUpdated: DateTime.now(),
    );
  }

  /// Dispose resources
  void dispose() {
    _mockDataTimer?.cancel();
    _trackingController.close();
    _liveDataController.close();
    _isInitialized = false;
    _isTracking = false;
  }
}

// Simple data classes for desktop mode
class MockLocationModel {
  final String id;
  final String userId;
  final String? vehicleId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  MockLocationModel({
    required this.id,
    required this.userId,
    this.vehicleId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'vehicleId': vehicleId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TrackingUpdate {
  final String sessionId;
  final MockLocationModel location;
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
  final MockLocationModel currentLocation;
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

  factory LiveTrackingData.empty(String vehicleId) {
    return LiveTrackingData(
      vehicleId: vehicleId,
      driverId: '',
      currentLocation: MockLocationModel(
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

enum TrackingStatus { active, paused, stopped }
