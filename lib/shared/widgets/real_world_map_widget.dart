import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/location_model.dart';
import '../../core/services/real_time_tracking_service.dart';
import '../../core/services/geofence_service.dart';
import '../../core/services/driver_behavior_service.dart';

/// Comprehensive real-world mapping widget
/// Displays live vehicle tracking with geofences, routes, and behavior analysis
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
  final RealTimeTrackingService _trackingService = RealTimeTrackingService.instance;
  final GoogleMapsService _mapsService = GoogleMapsService.instance;
  final GeofenceService _geofenceService = GeofenceService.instance;

  // Google Maps controller
  GoogleMapController? _mapController;
  
  // Map state
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};
  final Set<Circle> _circles = {};
  
  // Streams
  StreamSubscription<TrackingUpdate>? _trackingSubscription;
  StreamSubscription<GeofenceEvent>? _geofenceSubscription;
  StreamSubscription<DrivingEvent>? _behaviorSubscription;
  StreamSubscription<LiveTrackingData>? _liveDataSubscription;
  
  // Data
  LocationModel? _currentLocation;
  List<LocationModel> _routePoints = [];
  List<Geofence> _geofences = [];
  List<DrivingEvent> _behaviorEvents = [];
  
  // Map settings
  late LatLng _mapCenter;
  bool _isMapReady = false;
  bool _followVehicle = true;
  
  @override
  void initState() {
    super.initState();
    _mapCenter = widget.initialCenter ?? const LatLng(37.7749, -122.4194); // Default to San Francisco
    _initializeMap();
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _geofenceSubscription?.cancel();
    _behaviorSubscription?.cancel();
    _liveDataSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    // Load geofences if enabled
    if (widget.showGeofences) {
      await _loadGeofences();
    }
    
    // Start listening to tracking updates
    if (widget.vehicleId != null) {
      _setupTrackingListeners();
    }
  }

  void _setupTrackingListeners() {
    // Listen to real-time tracking updates
    _trackingSubscription = _trackingService.trackingStream.listen((update) {
      setState(() {
        _currentLocation = update.location;
        _routePoints.add(update.location);
        
        // Keep route manageable
        if (_routePoints.length > 1000) {
          _routePoints = _routePoints.sublist(_routePoints.length - 500);
        }
      });
      
      _updateVehicleMarker(update.location);
      _updateRoutePolyline();
      
      if (_followVehicle) {
        _centerMapOnLocation(update.location);
      }
    });

    // Listen to geofence events
    if (widget.showGeofences) {
      _geofenceSubscription = _geofenceService.eventStream.listen((event) {
        _showGeofenceEventPopup(event);
      });
    }

    // Listen to behavior events
    if (widget.showBehaviorEvents) {
      _behaviorSubscription = _trackingService.trackingStream.listen((update) {
        // Behavior events are handled within the tracking update
      });
    }

    // Listen to live tracking data
    if (widget.vehicleId != null) {
      _liveDataSubscription = _trackingService
          .getLiveTrackingData(widget.vehicleId!)
          .listen((liveData) {
        if (liveData.isActive) {
          setState(() {
            _currentLocation = liveData.currentLocation;
          });
          _updateVehicleMarker(liveData.currentLocation);
        }
      });
    }
  }

  Future<void> _loadGeofences() async {
    try {
      _geofences = _geofenceService.activeGeofences;
      _updateGeofenceOverlays();
    } catch (e) {
      debugPrint('Error loading geofences: $e');
    }
  }

  void _updateVehicleMarker(LocationModel location) {
    final markerId = MarkerId('vehicle_${widget.vehicleId ?? 'current'}');
    
    final marker = Marker(
      markerId: markerId,
      position: LatLng(location.latitude, location.longitude),
      icon: _getVehicleIcon(location),
      rotation: location.heading ?? 0.0,
      infoWindow: InfoWindow(
        title: 'Vehicle ${widget.vehicleId ?? 'Current'}',
        snippet: _formatLocationInfo(location),
      ),
      onTap: () => _onVehicleMarkerTap(location),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId == markerId);
      _markers.add(marker);
    });
  }

  BitmapDescriptor _getVehicleIcon(LocationModel location) {
    // Return different icons based on vehicle state
    if (location.speed != null && location.speed! > 5.0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  String _formatLocationInfo(LocationModel location) {
    final speed = location.speed?.toStringAsFixed(1) ?? '0.0';
    final time = '${location.timestamp.hour}:${location.timestamp.minute.toString().padLeft(2, '0')}';
    return 'Speed: ${speed} km/h • $time';
  }

  void _updateRoutePolyline() {
    if (!widget.showRoutes || _routePoints.length < 2) return;

    final polylineId = PolylineId('route_${widget.vehicleId ?? 'current'}');
    
    final polyline = Polyline(
      polylineId: polylineId,
      points: _routePoints.map((loc) => LatLng(loc.latitude, loc.longitude)).toList(),
      color: _getRouteColor(),
      width: 4,
      patterns: [PatternItem.dot, PatternItem.gap(10)],
    );

    setState(() {
      _polylines.removeWhere((p) => p.polylineId == polylineId);
      _polylines.add(polyline);
    });
  }

  Color _getRouteColor() {
    // Color code based on recent behavior events
    if (_behaviorEvents.isNotEmpty) {
      final recentEvent = _behaviorEvents.last;
      switch (recentEvent.severity) {
        case EventSeverity.critical:
          return Colors.red;
        case EventSeverity.high:
          return Colors.orange;
        case EventSeverity.medium:
          return Colors.yellow;
        case EventSeverity.low:
        default:
          return Colors.blue;
      }
    }
    return Colors.blue;
  }

  void _updateGeofenceOverlays() {
    if (!widget.showGeofences) return;

    final newCircles = <Circle>{};
    final newPolygons = <Polygon>{};

    for (final geofence in _geofences) {
      if (geofence.type == GeofenceType.circular && 
          geofence.centerLatitude != null && 
          geofence.centerLongitude != null &&
          geofence.radius != null) {
        
        final circle = Circle(
          circleId: CircleId(geofence.id),
          center: LatLng(geofence.centerLatitude!, geofence.centerLongitude!),
          radius: geofence.radius!,
          fillColor: _getGeofenceColor(geofence).withOpacity(0.2),
          strokeColor: _getGeofenceColor(geofence),
          strokeWidth: 2,
          onTap: () => _onGeofenceTap(geofence),
        );
        
        newCircles.add(circle);
        
      } else if (geofence.type == GeofenceType.polygon && 
                 geofence.polygonVertices != null) {
        
        final polygon = Polygon(
          polygonId: PolygonId(geofence.id),
          points: geofence.polygonVertices!
              .map((vertex) => LatLng(vertex.latitude, vertex.longitude))
              .toList(),
          fillColor: _getGeofenceColor(geofence).withOpacity(0.2),
          strokeColor: _getGeofenceColor(geofence),
          strokeWidth: 2,
          onTap: () => _onGeofenceTap(geofence),
        );
        
        newPolygons.add(polygon);
      }
    }

    setState(() {
      _circles.clear();
      _circles.addAll(newCircles);
      _polygons.clear();
      _polygons.addAll(newPolygons);
    });
  }

  Color _getGeofenceColor(Geofence geofence) {
    // Color code geofences by type or metadata
    if (geofence.metadata?['type'] == 'restricted') {
      return Colors.red;
    } else if (geofence.metadata?['type'] == 'warning') {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _centerMapOnLocation(LocationModel location) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(location.latitude, location.longitude),
        ),
      );
    }
  }

  void _onVehicleMarkerTap(LocationModel location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => VehicleInfoBottomSheet(
        location: location,
        vehicleId: widget.vehicleId,
        driverId: widget.driverId,
      ),
    );
  }

  void _onGeofenceTap(Geofence geofence) {
    showDialog(
      context: context,
      builder: (context) => GeofenceInfoDialog(geofence: geofence),
    );
  }

  void _showGeofenceEventPopup(GeofenceEvent event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${event.eventType == GeofenceEventType.enter ? 'Entered' : 'Exited'} ${event.geofenceName}',
        ),
        backgroundColor: event.eventType == GeofenceEventType.enter 
            ? Colors.green 
            : Colors.orange,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Details',
          onPressed: () => _onGeofenceEventTap(event),
        ),
      ),
    );
  }

  void _onGeofenceEventTap(GeofenceEvent event) {
    showDialog(
      context: context,
      builder: (context) => GeofenceEventDialog(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: widget.mapType,
          initialCameraPosition: CameraPosition(
            target: _mapCenter,
            zoom: widget.initialZoom,
          ),
          markers: _markers,
          polylines: _polylines,
          polygons: _polygons,
          circles: _circles,
          onMapCreated: _onMapCreated,
          onTap: _onMapTap,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        _buildMapControls(),
        _buildMapInfo(),
      ],
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    widget.onMapReady?.call();
  }

  void _onMapTap(LatLng position) {
    widget.onLocationTap?.call(position);
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          _buildControlButton(
            icon: _followVehicle ? Icons.gps_fixed : Icons.gps_not_fixed,
            onPressed: () {
              setState(() {
                _followVehicle = !_followVehicle;
              });
              if (_followVehicle && _currentLocation != null) {
                _centerMapOnLocation(_currentLocation!);
              }
            },
            tooltip: _followVehicle ? 'Stop following' : 'Follow vehicle',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.layers,
            onPressed: _showMapTypeSelector,
            tooltip: 'Map type',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.refresh,
            onPressed: _refreshMap,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildMapInfo() {
    if (_currentLocation == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatLocationInfo(_currentLocation!),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (_routePoints.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    'Distance',
                    '${_calculateTotalDistance().toStringAsFixed(1)} km',
                  ),
                  _buildInfoItem(
                    'Duration',
                    _formatDuration(_calculateTotalDuration()),
                  ),
                  _buildInfoItem(
                    'Speed',
                    '${_currentLocation!.speed?.toStringAsFixed(1) ?? '0'} km/h',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  double _calculateTotalDistance() {
    double total = 0.0;
    for (int i = 1; i < _routePoints.length; i++) {
      total += _routePoints[i].distanceTo(_routePoints[i - 1]) / 1000; // Convert to km
    }
    return total;
  }

  Duration _calculateTotalDuration() {
    if (_routePoints.length < 2) return Duration.zero;
    return _routePoints.last.timestamp.difference(_routePoints.first.timestamp);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Normal'),
              onTap: () => _changeMapType(MapType.normal),
            ),
            ListTile(
              leading: const Icon(Icons.satellite),
              title: const Text('Satellite'),
              onTap: () => _changeMapType(MapType.satellite),
            ),
            ListTile(
              leading: const Icon(Icons.terrain),
              title: const Text('Terrain'),
              onTap: () => _changeMapType(MapType.terrain),
            ),
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text('Hybrid'),
              onTap: () => _changeMapType(MapType.hybrid),
            ),
          ],
        ),
      ),
    );
  }

  void _changeMapType(MapType mapType) {
    Navigator.pop(context);
    // This would require updating the widget or using a state management solution
  }

  void _refreshMap() {
    _loadGeofences();
    if (_currentLocation != null) {
      _centerMapOnLocation(_currentLocation!);
    }
  }
}

