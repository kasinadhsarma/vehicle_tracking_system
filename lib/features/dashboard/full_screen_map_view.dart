import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FullScreenMapView extends StatefulWidget {
  const FullScreenMapView({super.key});

  @override
  State<FullScreenMapView> createState() => _FullScreenMapViewState();
}

class _FullScreenMapViewState extends State<FullScreenMapView> {
  GoogleMapController? _mapController;
  
  // Vadodara location
  static const LatLng _vadodaraCenter = LatLng(22.3072, 73.1812);
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isTrackingMode = false;

  @override
  void initState() {
    super.initState();
    _setupMarkers();
  }

  void _setupMarkers() {
    _markers.addAll([
      // Current location marker
      Marker(
        markerId: const MarkerId('current_location'),
        position: _vadodaraCenter,
        infoWindow: const InfoWindow(
          title: 'Your Current Location',
          snippet: 'Vadodara, Gujarat',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      
      // Laxmi Vilas Palace
      Marker(
        markerId: const MarkerId('laxmi_vilas_palace'),
        position: const LatLng(22.3006, 73.1731),
        infoWindow: const InfoWindow(
          title: 'Laxmi Vilas Palace',
          snippet: 'Historic Royal Palace',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      
      // Sayaji Garden
      Marker(
        markerId: const MarkerId('sayaji_garden'),
        position: const LatLng(22.3067, 73.1866),
        infoWindow: const InfoWindow(
          title: 'Sayaji Garden',
          snippet: 'Beautiful Public Park',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      
      // Railway Station
      Marker(
        markerId: const MarkerId('railway_station'),
        position: const LatLng(22.3131, 73.1651),
        infoWindow: const InfoWindow(
          title: 'Vadodara Railway Station',
          snippet: 'Main Railway Junction',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
      
      // Alkapuri Circle
      Marker(
        markerId: const MarkerId('alkapuri_circle'),
        position: const LatLng(22.2888, 73.2089),
        infoWindow: const InfoWindow(
          title: 'Alkapuri Circle',
          snippet: 'Shopping & Business Area',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ),
    ]);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _toggleTrackingMode() {
    setState(() {
      _isTrackingMode = !_isTrackingMode;
    });
    
    if (_isTrackingMode) {
      _showTrackingPolyline();
      Get.snackbar(
        'Tracking Mode On',
        'Now tracking your movement in real-time',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } else {
      setState(() {
        _polylines.clear();
      });
      Get.snackbar(
        'Tracking Mode Off',
        'GPS tracking stopped',
        backgroundColor: const Color(0xFF757575),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _showTrackingPolyline() {
    // Demo route polyline showing a path through Vadodara
    const List<LatLng> routePoints = [
      LatLng(22.3072, 73.1812), // Start point
      LatLng(22.3067, 73.1866), // Sayaji Garden
      LatLng(22.3006, 73.1731), // Laxmi Vilas Palace
      LatLng(22.3131, 73.1651), // Railway Station
      LatLng(22.2888, 73.2089), // Alkapuri Circle
    ];

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('tracking_route'),
          points: routePoints,
          color: const Color(0xFF4CAF50),
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    });
  }

  void _centerOnCurrentLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: _vadodaraCenter,
          zoom: 15.0,
          tilt: 45.0,
        ),
      ),
    );
  }

  void _switchMapType() {
    // Cycle through map types
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Map Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.map, color: Color(0xFF4CAF50)),
              title: const Text('Normal'),
              onTap: () {
                Navigator.pop(context);
                // Update map type to normal
              },
            ),
            ListTile(
              leading: const Icon(Icons.satellite, color: Color(0xFF4CAF50)),
              title: const Text('Satellite'),
              onTap: () {
                Navigator.pop(context);
                // Update map type to satellite
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain, color: Color(0xFF4CAF50)),
              title: const Text('Terrain'),
              onTap: () {
                Navigator.pop(context);
                // Update map type to terrain
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen Google Maps
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _vadodaraCenter,
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            buildingsEnabled: true,
            trafficEnabled: true,
            onTap: (LatLng position) {
              Get.snackbar(
                'Location Tapped',
                'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
                backgroundColor: const Color(0xFF4CAF50),
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          ),
          
          // Top app bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF2E3A59),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vadodara Live Map',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Your mobile device GPS tracker',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _switchMapType,
                      icon: const Icon(
                        Icons.layers,
                        color: Color(0xFF2E3A59),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom control panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current location info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isTrackingMode ? Icons.gps_fixed : Icons.gps_not_fixed,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isTrackingMode ? 'GPS Tracking Active' : 'GPS Ready',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2E3A59),
                                ),
                              ),
                              const Text(
                                'Vadodara, Gujarat • Demo Mode',
                                style: TextStyle(
                                  color: Color(0xFF8A8A8A),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _isTrackingMode ? '0 km/h' : 'Stopped',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons row
                  Row(
                    children: [
                      // Center location button
                      Expanded(
                        child: Container(
                          height: 56,
                          margin: const EdgeInsets.only(right: 8),
                          child: ElevatedButton.icon(
                            onPressed: _centerOnCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 20),
                            label: const Text('Center'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Tracking toggle button
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed: _toggleTrackingMode,
                            icon: Icon(
                              _isTrackingMode ? Icons.stop : Icons.play_arrow,
                              size: 20,
                            ),
                            label: Text(
                              _isTrackingMode ? 'Stop Tracking' : 'Start Tracking',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTrackingMode 
                                  ? Colors.red 
                                  : const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Share location button
                      Expanded(
                        child: Container(
                          height: 56,
                          margin: const EdgeInsets.only(left: 8),
                          child: ElevatedButton(
                            onPressed: () {
                              Get.snackbar(
                                'Location Shared',
                                'Your Vadodara location has been shared!',
                                backgroundColor: const Color(0xFF4CAF50),
                                colorText: Colors.white,
                                snackPosition: SnackPosition.TOP,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Icon(Icons.share_location, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
