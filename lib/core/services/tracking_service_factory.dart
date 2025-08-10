import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'real_time_tracking_service.dart';
import 'desktop_tracking_service.dart';
// import 'geofence_service.dart';
import 'simple_geofence_service.dart';

/// Service factory that creates appropriate services based on platform
class TrackingServiceFactory {
  static TrackingServiceFactory? _instance;
  static TrackingServiceFactory get instance => _instance ??= TrackingServiceFactory._();
  
  TrackingServiceFactory._();

  dynamic _trackingService;
  dynamic _geofenceService;

  /// Get the appropriate tracking service for the current platform
  dynamic getTrackingService() {
    if (_trackingService != null) {
      return _trackingService;
    }

    try {
      // For now, always use desktop service to avoid Firebase issues
      debugPrint('Using desktop tracking service');
      _trackingService = DesktopTrackingService.instance;
    } catch (e) {
      debugPrint('Error creating tracking service, falling back to desktop: $e');
      _trackingService = DesktopTrackingService.instance;
    }

    return _trackingService;
  }

  /// Get the appropriate geofence service for the current platform
  dynamic getGeofenceService() {
    if (_geofenceService != null) {
      return _geofenceService;
    }

    try {
      // For now, always use desktop service to avoid Firebase issues
      debugPrint('Using desktop geofence service');
      _geofenceService = DesktopGeofenceService.instance;
    } catch (e) {
      debugPrint('Error creating geofence service, falling back to desktop: $e');
      _geofenceService = DesktopGeofenceService.instance;
    }

    return _geofenceService;
  }

  /// Check if Firebase is available and initialized
  bool _isFirebaseAvailable() {
    try {
      // This will throw if Firebase is not initialized
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initialize the tracking service
  Future<void> initializeTrackingService() async {
    final trackingService = getTrackingService();
    final geofenceService = getGeofenceService();
    
    if (trackingService is DesktopTrackingService) {
      await trackingService.initialize();
    }

    if (geofenceService is DesktopGeofenceService) {
      await geofenceService.initialize();
    }
  }
}