// Supporting widgets
class VehicleInfoBottomSheet extends StatelessWidget {
  final LocationModel location;
  final String? vehicleId;
  final String? driverId;

  const VehicleInfoBottomSheet({
    Key? key,
    required this.location,
    this.vehicleId,
    this.driverId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Vehicle ID', vehicleId ?? 'Unknown'),
          _buildInfoRow('Driver ID', driverId ?? 'Unknown'),
          _buildInfoRow('Speed', '${location.speed?.toStringAsFixed(1) ?? '0'} km/h'),
          _buildInfoRow('Heading', '${location.heading?.toStringAsFixed(0) ?? '0'}°'),
          _buildInfoRow('Accuracy', '${location.accuracy?.toStringAsFixed(1) ?? '0'} m'),
          _buildInfoRow('Last Update', _formatTimestamp(location.timestamp)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class GeofenceInfoDialog extends StatelessWidget {
  final Geofence geofence;

  const GeofenceInfoDialog({Key? key, required this.geofence}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(geofence.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(geofence.description),
          const SizedBox(height: 8),
          Text('Type: ${geofence.type.toString()}'),
          Text('Active: ${geofence.isActive ? 'Yes' : 'No'}'),
          if (geofence.radius != null)
            Text('Radius: ${geofence.radius!.toStringAsFixed(0)} m'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class GeofenceEventDialog extends StatelessWidget {
  final GeofenceEvent event;

  const GeofenceEventDialog({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Geofence Event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event: ${event.eventType.toString()}'),
          Text('Geofence: ${event.geofenceName}'),
          Text('Vehicle: ${event.vehicleId ?? 'Unknown'}'),
          Text('Time: ${event.timestamp}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
