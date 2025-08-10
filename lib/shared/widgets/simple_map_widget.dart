import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/location_model.dart';
import '../../core/services/tracking_service_factory.dart';

/// Simplified real-world mapping widget
/// Displays live vehicle tracking with basic geofences and routes
class RealWorldMapWidget extends StatefulWidget {
  final String? vehicleId;
  final String? driverId;
  final bool showGeofences;
  final bool showRoutes;
  final bool showBehaviorEvents;
  final MapType mapType;
  final double initialZoom;
  final LatLng? initialCenter;
  final VoidCallback? onMapReady;
  final Function(LatLng)? onLocationTap;

  const RealWorldMapWidget({
    Key? key,
    this.vehicleId,
    this.driverId,
    this.showGeofences = true,
    this.showRoutes = true,
    this.showBehaviorEvents = true,
    this.mapType = MapType.normal,
    this.initialZoom = 15.0,
    this.initialCenter,
    this.onMapReady,
    this.onLocationTap,
  }) : super(key: key);

  @override
  State<RealWorldMapWidget> createState() => _RealWorldMapWidgetState();
}

class _RealWorldMapWidgetState extends State<RealWorldMapWidget> {
  // Services
  dynamic _trackingService;
  dynamic _geofenceService;

  // Google Maps controller
  GoogleMapController? _mapController;
  
