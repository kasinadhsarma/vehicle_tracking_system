import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Simple geofence service for desktop that doesn't require Firebase
class DesktopGeofenceService {
  static DesktopGeofenceService? _instance;
  static DesktopGeofenceService get instance => _instance ??= DesktopGeofenceService._();
  
  DesktopGeofenceService._();

  final List<Geofence> _activeGeofences = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('Initializing desktop geofence service...');
    _addMockGeofences();
    _isInitialized = true;
    debugPrint('Desktop geofence service initialized');
  }

  void _addMockGeofences() {
    _activeGeofences.addAll([
      Geofence(
        id: 'home_zone',
        name: 'Home Zone',
        description: 'Home office area',
        latitude: 40.7128,
        longitude: -74.0060,
        radius: 100.0,
        isActive: true,
      ),
      Geofence(
        id: 'office_zone',
        name: 'Office Zone',
        description: 'Main office building',
        latitude: 40.7589,
        longitude: -73.9851,
        radius: 200.0,
        isActive: true,
      ),
    ]);
  }

  List<Geofence> get activeGeofences => _activeGeofences.where((g) => g.isActive).toList();
  
  bool get isInitialized => _isInitialized;
}

class Geofence {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double radius;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  Geofence({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.isActive,
    this.metadata,
  });
}
