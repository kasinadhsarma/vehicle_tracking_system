import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/directions_service.dart';

class RoutePlanningPanel extends StatefulWidget {
  final Function(List<LatLng>) onRouteSelected;
  final LatLng? currentLocation;
  
  const RoutePlanningPanel({
    super.key,
    required this.onRouteSelected,
    this.currentLocation,
  });

  @override
  State<RoutePlanningPanel> createState() => _RoutePlanningPanelState();
}

class _RoutePlanningPanelState extends State<RoutePlanningPanel> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  List<RouteOption> _routeOptions = [];
  RouteOption? _selectedRoute;
  bool _isLoading = false;
  String _travelMode = 'driving';

  // Popular Vadodara locations
  final List<VadodaraLocation> _popularLocations = [
    VadodaraLocation('Vadodara Railway Station', 22.3072, 73.1812),
    VadodaraLocation('MS University', 22.3089, 73.1750),
    VadodaraLocation('Sayajigunj', 22.3056, 73.1903),
    VadodaraLocation('Alkapuri', 22.2871, 73.2081),
    VadodaraLocation('Makarpura GIDC', 22.2644, 73.2089),
    VadodaraLocation('Vadodara Airport', 22.3361, 73.2264),
    VadodaraLocation('Inox Racecourse Circle', 22.2956, 73.1936),
    VadodaraLocation('Karelibaug', 22.3156, 73.1681),
    VadodaraLocation('Gotri', 22.3494, 73.1844),
    VadodaraLocation('Manjalpur', 22.2478, 73.1619),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      _fromController.text = 'Your Location';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchSection(),
          _buildTravelModeSelector(),
          if (_isLoading) _buildLoadingIndicator(),
          if (_routeOptions.isNotEmpty) _buildRouteOptions(),
          if (_selectedRoute != null) _buildDirectionsPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Text(
            'Route Planning',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearRoutes,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLocationInput(
            controller: _fromController,
            hint: 'Your location',
            icon: Icons.my_location,
            iconColor: Colors.green,
            onTap: () => _showLocationPicker(true),
          ),
          const SizedBox(height: 12),
          _buildLocationInput(
            controller: _toController,
            hint: 'Add destination',
            icon: Icons.location_on,
            iconColor: Colors.red,
            onTap: () => _showLocationPicker(false),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _searchRoutes,
              icon: const Icon(Icons.search),
              label: const Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
          ),
          onTap: onTap,
          readOnly: true,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.clear, size: 20),
          onPressed: () => controller.clear(),
        ),
      ),
    );
  }

  Widget _buildTravelModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildModeButton('driving', Icons.directions_car, 'Car'),
          _buildModeButton('walking', Icons.directions_walk, 'Walk'),
          _buildModeButton('bicycling', Icons.directions_bike, 'Bike'),
          _buildModeButton('transit', Icons.directions_transit, 'Transit'),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, IconData icon, String label) {
    final isSelected = _travelMode == mode;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _travelMode = mode;
            });
            if (_fromController.text.isNotEmpty && _toController.text.isNotEmpty) {
              _searchRoutes();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              Text(label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildRouteOptions() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _routeOptions.length,
        itemBuilder: (context, index) {
          final route = _routeOptions[index];
          final isSelected = _selectedRoute == route;
          
          return Card(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getRouteColor(index),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C...
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                route.summary,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(route.duration),
                      const SizedBox(width: 16),
                      Icon(Icons.straighten, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(route.distance),
                    ],
                  ),
                  if (route.trafficInfo.isNotEmpty)
                    Text(
                      route.trafficInfo,
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              onTap: () => _selectRoute(route),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDirectionsPanel() {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.navigation, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turn-by-turn directions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        '${_selectedRoute!.distance} • ${_selectedRoute!.duration}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareRoute(_selectedRoute!),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedRoute!.steps.length,
              itemBuilder: (context, index) {
                final step = _selectedRoute!.steps[index];
                return ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        _getStepIcon(step.maneuver),
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  title: Text(
                    step.instruction,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: step.distance.isNotEmpty
                      ? Text(
                          step.distance,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      : null,
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFrom ? 'Select Starting Point' : 'Select Destination',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isFrom && widget.currentLocation != null)
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: const Text('Your Current Location'),
                onTap: () {
                  _fromController.text = 'Your Location';
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            const Text('Popular Locations in Vadodara'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _popularLocations.length,
                itemBuilder: (context, index) {
                  final location = _popularLocations[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(location.name),
                    onTap: () {
                      if (isFrom) {
                        _fromController.text = location.name;
                      } else {
                        _toController.text = location.name;
                      }
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchRoutes() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both starting point and destination')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _routeOptions.clear();
      _selectedRoute = null;
    });

    try {
      // Simulate API call - replace with actual Google Directions API
      await Future.delayed(const Duration(seconds: 2));
      
      final mockRoutes = _generateMockRoutes();
      setState(() {
        _routeOptions = mockRoutes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting directions: $e')),
      );
    }
  }

  List<RouteOption> _generateMockRoutes() {
    // Generate mock routes for demo - replace with actual API data
    return [
      RouteOption(
        id: 'route1',
        summary: 'via NH75 and Chikkamagaluru - Sringeri Rd',
        distance: '6 hr 55 min',
        duration: '333 km',
        trafficInfo: 'Fastest route now due to traffic conditions',
        polylinePoints: _generateMockPolyline(),
        steps: _generateMockSteps(),
      ),
      RouteOption(
        id: 'route2',
        summary: 'via NH75 and Chikkamagaluru - Sringeri Rd',
        distance: '6 hr 57 min',
        duration: '328 km',
        trafficInfo: '',
        polylinePoints: _generateMockPolyline(),
        steps: _generateMockSteps(),
      ),
      RouteOption(
        id: 'route3',
        summary: 'via NH73 and Chikkamagaluru - Sringeri Rd',
        distance: '7 hr 18 min',
        duration: '329 km',
        trafficInfo: '',
        polylinePoints: _generateMockPolyline(),
        steps: _generateMockSteps(),
      ),
    ];
  }

  List<LatLng> _generateMockPolyline() {
    // Generate a mock polyline for demo
    final start = widget.currentLocation ?? const LatLng(22.3072, 73.1812);
    final end = _getDestinationCoordinates(_toController.text);
    
    return [
      start,
      LatLng((start.latitude + end.latitude) / 2, (start.longitude + end.longitude) / 2),
      end,
    ];
  }

  LatLng _getDestinationCoordinates(String destination) {
    final location = _popularLocations.firstWhere(
      (loc) => loc.name == destination,
      orElse: () => _popularLocations.first,
    );
    return LatLng(location.latitude, location.longitude);
  }

  List<DirectionStep> _generateMockSteps() {
    return [
      DirectionStep(
        instruction: 'Head north on Railway Station Rd toward Sardar Bridge',
        distance: '0.5 km',
        maneuver: 'straight',
      ),
      DirectionStep(
        instruction: 'Turn right onto Sardar Bridge',
        distance: '1.2 km',
        maneuver: 'turn-right',
      ),
      DirectionStep(
        instruction: 'Continue straight on RC Dutt Rd',
        distance: '2.1 km',
        maneuver: 'straight',
      ),
      DirectionStep(
        instruction: 'Turn left onto University Rd',
        distance: '0.8 km',
        maneuver: 'turn-left',
      ),
      DirectionStep(
        instruction: 'Arrive at your destination on the right',
        distance: '',
        maneuver: 'arrive',
      ),
    ];
  }

  void _selectRoute(RouteOption route) {
    setState(() {
      _selectedRoute = route;
    });
    widget.onRouteSelected(route.polylinePoints);
  }

  Color _getRouteColor(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    return colors[index % colors.length];
  }

  IconData _getStepIcon(String maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'straight':
        return Icons.straight;
      case 'arrive':
        return Icons.location_on;
      default:
        return Icons.navigation;
    }
  }

  void _shareRoute(RouteOption route) {
    // Implement route sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route shared successfully!')),
    );
  }

  void _clearRoutes() {
    setState(() {
      _fromController.clear();
      _toController.clear();
      _routeOptions.clear();
      _selectedRoute = null;
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
}

// Supporting classes
class VadodaraLocation {
  final String name;
  final double latitude;
  final double longitude;

  VadodaraLocation(this.name, this.latitude, this.longitude);
}

class RouteOption {
  final String id;
  final String summary;
  final String distance;
  final String duration;
  final String trafficInfo;
  final List<LatLng> polylinePoints;
  final List<DirectionStep> steps;

  RouteOption({
    required this.id,
    required this.summary,
    required this.distance,
    required this.duration,
    required this.trafficInfo,
    required this.polylinePoints,
    required this.steps,
  });
}

class DirectionStep {
  final String instruction;
  final String distance;
  final String maneuver;

  DirectionStep({
    required this.instruction,
    required this.distance,
    required this.maneuver,
  });
}
