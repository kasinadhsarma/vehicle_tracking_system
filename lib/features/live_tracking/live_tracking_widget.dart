import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'live_map_controller.dart';

/// Advanced live tracking widget with real-time vehicle monitoring
class LiveTrackingWidget extends StatelessWidget {
  final String? selectedVehicleId;
  final VoidCallback? onVehicleSelected;
  final bool showControls;
  final bool showStats;

  const LiveTrackingWidget({
    super.key,
    this.selectedVehicleId,
    this.onVehicleSelected,
    this.showControls = true,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LiveMapController());

    return Scaffold(
      body: Column(
        children: [
          if (showStats) _buildStatsHeader(controller),
          Expanded(
            child: Stack(
              children: [
                _buildMap(controller),
                if (showControls) _buildMapControls(controller, context),
                _buildVehicleSelector(controller, context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActions(controller),
    );
  }

  /// Build statistics header
  Widget _buildStatsHeader(LiveMapController controller) {
    return Obx(() {
      final stats = controller.getVehicleStats();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard(
              'Active Vehicles',
              '${stats['activeVehicles']}',
              Icons.directions_car,
              Colors.blue,
            ),
            _buildStatCard(
              'Avg Speed',
              '${stats['averageSpeed'].toStringAsFixed(1)} km/h',
              Icons.speed,
              Colors.green,
            ),
            _buildStatCard(
              'Distance',
              '${stats['totalDistance'].toStringAsFixed(1)} km',
              Icons.route,
              Colors.orange,
            ),
            _buildStatCard(
              'Status',
              controller.isTracking.value ? 'Live' : 'Offline',
              controller.isTracking.value ? Icons.location_on : Icons.location_off,
              controller.isTracking.value ? Colors.green : Colors.red,
            ),
            Obx(() => _buildAlgorithmIndicator(controller)),
          ],
        ),
      );
    });
  }

  /// Build individual stat card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Get.textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Build algorithm indicator
  Widget _buildAlgorithmIndicator(LiveMapController controller) {
    if (controller.calculatedRoutes.isEmpty) {
      return GestureDetector(
        onTap: () => _showRouteSelectionMenu(controller),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route, color: Colors.purple, size: 24),
            const SizedBox(height: 4),
            Text(
              'Routes',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            Text(
              'DFS/BFS/A*',
              style: Get.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showAlgorithmMenu(controller),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            controller.showAlgorithmRoutes.value ? Icons.visibility : Icons.visibility_off,
            color: Colors.purple,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.calculatedRoutes.length}',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          Text(
            'Routes',
            style: Get.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Show route selection menu
  void _showRouteSelectionMenu(LiveMapController controller) {
    final predefinedRoutes = controller.getPredefinedRoutes();
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Colors.purple, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Select Route Demo',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Choose a predefined route to compare DFS, BFS & A* algorithms:',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ...predefinedRoutes.map((route) => _buildRouteOption(
              name: route['name']!,
              description: route['description']!,
              category: route['category']!,
              onTap: () {
                Get.back();
                controller.generatePredefinedRouteDemo(route['name']!);
              },
            )),
            const SizedBox(height: 16),
            _buildRouteOption(
              name: 'Random Route',
              description: 'Generate a random route between any two points',
              category: 'random',
              onTap: () {
                Get.back();
                controller.generateRandomAlgorithmDemo();
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build route option tile
  Widget _buildRouteOption({
    required String name,
    required String description,
    required String category,
    required VoidCallback onTap,
  }) {
    Color categoryColor;
    IconData categoryIcon;
    
    switch (category) {
      case 'educational':
        categoryColor = Colors.blue;
        categoryIcon = Icons.school;
        break;
      case 'commercial':
        categoryColor = Colors.green;
        categoryIcon = Icons.business;
        break;
      case 'residential':
        categoryColor = Colors.orange;
        categoryIcon = Icons.home;
        break;
      case 'mixed':
        categoryColor = Colors.purple;
        categoryIcon = Icons.location_city;
        break;
      case 'cross_city':
        categoryColor = Colors.indigo;
        categoryIcon = Icons.swap_horiz;
        break;
      case 'random':
        categoryColor = Colors.grey;
        categoryIcon = Icons.shuffle;
        break;
      default:
        categoryColor = Colors.grey;
        categoryIcon = Icons.route;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(categoryIcon, color: categoryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  /// Show algorithm menu
  void _showAlgorithmMenu(LiveMapController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Colors.purple, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Route Algorithms',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAlgorithmOption(
              icon: Icons.toggle_on,
              title: controller.showAlgorithmRoutes.value ? 'Hide Routes' : 'Show Routes',
              subtitle: 'Toggle algorithm route visibility',
              color: Colors.blue,
              onTap: () {
                Get.back();
                controller.toggleAlgorithmRoutes();
              },
            ),
            const SizedBox(height: 12),
            _buildAlgorithmOption(
              icon: Icons.refresh,
              title: 'New Demo',
              subtitle: 'Generate new random route comparison',
              color: Colors.green,
              onTap: () {
                Get.back();
                controller.generateRandomAlgorithmDemo();
              },
            ),
            const SizedBox(height: 12),
            _buildAlgorithmOption(
              icon: Icons.clear,
              title: 'Clear Routes',
              subtitle: 'Clear all routes and return to vehicle tracking',
              color: Colors.red,
              onTap: () {
                Get.back();
                controller.clearAlgorithmRoutes();
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build algorithm option tile
  Widget _buildAlgorithmOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  /// Build Google Maps widget
  /// Build map widget with fallback for web
  Widget _buildMap(LiveMapController controller) {
    return Obx(() {
      // Now that we have a valid API key, always use Google Maps
      return GoogleMap(
        onMapCreated: controller.setMapController,
        initialCameraPosition: CameraPosition(
          target: controller.center.value,
          zoom: controller.zoom.value,
        ),
        mapType: controller.mapType.value,
        markers: controller.markers,
        polylines: controller.polylines,
        polygons: controller.geofences,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: true,
        trafficEnabled: true,
        buildingsEnabled: true,
        onTap: (LatLng position) {
          // Handle map tap
          debugPrint('Map tapped at: ${position.latitude}, ${position.longitude}');
        },
      );
    });
  }

  /// Build map control buttons
  Widget _buildMapControls(LiveMapController controller, BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.layers,
            onPressed: () => _showMapTypeSelector(controller, context),
            tooltip: 'Map Type',
          ),
          const SizedBox(height: 8),
          Obx(() => _buildControlButton(
            icon: controller.followVehicle.value ? Icons.my_location : Icons.location_disabled,
            onPressed: controller.toggleFollowVehicle,
            tooltip: 'Follow Vehicle',
            isActive: controller.followVehicle.value,
          )),
          const SizedBox(height: 8),
          Obx(() => _buildControlButton(
            icon: controller.isTracking.value ? Icons.pause : Icons.play_arrow,
            onPressed: () {
              if (controller.isTracking.value) {
                controller.stopTracking();
              } else {
                controller.startLiveTracking();
              }
            },
            tooltip: controller.isTracking.value ? 'Pause Tracking' : 'Start Tracking',
            isActive: controller.isTracking.value,
          )),
        ],
      ),
    );
  }

  /// Build control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Get.theme.primaryColor : Get.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? Colors.white : Get.theme.colorScheme.onSurface,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  /// Build vehicle selector panel
  Widget _buildVehicleSelector(LiveMapController controller, BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Fleet Vehicles',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final vehicles = controller.getVehicleList();
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return _buildVehicleCard(controller, vehicle);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual vehicle card
  Widget _buildVehicleCard(LiveMapController controller, Map<String, dynamic> vehicle) {
    final isSelected = vehicle['isSelected'] as bool;
    final isActive = vehicle['isActive'] as bool;
    final color = vehicle['color'] as Color;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8, bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
        border: Border.all(
          color: isSelected ? color : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => controller.selectVehicle(vehicle['id']),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_car,
                color: isActive ? color : Colors.grey,
                size: 18,
              ),
              const SizedBox(height: 1),
              Text(
                vehicle['id'],
                style: Get.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : null,
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                isActive ? 'Active' : 'Offline',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: isActive ? Colors.green : Colors.red,
                  fontSize: 7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build floating action buttons
  Widget _buildFloatingActions(LiveMapController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Clear Algorithm Routes Button
        Obx(() => controller.calculatedRoutes.isNotEmpty 
          ? FloatingActionButton(
              mini: true,
              heroTag: 'clear_routes',
              backgroundColor: Colors.red.shade400,
              onPressed: () => controller.clearAlgorithmRoutes(),
              child: const Icon(Icons.clear, color: Colors.white),
            )
          : const SizedBox.shrink()),
        Obx(() => controller.calculatedRoutes.isNotEmpty 
          ? const SizedBox(height: 8) 
          : const SizedBox.shrink()),
        // DFS/BFS/A* Algorithm Demo Button
        FloatingActionButton(
          mini: true,
          heroTag: 'algorithm_demo',
          backgroundColor: Colors.purple,
          onPressed: () => _showRouteSelectionMenu(controller),
          child: const Icon(Icons.route, color: Colors.white),
        ),
        const SizedBox(height: 8),
        // PDF Report Generation Button
        FloatingActionButton(
          mini: true,
          heroTag: 'pdf_report',
          backgroundColor: Colors.orange,
          onPressed: () => _showReportOptions(controller),
          child: const Icon(Icons.picture_as_pdf, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'zoom_in',
          onPressed: () {
            controller.mapController?.animateCamera(
              CameraUpdate.zoomIn(),
            );
          },
          child: const Icon(Icons.zoom_in),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'zoom_out',
          onPressed: () {
            controller.mapController?.animateCamera(
              CameraUpdate.zoomOut(),
            );
          },
          child: const Icon(Icons.zoom_out),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'center_map',
          onPressed: () {
            // Center map on all vehicles
            final vehicles = controller.getVehicleList();
            if (vehicles.isNotEmpty) {
              final bounds = _calculateBounds(vehicles);
              controller.mapController?.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 100),
              );
            }
          },
          child: const Icon(Icons.center_focus_strong),
        ),
      ],
    );
  }

  /// Show PDF report options
  void _showReportOptions(LiveMapController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Fleet Report Options',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildReportOption(
              icon: Icons.download,
              title: 'Generate & Save PDF',
              subtitle: 'Save detailed fleet report to device',
              color: Colors.green,
              onTap: () {
                Get.back();
                controller.generateFleetPDFReport();
              },
            ),
            const SizedBox(height: 12),
            _buildReportOption(
              icon: Icons.print,
              title: 'Print Report',
              subtitle: 'Print fleet status report',
              color: Colors.blue,
              onTap: () {
                Get.back();
                controller.printFleetReport();
              },
            ),
            const SizedBox(height: 12),
            _buildReportOption(
              icon: Icons.share,
              title: 'Share Report',
              subtitle: 'Share PDF via messaging or email',
              color: Colors.orange,
              onTap: () {
                Get.back();
                controller.shareFleetReport();
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build report option tile
  Widget _buildReportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  /// Calculate bounds for all vehicles
  LatLngBounds _calculateBounds(List<Map<String, dynamic>> vehicles) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final vehicle in vehicles) {
      final location = vehicle['lastLocation'];
      if (location != null) {
        final lat = location.latitude;
        final lng = location.longitude;
        
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Show map type selector
  void _showMapTypeSelector(LiveMapController controller, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map Type',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...MapType.values.map((type) => ListTile(
              leading: Icon(_getMapTypeIcon(type)),
              title: Text(_getMapTypeName(type)),
              onTap: () {
                controller.changeMapType(type);
                Navigator.pop(context);
              },
              trailing: Obx(() => Radio<MapType>(
                value: type,
                groupValue: controller.mapType.value,
                onChanged: (MapType? value) {
                  if (value != null) {
                    controller.changeMapType(value);
                    Navigator.pop(context);
                  }
                },
              )),
            )),
          ],
        ),
      ),
    );
  }

  /// Get map type icon
  IconData _getMapTypeIcon(MapType type) {
    switch (type) {
      case MapType.normal:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.terrain:
        return Icons.terrain;
      case MapType.hybrid:
        return Icons.layers;
      default:
        return Icons.map;
    }
  }

  /// Get map type name
  String _getMapTypeName(MapType type) {
    switch (type) {
      case MapType.normal:
        return 'Normal';
      case MapType.satellite:
        return 'Satellite';
      case MapType.terrain:
        return 'Terrain';
      case MapType.hybrid:
        return 'Hybrid';
      default:
        return 'Normal';
    }
  }
}
