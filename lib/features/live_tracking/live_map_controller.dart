import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/location_model.dart';
import '../../core/services/tracking_service_factory.dart';
import '../../core/services/vadodara_demo_service.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/services/pathfinding_service.dart';

/// Controller for live mapping functionality
class LiveMapController extends GetxController {
  // Map controller
  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;

  // Observables
  final RxBool isInitialized = false.obs;
  final RxBool isTracking = false.obs;
  final RxBool isMapReady = false.obs;
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxSet<Polygon> geofences = <Polygon>{}.obs;
  final RxMap<String, LocationModel> vehicleLocations = <String, LocationModel>{}.obs;
  final RxMap<String, List<LatLng>> vehicleRoutes = <String, List<LatLng>>{}.obs;
  final RxString selectedVehicleId = ''.obs;
  final RxBool followVehicle = true.obs;
  final Rx<MapType> mapType = MapType.normal.obs;
  final RxDouble zoom = 13.0.obs;
  final Rx<LatLng> center = const LatLng(22.3072, 73.1812).obs; // Vadodara Railway Station
  
  // Pathfinding observables
  final RxList<RouteResult> calculatedRoutes = <RouteResult>[].obs;
  final RxBool showAlgorithmRoutes = false.obs;
  final RxString selectedAlgorithm = 'A*'.obs;

  // Services
  late dynamic _trackingService;
  
  // Streams
  StreamSubscription? _trackingSubscription;
  Timer? _updateTimer;

  // Vehicle waypoint tracking
  final Map<String, int> _vehicleWaypointIndex = {};

  // Mock vehicle data for Vadodara, Gujarat demonstration
  final List<Map<String, dynamic>> _mockVehicles = 
      VadodaraDemoService.getVadodaraVehicles();

  @override
  void onInit() {
    super.onInit();
    initializeTracking();
  }

  @override
  void onClose() {
    stopTracking();
    _trackingSubscription?.cancel();
    _updateTimer?.cancel();
    super.onClose();
  }

  /// Initialize tracking service and start live updates
  Future<void> initializeTracking() async {
    try {
      _trackingService = TrackingServiceFactory.instance.getTrackingService();
      await TrackingServiceFactory.instance.initializeTrackingService();
      
      // Initialize mock vehicle positions and waypoint tracking
      for (var vehicle in _mockVehicles) {
        final vehicleId = vehicle['id'] as String;
        vehicleRoutes[vehicleId] = <LatLng>[];
        // Initialize each vehicle at waypoint 0 of their route
        _vehicleWaypointIndex[vehicleId] = 0;
      }
      
      isInitialized.value = true;
      await startLiveTracking();
    } catch (e) {
      debugPrint('Error initializing tracking: $e');
      Get.snackbar('Error', 'Failed to initialize tracking: $e');
    }
  }

