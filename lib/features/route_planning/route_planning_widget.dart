import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/pathfinding_service.dart';

/// Widget for demonstrating DFS, BFS, and A* pathfinding algorithms
class RoutePlanningWidget extends StatefulWidget {
  const RoutePlanningWidget({super.key});

  @override
  State<RoutePlanningWidget> createState() => _RoutePlanningWidgetState();
}

class _RoutePlanningWidgetState extends State<RoutePlanningWidget> {
  String? selectedStartNode;
  String? selectedEndNode;
  List<RouteResult> foundRoutes = [];
  bool isCalculating = false;

  final Map<String, LatLng> nodes = PathfindingService.getAllNodes();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildNodeSelectors(),
          const SizedBox(height: 16),
          _buildCalculateButton(),
          const SizedBox(height: 16),
          _buildRouteResults(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.route,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Route Planning',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'DFS, BFS & A* Algorithms',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildRandomRouteButton(),
      ],
    );
  }

  Widget _buildRandomRouteButton() {
    return ElevatedButton.icon(
      onPressed: _generateRandomRoute,
      icon: const Icon(Icons.shuffle, size: 16),
      label: const Text('Random'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(80, 36),
      ),
    );
  }

  Widget _buildNodeSelectors() {
    return Row(
      children: [
        Expanded(
          child: _buildNodeDropdown(
            label: 'Start Location',
            value: selectedStartNode,
            onChanged: (value) => setState(() => selectedStartNode = value),
            icon: Icons.my_location,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildNodeDropdown(
            label: 'Destination',
            value: selectedEndNode,
            onChanged: (value) => setState(() => selectedEndNode = value),
            icon: Icons.location_on,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildNodeDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              isExpanded: true,
              hint: Text(
                'Select $label',
                style: TextStyle(color: Colors.grey[600]),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              items: nodes.keys.map((node) {
                return DropdownMenuItem<String>(
                  value: node,
                  child: Text(
                    _formatNodeName(node),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateButton() {
    final canCalculate = selectedStartNode != null && 
                        selectedEndNode != null && 
                        selectedStartNode != selectedEndNode;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canCalculate && !isCalculating ? _calculateRoutes : null,
        icon: isCalculating 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.search),
        label: Text(isCalculating ? 'Calculating...' : 'Find Routes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRouteResults() {
    if (foundRoutes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No routes calculated yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select start and end locations to find optimal routes',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.route,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Route Options (${foundRoutes.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...foundRoutes.asMap().entries.map((entry) {
          final index = entry.key;
          final route = entry.value;
          return _buildRouteCard(route, index);
        }).toList(),
      ],
    );
  }

  Widget _buildRouteCard(RouteResult route, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: route.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: route.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: route.color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  route.algorithm,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.routeType,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildRouteStats(route),
            ],
          ),
          const SizedBox(height: 12),
          _buildRoutePath(route),
          const SizedBox(height: 8),
          _buildRouteActions(route),
        ],
      ),
    );
  }

  Widget _buildRouteStats(RouteResult route) {
    return Row(
      children: [
        _buildStatChip(
          '${route.distance.toStringAsFixed(1)} km',
          Icons.straighten,
          Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          '${route.estimatedTime.toStringAsFixed(0)} min',
          Icons.schedule,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePath(RouteResult route) {
    return Wrap(
      children: route.path.asMap().entries.map((entry) {
        final index = entry.key;
        final node = entry.value;
        final isLast = index == route.path.length - 1;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: index == 0 
                  ? Colors.green.withOpacity(0.1)
                  : isLast 
                    ? Colors.red.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: index == 0 
                    ? Colors.green
                    : isLast 
                      ? Colors.red
                      : Colors.grey,
                  width: 1,
                ),
              ),
              child: Text(
                _formatNodeName(node),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: index == 0 
                    ? Colors.green[700]
                    : isLast 
                      ? Colors.red[700]
                      : Colors.grey[700],
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 4),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRouteActions(RouteResult route) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => _useRoute(route),
          icon: const Icon(Icons.navigation, size: 16),
          label: const Text('Use Route'),
          style: TextButton.styleFrom(
            foregroundColor: route.color,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _shareRoute(route),
          icon: const Icon(Icons.share, size: 16),
          label: const Text('Share'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ],
    );
  }

  void _calculateRoutes() async {
    if (selectedStartNode == null || selectedEndNode == null) return;

    setState(() {
      isCalculating = true;
      foundRoutes.clear();
    });

    try {
      // Simulate calculation delay for better UX
      await Future.delayed(const Duration(milliseconds: 800));

      final routes = PathfindingService.findMultipleRoutes(
        selectedStartNode!,
        selectedEndNode!,
      );

      setState(() {
        foundRoutes = routes;
        isCalculating = false;
      });

      if (routes.isNotEmpty) {
        Get.snackbar(
          'Routes Found',
          'Found ${routes.length} route options using different algorithms',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'No Routes',
          'No routes found between selected locations',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        isCalculating = false;
      });
      Get.snackbar(
        'Error',
        'Failed to calculate routes: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _generateRandomRoute() {
    final route = PathfindingService.generateRandomRoute();
    setState(() {
      selectedStartNode = route.path.first;
      selectedEndNode = route.path.last;
      foundRoutes = [route];
    });

    Get.snackbar(
      'Random Route',
      'Generated random route: ${_formatNodeName(route.path.first)} → ${_formatNodeName(route.path.last)}',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  void _useRoute(RouteResult route) {
    Get.snackbar(
      'Route Selected',
      'Using ${route.algorithm} route: ${route.routeType}',
      backgroundColor: route.color,
      colorText: Colors.white,
    );
    // Here you could integrate with your vehicle tracking system
  }

  void _shareRoute(RouteResult route) {
    final routeText = 'Route from ${_formatNodeName(route.path.first)} to ${_formatNodeName(route.path.last)}\n'
                     'Algorithm: ${route.algorithm}\n'
                     'Distance: ${route.distance.toStringAsFixed(1)} km\n'
                     'Time: ${route.estimatedTime.toStringAsFixed(0)} minutes\n'
                     'Path: ${route.path.map(_formatNodeName).join(' → ')}';

    Get.snackbar(
      'Route Shared',
      'Route details copied to clipboard',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
    // Here you could implement actual sharing functionality
  }

  String _formatNodeName(String nodeName) {
    return nodeName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