  // Map state
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};
  final Set<Circle> _circles = {};

  // Tracking state
  bool _isInitialized = false;
  bool _isTracking = false;
  LocationModel? _currentLocation;
  
  // Data
  final List<LocationModel> _routePoints = [];
  final List<Map<String, dynamic>> _mockGeofences = [
    {
      'id': 'gf-001',
      'name': 'Downtown Zone',
      'lat': 40.7128,
      'lng': -74.0060,
      'radius': 500.0,
      'type': 'safe_zone'
    },
    {
      'id': 'gf-002',
      'name': 'Industrial Area',
      'lat': 40.7589,
      'lng': -73.9851,
      'radius': 300.0,
      'type': 'restricted'
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      _trackingService = TrackingServiceFactory.instance.getTrackingService();
      _geofenceService = TrackingServiceFactory.instance.getGeofenceService();
      
      await TrackingServiceFactory.instance.initializeTrackingService();
      
      setState(() {
        _isInitialized = true;
      });

      if (widget.vehicleId != null) {
        await _startTracking();
      }

      _setupGeofences();
    } catch (e) {
      debugPrint('Error initializing services: $e');
      setState(() {
        _isInitialized = true; // Still allow UI to load
      });
    }
  }

  Future<void> _startTracking() async {
    if (widget.vehicleId == null || !_isInitialized) return;

    try {
      await _trackingService.startTracking(widget.vehicleId!, widget.driverId ?? widget.vehicleId!);
      setState(() {
        _isTracking = true;
      });

      // Simulate location updates
      _simulateLocationUpdates();
    } catch (e) {
      debugPrint('Error starting tracking: $e');
    }
  }

  void _simulateLocationUpdates() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isTracking || !mounted) {
        timer.cancel();
        return;
      }

      // Simulate moving vehicle
      _updateVehicleLocation();
    });
  }

  void _updateVehicleLocation() {
    final baseLocation = widget.initialCenter ?? const LatLng(40.7128, -74.0060);
    final randomOffset = 0.001;
    
    final newLocation = LocationModel(
      id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'demo_user',
      vehicleId: widget.vehicleId,
      driverId: widget.driverId,
      latitude: baseLocation.latitude + (DateTime.now().millisecond % 100 - 50) * randomOffset / 50,
      longitude: baseLocation.longitude + (DateTime.now().millisecond % 100 - 50) * randomOffset / 50,
      timestamp: DateTime.now(),
      speed: 25.0 + (DateTime.now().millisecond % 20),
      heading: (DateTime.now().millisecond % 360).toDouble(),
      accuracy: 5.0,
    );

    setState(() {
      _currentLocation = newLocation;
      _routePoints.add(newLocation);
      if (_routePoints.length > 50) {
        _routePoints.removeAt(0); // Keep only last 50 points
      }
    });

    _updateMapMarkers();
    _updateMapPolylines();
  }

  void _updateMapMarkers() {
    _markers.clear();

    // Add vehicle marker
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId(widget.vehicleId ?? 'current_vehicle'),
          position: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          infoWindow: InfoWindow(
            title: 'Vehicle ${widget.vehicleId ?? 'Unknown'}',
            snippet: 'Speed: ${(_currentLocation!.speed ?? 0).toStringAsFixed(1)} km/h',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // Add mock vehicle markers
    _addMockVehicleMarkers();
  }

  void _addMockVehicleMarkers() {
    final mockVehicles = [
      {'id': 'VH-001', 'lat': 40.7128, 'lng': -74.0060, 'status': 'Active'},
      {'id': 'VH-002', 'lat': 40.7589, 'lng': -73.9851, 'status': 'Idle'},
      {'id': 'VH-003', 'lat': 40.7282, 'lng': -73.7949, 'status': 'Active'},
    ];

    for (final vehicle in mockVehicles) {
      if (vehicle['id'] != widget.vehicleId) {
        _markers.add(
          Marker(
            markerId: MarkerId(vehicle['id'] as String),
            position: LatLng(vehicle['lat'] as double, vehicle['lng'] as double),
            infoWindow: InfoWindow(
              title: 'Vehicle ${vehicle['id']}',
              snippet: 'Status: ${vehicle['status']}',
            ),
            icon: _getVehicleIcon(vehicle['status'] as String),
          ),
        );
      }
    }
  }

  BitmapDescriptor _getVehicleIcon(String status) {
    switch (status) {
      case 'Active':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'Idle':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'Offline':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _updateMapPolylines() {
    if (!widget.showRoutes || _routePoints.length < 2) return;

    _polylines.clear();

    final routePoints = _routePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('vehicle_route'),
        points: routePoints,
        color: Colors.blue,
        width: 3,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  void _setupGeofences() {
    if (!widget.showGeofences) return;

    _circles.clear();

    for (final geofence in _mockGeofences) {
      final color = geofence['type'] == 'safe_zone' ? Colors.green : Colors.red;
      
      _circles.add(
        Circle(
          circleId: CircleId(geofence['id']),
          center: LatLng(geofence['lat'], geofence['lng']),
          radius: geofence['radius'],
          fillColor: color.withOpacity(0.2),
          strokeColor: color,
          strokeWidth: 2,
        ),
      );

      // Add geofence center marker
      _markers.add(
        Marker(
          markerId: MarkerId('${geofence['id']}_center'),
          position: LatLng(geofence['lat'], geofence['lng']),
          infoWindow: InfoWindow(
            title: geofence['name'],
            snippet: 'Type: ${geofence['type']}\nRadius: ${geofence['radius']}m',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            geofence['type'] == 'safe_zone' 
                ? BitmapDescriptor.hueGreen 
                : BitmapDescriptor.hueRed,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing Real-Time Map...'),
          ],
        ),
      );
    }

    // For web, show a placeholder
    if (kIsWeb) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.green.shade100],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 120, color: Colors.blue.shade600),
            const SizedBox(height: 24),
            Text(
              'Real-World Map View',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Advanced mapping features available on desktop',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            if (_isTracking)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.gps_fixed, color: Colors.green.shade600, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Tracking Active',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Vehicle: ${widget.vehicleId ?? 'Unknown'}',
                      style: TextStyle(color: Colors.green.shade600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialCenter ?? const LatLng(40.7128, -74.0060),
        zoom: widget.initialZoom,
      ),
      mapType: widget.mapType,
      markers: _markers,
      polylines: _polylines,
      circles: _circles,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        widget.onMapReady?.call();
        
        // Set up initial markers and geofences
        _updateMapMarkers();
        _setupGeofences();
      },
      onTap: widget.onLocationTap,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: true,
      compassEnabled: true,
      trafficEnabled: false,
      buildingsEnabled: true,
      indoorViewEnabled: true,
    );
  }
}