  /// Start live tracking for all vehicles
  Future<void> startLiveTracking() async {
    if (isTracking.value) return;
    
    isTracking.value = true;
    
    // Wait a bit for map to be fully ready before starting updates
    await Future.delayed(const Duration(seconds: 2));
    
    // Start mock data generation for all vehicles
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateVehiclePositions();
    });
    
    debugPrint('Live tracking started for ${_mockVehicles.length} vehicles');
  }

  /// Stop live tracking
  Future<void> stopTracking() async {
    isTracking.value = false;
    _updateTimer?.cancel();
    _trackingSubscription?.cancel();
    debugPrint('Live tracking stopped');
  }

  /// Update positions for all vehicles
  void _updateVehiclePositions() {
    final now = DateTime.now();
    
    for (var vehicle in _mockVehicles) {
      final vehicleId = vehicle['id'] as String;
      final driverId = vehicle['driverId'] as String;
      
      // Get or create current position
      LocationModel? currentLocation = vehicleLocations[vehicleId];
      
      if (currentLocation == null) {
        // Initialize at starting position from Vadodara demo service
        final startLocation = vehicle['startLocation'] as LatLng?;
        if (startLocation == null) {
          // Fallback to Railway Station if startLocation is null
          currentLocation = LocationModel(
            id: 'loc_${now.millisecondsSinceEpoch}_$vehicleId',
            userId: driverId,
            vehicleId: vehicleId,
            driverId: driverId,
            latitude: 22.3072, // Railway Station latitude
            longitude: 73.1812, // Railway Station longitude
            speed: vehicle['currentSpeed']?.toDouble() ?? 0.0,
            heading: 0.0,
            accuracy: 5.0,
            timestamp: now,
          );
        } else {
          currentLocation = LocationModel(
            id: 'loc_${now.millisecondsSinceEpoch}_$vehicleId',
            userId: driverId,
            vehicleId: vehicleId,
            driverId: driverId,
            latitude: startLocation.latitude,
            longitude: startLocation.longitude,
            speed: vehicle['currentSpeed']?.toDouble() ?? 0.0,
            heading: 0.0,
            accuracy: 5.0,
            timestamp: now,
          );
        }
      } else {
        // Simulate realistic movement
        final newLocation = _generateNextPosition(currentLocation, vehicleId);
        currentLocation = newLocation;
      }
      
      // Update vehicle location
      vehicleLocations[vehicleId] = currentLocation;
      
      // Add to route
      final route = vehicleRoutes[vehicleId] ?? <LatLng>[];
      route.add(LatLng(currentLocation.latitude, currentLocation.longitude));
      
      // Limit route length for performance
      if (route.length > 100) {
        route.removeRange(0, route.length - 50);
      }
      vehicleRoutes[vehicleId] = route;
    }
    
    // Update markers and polylines
    _updateMarkersAndPolylines();
    
    // Follow selected vehicle if enabled
    if (followVehicle.value && selectedVehicleId.value.isNotEmpty) {
      final location = vehicleLocations[selectedVehicleId.value];
      if (location != null) {
        _animateToLocation(LatLng(location.latitude, location.longitude));
      }
    }
  }

  /// Generate next position for a vehicle with realistic movement in Vadodara
  LocationModel _generateNextPosition(LocationModel current, String vehicleId) {
    final now = DateTime.now();
    
    // Get vehicle info from mock data
    final vehicleData = _mockVehicles.firstWhere(
      (v) => v['id'] == vehicleId,
      orElse: () => _mockVehicles.first,
    );
    
    final vehicleType = vehicleData['type'] ?? 'taxi';
    final routeName = vehicleData['route'] ?? 'city_center_route';
    
    // Get current position as LatLng
    final currentLatLng = LatLng(current.latitude, current.longitude);
    
    // Get next position using improved Vadodara demo service with vehicle-specific key
    final nextLatLng = VadodaraDemoService.getNextPositionOnRoute(
      '${routeName}_$vehicleId', // Make route key unique per vehicle
      currentLatLng,
      current.speed ?? 30.0,
    );
    
    // Generate realistic speed for this vehicle type and location
    final newSpeed = VadodaraDemoService.generateRealisticSpeed(
      vehicleType,
      nextLatLng,
    );
    
    // Calculate heading (direction) between current and next position
    final heading = _calculateHeading(currentLatLng, nextLatLng);
    
    return LocationModel(
      id: 'loc_${now.millisecondsSinceEpoch}_$vehicleId',
      userId: current.userId,
      vehicleId: vehicleId,
      driverId: current.driverId,
      latitude: nextLatLng.latitude,
      longitude: nextLatLng.longitude,
      speed: newSpeed,
      heading: heading,
      accuracy: 5.0,
      timestamp: now,
    );
  }

  /// Calculate heading (bearing) between two points
  double _calculateHeading(LatLng from, LatLng to) {
    final lat1Rad = from.latitude * (math.pi / 180);
    final lat2Rad = to.latitude * (math.pi / 180);
    final deltaLngRad = (to.longitude - from.longitude) * (math.pi / 180);
    
    final x = math.sin(deltaLngRad) * math.cos(lat2Rad);
    final y = math.cos(lat1Rad) * math.sin(lat2Rad) - 
              math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLngRad);
    
    final headingRad = math.atan2(x, y);
    final headingDeg = (headingRad * (180 / math.pi) + 360) % 360;
    
    return headingDeg;
  }

  /// Update map markers and polylines
  void _updateMarkersAndPolylines() {
    final newMarkers = <Marker>{};
    final newPolylines = <Polyline>{};
    
    for (var vehicle in _mockVehicles) {
      final vehicleId = vehicle['id'] as String;
      final vehicleName = vehicle['name'] as String;
      final vehicleService = vehicle['service'] as String? ?? 'Unknown';
      final vehicleModel = vehicle['vehicleModel'] as String? ?? '';
      final driverName = vehicle['driverName'] as String? ?? 'Unknown Driver';
      final rating = vehicle['rating']?.toString() ?? '0.0';
      final status = vehicle['status'] as String? ?? 'unknown';
      final colorHex = vehicle['color'] as String;
      final color = _parseHexColor(colorHex);
      final location = vehicleLocations[vehicleId];
      final route = vehicleRoutes[vehicleId] ?? <LatLng>[];
      
      if (location != null) {
        // Create enhanced vehicle marker with service information
        newMarkers.add(
          Marker(
            markerId: MarkerId(vehicleId),
            position: LatLng(location.latitude, location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(_getHueForService(vehicleService, color)),
            infoWindow: InfoWindow(
              title: '$vehicleService - $vehicleName',
              snippet: 'Driver: $driverName\n'
                      'Model: $vehicleModel\n'
                      'Speed: ${(location.speed ?? 0.0).toStringAsFixed(1)} km/h\n'
                      'Rating: ⭐$rating | Status: ${status.toUpperCase()}\n'
                      'Updated: ${location.timestamp.toString().substring(11, 19)}',
            ),
            onTap: () => selectVehicle(vehicleId),
            rotation: location.heading ?? 0.0,
          ),
        );
        
        // Create service-specific route polyline with different styles
        if (route.length > 1) {
          newPolylines.add(
            Polyline(
              polylineId: PolylineId('route_$vehicleId'),
              points: route,
              color: _getRouteColor(vehicleService, color),
              width: _getRouteWidth(vehicleService),
              patterns: _getRoutePattern(vehicleService, selectedVehicleId.value == vehicleId),
            ),
          );
        }
      }
    }
    
    markers.clear();
    markers.addAll(newMarkers);
    polylines.clear();
    polylines.addAll(newPolylines);
  }

  /// Get hue value for marker color based on service
  double _getHueForService(String service, Color fallbackColor) {
    switch (service.toLowerCase()) {
      case 'ola':
        return BitmapDescriptor.hueGreen;
      case 'uber':
        return BitmapDescriptor.hueAzure;
      case 'gsrtc':
        return BitmapDescriptor.hueBlue;
      case 'zomato':
        return BitmapDescriptor.hueRed;
      case 'swiggy':
        return BitmapDescriptor.hueOrange;
      case 'emergency':
        return BitmapDescriptor.hueRose;
      case 'corporate':
        return BitmapDescriptor.hueViolet;
      case 'local':
        return BitmapDescriptor.hueYellow;
      default:
        return _getHue(fallbackColor);
    }
  }

  /// Get route color based on service
  Color _getRouteColor(String service, Color fallbackColor) {
    switch (service.toLowerCase()) {
      case 'ola':
        return Colors.green.withOpacity(0.8);
      case 'uber':
        return Colors.black.withOpacity(0.8);
      case 'gsrtc':
        return Colors.blue.withOpacity(0.8);
      case 'zomato':
        return Colors.red.withOpacity(0.8);
      case 'swiggy':
        return Colors.orange.withOpacity(0.8);
      case 'emergency':
        return Colors.red.withOpacity(0.9);
      case 'corporate':
        return Colors.purple.withOpacity(0.8);
      default:
        return fallbackColor.withOpacity(0.8);
    }
  }

  /// Get route width based on service priority
  int _getRouteWidth(String service) {
    switch (service.toLowerCase()) {
      case 'emergency':
        return 5; // Thicker for emergency vehicles
      case 'gsrtc':
      case 'corporate':
        return 4; // Thick for public/corporate transport
      case 'ola':
      case 'uber':
        return 3; // Standard for ride-sharing
      default:
        return 2; // Thin for delivery/local services
    }
  }

  /// Get route pattern based on service and selection
  List<PatternItem> _getRoutePattern(String service, bool isSelected) {
    if (isSelected) {
      return []; // Solid line for selected vehicle
    }
    
    switch (service.toLowerCase()) {
      case 'emergency':
        return [PatternItem.dash(20), PatternItem.gap(10)]; // Emergency pattern
      case 'zomato':
      case 'swiggy':
        return [PatternItem.dot, PatternItem.gap(5)]; // Dotted for delivery
      default:
        return [PatternItem.dash(10), PatternItem.gap(5)]; // Standard dash
    }
  }

  /// Get hue value for marker color
  double _getHue(Color color) {
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    return BitmapDescriptor.hueRed;
  }

  /// Select a vehicle for tracking
  void selectVehicle(String vehicleId) {
    selectedVehicleId.value = vehicleId;
    Get.snackbar(
      'Vehicle Selected', 
      'Now tracking: $vehicleId',
      duration: const Duration(seconds: 2),
    );
  }

  /// Toggle follow vehicle mode
  void toggleFollowVehicle() {
    followVehicle.value = !followVehicle.value;
  }

  /// Change map type
  void changeMapType(MapType newType) {
    mapType.value = newType;
  }

  /// Set map controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    isMapReady.value = true;
    debugPrint('Map controller ready for vehicle tracking');
  }

  /// Animate to a specific location
  Future<void> _animateToLocation(LatLng location) async {
    try {
      if (_mapController != null && isMapReady.value) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(location),
        );
      }
    } catch (e) {
      debugPrint('Error animating to location: $e');
    }
  }

  /// Get vehicle statistics with service breakdown
  Map<String, dynamic> getVehicleStats() {
    final activeVehicles = vehicleLocations.length;
    final totalDistance = vehicleRoutes.values
        .map((route) => route.length * 0.1) // Rough distance estimate
        .fold(0.0, (a, b) => a + b);
    
    double avgSpeed = 0.0;
    if (vehicleLocations.isNotEmpty) {
      avgSpeed = vehicleLocations.values
          .map((loc) => loc.speed ?? 0.0)
          .fold(0.0, (a, b) => a + b) / vehicleLocations.length;
    }
    
    // Service breakdown
    final serviceBreakdown = <String, Map<String, dynamic>>{};
    for (var vehicle in _mockVehicles) {
      final service = vehicle['service'] as String? ?? 'Unknown';
      final vehicleId = vehicle['id'] as String;
      final location = vehicleLocations[vehicleId];
      final isActive = location != null && (location.speed ?? 0.0) > 5.0;
      
      if (!serviceBreakdown.containsKey(service)) {
        serviceBreakdown[service] = {
          'total': 0,
          'active': 0,
          'avgSpeed': 0.0,
          'vehicles': <String>[],
        };
      }
      
      serviceBreakdown[service]!['total'] = 
          (serviceBreakdown[service]!['total'] as int) + 1;
      
      if (isActive) {
        serviceBreakdown[service]!['active'] = 
            (serviceBreakdown[service]!['active'] as int) + 1;
      }
      
      if (location != null) {
        final currentAvg = serviceBreakdown[service]!['avgSpeed'] as double;
        final currentCount = (serviceBreakdown[service]!['vehicles'] as List).length;
        serviceBreakdown[service]!['avgSpeed'] = 
            (currentAvg * currentCount + (location.speed ?? 0.0)) / (currentCount + 1);
        (serviceBreakdown[service]!['vehicles'] as List).add(vehicleId);
      }
    }
    
    return {
      'activeVehicles': activeVehicles,
      'totalVehicles': _mockVehicles.length,
      'totalDistance': totalDistance,
      'averageSpeed': avgSpeed,
      'serviceBreakdown': serviceBreakdown,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get vehicle list for UI with enhanced information
  List<Map<String, dynamic>> getVehicleList() {
    return _mockVehicles.map((vehicle) {
      final vehicleId = vehicle['id'] as String;
      final location = vehicleLocations[vehicleId];
      final route = vehicleRoutes[vehicleId] ?? <LatLng>[];
      
      return {
        ...vehicle,
        'isActive': location != null && (location.speed ?? 0.0) > 5.0,
        'isOnline': location != null,
        'lastLocation': location,
        'isSelected': selectedVehicleId.value == vehicleId,
        'color': _parseHexColor(vehicle['color'] as String),
        'routeLength': route.length,
        'distanceTraveled': route.length * 0.1, // Rough estimate in km
        'currentSpeed': location?.speed ?? 0.0,
        'lastUpdateTime': location?.timestamp,
        'statusIcon': _getStatusIcon(vehicle['service'] as String? ?? 'Unknown'),
      };
    }).toList();
  }

  /// Get vehicles grouped by service
  Map<String, List<Map<String, dynamic>>> getVehiclesByService() {
    final vehiclesByService = <String, List<Map<String, dynamic>>>{};
    
    for (var vehicleData in getVehicleList()) {
      final service = vehicleData['service'] as String? ?? 'Unknown';
      
      if (!vehiclesByService.containsKey(service)) {
        vehiclesByService[service] = [];
      }
      
      vehiclesByService[service]!.add(vehicleData);
    }
    
    return vehiclesByService;
  }

  /// Get status icon for service
  String _getStatusIcon(String service) {
    switch (service.toLowerCase()) {
      case 'ola':
        return '🚕';
      case 'uber':
        return '🚗';
      case 'gsrtc':
        return '🚌';
      case 'zomato':
        return '🍕';
      case 'swiggy':
        return '🛵';
      case 'emergency':
        return '🚑';
      case 'corporate':
        return '🚐';
      case 'local':
        return '🛺';
      default:
        return '🚙';
    }
  }

  /// Parse hex color string to Color object
  Color _parseHexColor(String hexColor) {
    // Remove # if present
    hexColor = hexColor.replaceAll('#', '');
    
    // Add alpha if not present
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Reset all vehicles to their starting positions
  void resetVehiclePositions() {
    for (var vehicle in _mockVehicles) {
      final vehicleId = vehicle['id'] as String;
      _vehicleWaypointIndex[vehicleId] = 0;
      vehicleRoutes[vehicleId] = <LatLng>[];
    }
    vehicleLocations.clear();
    Get.snackbar('Reset', 'All vehicles reset to starting positions');
  }

  /// Get real-time vehicle count by status
  Map<String, int> getVehicleStatusCount() {
    int active = 0;
    int idle = 0;
    
    for (final location in vehicleLocations.values) {
      if ((location.speed ?? 0.0) > 5.0) {
        active++;
      } else {
        idle++;
      }
    }
    
    return {
      'active': active,
      'idle': idle,
      'total': vehicleLocations.length,
    };
  }

  /// Generate enhanced statistics for PDF report
  Map<String, dynamic> getEnhancedVehicleStats() {
    final stats = getVehicleStats();
    final vehicleList = getVehicleList();
    
    // Calculate additional metrics
    final availableVehicles = vehicleList.where((v) => 
        v['status'] == 'available' || v['status'] == 'standby').length;
    final totalTrips = vehicleList.fold<int>(0, (sum, v) => 
        sum + (v['totalTrips'] as int? ?? 0));
    final averageRating = vehicleList.fold<double>(0, (sum, v) => 
        sum + (v['rating'] as double? ?? 0.0)) / vehicleList.length;
    final averageFuelLevel = vehicleList.fold<double>(0, (sum, v) => 
        sum + (v['fuelLevel'] as double? ?? 0.0)) / vehicleList.length;

    return {
      ...stats,
      'availableVehicles': availableVehicles,
      'totalTrips': totalTrips,
      'averageRating': averageRating,
      'averageFuelLevel': averageFuelLevel,
      'generatedAt': DateTime.now(),
      'reportType': 'Fleet Status Report',
      'location': 'Vadodara, Gujarat',
    };
  }

  /// Generate and save PDF report
  Future<String?> generateFleetPDFReport() async {
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      final vehicles = getVehicleList();
      final statistics = getEnhancedVehicleStats();
      
      debugPrint('Generating PDF for ${vehicles.length} vehicles...');
      
      final filePath = await PDFReportService.generateAndSaveFleetReport(
        vehicles,
        statistics,
      );
      
      Get.back(); // Close loading dialog
      
      if (kIsWeb) {
        Get.snackbar(
          'Success',
          'PDF report downloaded successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Success',
          'PDF report saved successfully!\nLocation: $filePath',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      
      return filePath;
    } catch (e) {
      Get.back(); // Close loading dialog
      debugPrint('PDF generation error: $e');
      Get.snackbar(
        'Error',
        'Failed to generate PDF report: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Print fleet report
  Future<void> printFleetReport() async {
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      final vehicles = getVehicleList();
      final statistics = getEnhancedVehicleStats();
      
      await PDFReportService.printReport(vehicles, statistics);
      
      Get.back(); // Close loading dialog
      
      Get.snackbar(
        'Print Ready',
        'Print dialog opened successfully!',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to print report: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Share fleet report
  Future<void> shareFleetReport() async {
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      final vehicles = getVehicleList();
      final statistics = getEnhancedVehicleStats();
      
      await PDFReportService.shareReport(vehicles, statistics);
      
      Get.back(); // Close loading dialog
      
      Get.snackbar(
        'Share Ready',
        'Share dialog opened successfully!',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to share report: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // PATHFINDING & ROUTE PLANNING METHODS

  /// Calculate routes using different algorithms (DFS, BFS, A*)
  Future<void> calculateRoutes(String startNode, String endNode) async {
    try {
      calculatedRoutes.clear();
      
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Find routes using all algorithms
      final routes = PathfindingService.findMultipleRoutes(startNode, endNode);
      
      calculatedRoutes.addAll(routes);
      showAlgorithmRoutes.value = true;
      
      // Update map with algorithm routes
      _updateAlgorithmRoutes();
      
      Get.back(); // Close loading dialog
      
      if (routes.isNotEmpty) {
        Get.snackbar(
          'Routes Calculated',
          'Found ${routes.length} routes using DFS, BFS & A* algorithms',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'No Routes Found',
          'Unable to find routes between selected locations',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Calculation Error',
        'Failed to calculate routes: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Update map polylines with algorithm routes
  void _updateAlgorithmRoutes() {
    // First clear any existing algorithm routes
    polylines.removeWhere((polyline) => 
      polyline.polylineId.value.startsWith('algorithm_'));
    
    if (!showAlgorithmRoutes.value) return;

    final algorithmPolylines = <Polyline>{};
    
    for (final route in calculatedRoutes) {
      algorithmPolylines.add(
        Polyline(
          polylineId: PolylineId('algorithm_${route.algorithm}'),
          points: route.coordinates,
          color: route.color,
          width: 6, // Thicker lines for better visibility
          patterns: route.algorithm == 'DFS' 
            ? [PatternItem.dash(20), PatternItem.gap(15)]
            : route.algorithm == 'BFS'
              ? [PatternItem.dot, PatternItem.gap(12)]
              : [], // Solid for A*
        ),
      );
    }

    // Add algorithm routes to existing polylines
    polylines.addAll(algorithmPolylines);
  }

  /// Toggle algorithm routes visibility
  void toggleAlgorithmRoutes() {
    showAlgorithmRoutes.value = !showAlgorithmRoutes.value;
    if (showAlgorithmRoutes.value) {
      _updateAlgorithmRoutes();
    } else {
      // Remove algorithm routes
      polylines.removeWhere((polyline) => 
        polyline.polylineId.value.startsWith('algorithm_'));
    }
  }

  /// Generate random route for demonstration
  void generateRandomAlgorithmDemo() {
    // First clear any existing algorithm routes to avoid mess
    clearAlgorithmRoutes();
    
    final route = PathfindingService.generateRandomRoute();
    final startNode = route.path.first;
    final endNode = route.path.last;
    
    // Temporarily hide vehicle routes for cleaner demo
    _hideVehicleRoutes();
    
    calculateRoutes(startNode, endNode);
    
    Get.snackbar(
      'Algorithm Demo',
      'Comparing DFS vs BFS vs A*: ${_formatNodeName(startNode)} → ${_formatNodeName(endNode)}',
      backgroundColor: Colors.purple,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Generate predefined route demo (Railway Station to Parul University)
  void generatePredefinedRouteDemo(String routeName) {
    // First clear any existing algorithm routes to avoid mess
    clearAlgorithmRoutes();
    
    // Temporarily hide vehicle routes for cleaner demo
    _hideVehicleRoutes();
    
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Calculate predefined route
      final routes = PathfindingService.calculatePredefinedRoute(routeName);
      
      calculatedRoutes.addAll(routes);
      showAlgorithmRoutes.value = true;
      
      // Update map with algorithm routes
      _updateAlgorithmRoutes();
      
      Get.back(); // Close loading dialog
      
      if (routes.isNotEmpty) {
        Get.snackbar(
          'Predefined Route Demo',
          '$routeName\nFound ${routes.length} routes using DFS, BFS & A*',
          backgroundColor: Colors.purple,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'No Routes Found',
          'Unable to find routes for $routeName',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Calculation Error',
        'Failed to calculate routes: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Get predefined routes for UI
  List<Map<String, String>> getPredefinedRoutes() {
    return PathfindingService.getPredefinedRoutes();
  }

  /// Hide vehicle routes temporarily
  void _hideVehicleRoutes() {
    polylines.removeWhere((polyline) => 
      !polyline.polylineId.value.startsWith('algorithm_'));
  }

  /// Restore vehicle routes
  void _restoreVehicleRoutes() {
    _updateMarkersAndPolylines();
  }

  /// Format node name for display
  String _formatNodeName(String nodeName) {
    return nodeName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Clear all algorithm routes
  void clearAlgorithmRoutes() {
    calculatedRoutes.clear();
    showAlgorithmRoutes.value = false;
    polylines.removeWhere((polyline) => 
      polyline.polylineId.value.startsWith('algorithm_'));
    
    // Restore vehicle routes when clearing algorithm routes
    _restoreVehicleRoutes();
    
    Get.snackbar(
      'Routes Cleared',
      'Algorithm routes cleared, vehicle tracking restored',
      backgroundColor: Colors.grey,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Reset map to show only vehicle tracking
  void resetToVehicleTracking() {
    clearAlgorithmRoutes();
    showAlgorithmRoutes.value = false;
    _restoreVehicleRoutes();
  }
}
