import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/location_model.dart';
import '../models/trip_model.dart';
import '../constants/app_colors.dart';
import 'firebase_service.dart';

class LocationService extends ChangeNotifier {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  LocationService._();

  bool _isTracking = false;
  LocationModel? _currentLocation;
  String? _currentTripId;
  List<LocationModel> _locationHistory = [];
  final FirebaseService _firebaseService = FirebaseService.instance;

  bool get isTracking => _isTracking;
  LocationModel? get currentLocation => _currentLocation;
  String? get currentTripId => _currentTripId;
  List<LocationModel> get locationHistory => _locationHistory;

  Future<bool> checkPermissions() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Save permission status
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyLocationPermissionGranted, true);

      return true;
    } catch (e) {
      debugPrint('Error checking location permissions: $e');
      return false;
    }
  }

  Future<bool> requestBackgroundPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        PermissionStatus status = await Permission.locationAlways.request();
        return status == PermissionStatus.granted;
      }
      return true; // iOS handles this differently
    } catch (e) {
      debugPrint('Error requesting background permission: $e');
      return false;
    }
  }

  Future<LocationModel?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkPermissions();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentLocation = LocationModel(
        id: '',
        userId: '', // Will be set when saving
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: DateTime.now(),
      );

      notifyListeners();
      return _currentLocation;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      throw Exception('Failed to get current location');
    }
  }

  Future<void> startTracking(String userId, {String? vehicleId}) async {
    try {
      bool hasPermission = await checkPermissions();
      if (!hasPermission) {
        throw Exception('Location permissions required for tracking');
      }

      _isTracking = true;

      // Create a new trip
      TripModel trip = TripModel(
        id: '',
        userId: userId,
        vehicleId: vehicleId ?? '',
        startTime: DateTime.now(),
        status: TripStatus.active,
      );

      _currentTripId = await _firebaseService.createTrip(trip);

      // Start location updates
      await _startLocationUpdates(userId);

      // Register background task
      await _registerBackgroundTask();

      notifyListeners();
      debugPrint('Location tracking started for user: $userId');
    } catch (e) {
      _isTracking = false;
      debugPrint('Error starting location tracking: $e');
      throw Exception('Failed to start location tracking');
    }
  }

  Future<void> stopTracking() async {
    try {
      if (!_isTracking) return;

      _isTracking = false;

      // End current trip
      if (_currentTripId != null) {
        await _firebaseService.updateTrip(_currentTripId!, {
          'endTime': Timestamp.fromDate(DateTime.now()),
          'status': 'completed',
          'totalDistance': _calculateTotalDistance(),
          'totalDuration': DateTime.now()
              .difference(
                _locationHistory.isNotEmpty
                    ? _locationHistory.first.timestamp
                    : DateTime.now(),
              )
              .inMinutes,
        });
      }

      // Cancel background task
      await Workmanager().cancelAll();

      _currentTripId = null;
      _locationHistory.clear();

      notifyListeners();
      debugPrint('Location tracking stopped');
    } catch (e) {
      debugPrint('Error stopping location tracking: $e');
      throw Exception('Failed to stop location tracking');
    }
  }

  Future<void> pauseTracking() async {
    try {
      if (!_isTracking || _currentTripId == null) return;

      await _firebaseService.updateTrip(_currentTripId!, {'status': 'paused'});

      _isTracking = false;
      notifyListeners();
      debugPrint('Location tracking paused');
    } catch (e) {
      debugPrint('Error pausing location tracking: $e');
      throw Exception('Failed to pause location tracking');
    }
  }

  Future<void> resumeTracking() async {
    try {
      if (_isTracking || _currentTripId == null) return;

      await _firebaseService.updateTrip(_currentTripId!, {'status': 'active'});

      _isTracking = true;
      notifyListeners();
      debugPrint('Location tracking resumed');
    } catch (e) {
      debugPrint('Error resuming location tracking: $e');
      throw Exception('Failed to resume location tracking');
    }
  }

  Future<void> _startLocationUpdates(String userId) async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        if (!_isTracking) return;

        LocationModel location = LocationModel(
          id: '',
          userId: userId,
          tripId: _currentTripId,
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
          timestamp: DateTime.now(),
        );

        _currentLocation = location;
        _locationHistory.add(location);

        // Save to Firebase
        await _firebaseService.saveLocation(location);

        notifyListeners();
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  Future<void> _registerBackgroundTask() async {
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

      await Workmanager().registerPeriodicTask(
        "location_update_task",
        "locationUpdate",
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    } catch (e) {
      debugPrint('Error registering background task: $e');
    }
  }

  double _calculateTotalDistance() {
    if (_locationHistory.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < _locationHistory.length; i++) {
      totalDistance += _locationHistory[i - 1].distanceTo(_locationHistory[i]);
    }
    return totalDistance;
  }

  Future<List<LocationModel>> getLocationHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      // Implementation depends on current user context
      // This would typically get the current user ID from AuthService
      return await _firebaseService.getLocationHistory(
        'current_user_id', // Replace with actual user ID
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting location history: $e');
      throw Exception('Failed to get location history');
    }
  }

  Stream<LocationModel?> getLocationStream(String userId) {
    return _firebaseService.getUserLocationStream(userId);
  }

  Future<double> calculateDistance(LocationModel from, LocationModel to) async {
    return from.distanceTo(to);
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Helper method to check if device is moving
  bool isDeviceMoving() {
    if (_locationHistory.length < 2) return false;

    LocationModel lastLocation = _locationHistory.last;
    LocationModel previousLocation =
        _locationHistory[_locationHistory.length - 2];

    // Check if speed is above threshold or distance moved
    bool speedMoving = (lastLocation.speed ?? 0) > 1.0; // 1 m/s threshold
    bool distanceMoving =
        lastLocation.distanceTo(previousLocation) > 10; // 10 meters

    return speedMoving || distanceMoving;
  }

  // Clean up old location data
  Future<void> cleanupOldLocations() async {
    try {
      DateTime cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      _locationHistory.removeWhere(
        (location) => location.timestamp.isBefore(cutoffDate),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error cleaning up old locations: $e');
    }
  }
}

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Background location update logic
      debugPrint('Background location update triggered');

      // Get current location and save to Firebase
      // This is a simplified version - you'd need to implement the full logic

      return Future.value(true);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}
