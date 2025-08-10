import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/directions_service.dart';

/// Route planning widget with turn-by-turn directions
class RoutePlanningWidget extends StatefulWidget {
  final LatLng? origin;
  final LatLng? destination;
  final Function(DirectionsResult?)? onRouteCalculated;
  final Function(String)? onLocationSearch;

  const RoutePlanningWidget({
    super.key,
    this.origin,
    this.destination,
    this.onRouteCalculated,
    this.onLocationSearch,
  });

  @override
  State<RoutePlanningWidget> createState() => _RoutePlanningWidgetState();
}

class _RoutePlanningWidgetState extends State<RoutePlanningWidget> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final DirectionsService _directionsService = DirectionsService.instance;

  DirectionsResult? _currentRoute;
  bool _isLoading = false;
  String _travelMode = 'driving';
  bool _avoidTolls = false;
  bool _avoidHighways = false;

  @override
  void initState() {
    super.initState();
    if (widget.origin != null) {
      _originController.text = 'Current Location';
    }
    if (widget.destination != null) {
      _destinationController.text = 'Selected Destination';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Route planning header
          _buildRouteHeader(),

          // Location inputs
          _buildLocationInputs(),

          // Travel options
          _buildTravelOptions(),

          // Route summary or directions
          if (_currentRoute != null) ...[
            _buildRouteSummary(),
            _buildDirectionsList(),
          ] else if (_isLoading)
            _buildLoadingIndicator()
          else
            _buildSearchPrompt(),
        ],
      ),
    );
  }

  Widget _buildRouteHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.directions,
            color: Colors.blue[600],
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Directions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _calculateRoute,
            icon: const Icon(Icons.search),
            tooltip: 'Get Directions',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInputs() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Origin input
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.my_location, color: Colors.green[600]),
                ),
                Expanded(
                  child: TextField(
                    controller: _originController,
                    decoration: const InputDecoration(
                      hintText: 'Your location',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      widget.onLocationSearch?.call(value);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Swap button
          Center(
            child: IconButton(
              onPressed: _swapLocations,
              icon: const Icon(Icons.swap_vert),
              tooltip: 'Swap locations',
            ),
          ),

          const SizedBox(height: 8),

          // Destination input
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.place, color: Colors.red[600]),
                ),
                Expanded(
                  child: TextField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      hintText: 'Choose destination',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      widget.onLocationSearch?.call(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Travel mode selector
          Row(
            children: [
              _buildTravelModeButton('driving', Icons.directions_car, 'Drive'),
              const SizedBox(width: 8),
              _buildTravelModeButton('walking', Icons.directions_walk, 'Walk'),
              const SizedBox(width: 8),
              _buildTravelModeButton('bicycling', Icons.directions_bike, 'Bike'),
              const SizedBox(width: 8),
              _buildTravelModeButton('transit', Icons.directions_transit, 'Transit'),
            ],
          ),

          const SizedBox(height: 12),

          // Route options
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Avoid tolls'),
                  value: _avoidTolls,
                  onChanged: (value) {
                    setState(() {
                      _avoidTolls = value ?? false;
                    });
                  },
                  dense: true,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Avoid highways'),
                  value: _avoidHighways,
                  onChanged: (value) {
                    setState(() {
                      _avoidHighways = value ?? false;
                    });
                  },
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTravelModeButton(String mode, IconData icon, String label) {
    final isSelected = _travelMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _travelMode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue[600] : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.blue[600] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSummary() {
    if (_currentRoute == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.route, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentRoute!.summary.isNotEmpty 
                      ? _currentRoute!.summary 
                      : 'Best route',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryItem(
                Icons.access_time,
                _currentRoute!.duration,
                'Duration',
              ),
              const SizedBox(width: 24),
              _buildSummaryItem(
                Icons.straighten,
                _currentRoute!.distance,
                'Distance',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionsList() {
    if (_currentRoute?.steps == null || _currentRoute!.steps.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200,
      child: ListView.builder(
        itemCount: _currentRoute!.steps.length,
        itemBuilder: (context, index) {
          final step = _currentRoute!.steps[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(
                  step.maneuverIcon,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
              title: Text(
                _stripHtml(step.instructions),
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text('${step.distance} • ${step.duration}'),
              dense: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Calculating route...'),
        ],
      ),
    );
  }

  Widget _buildSearchPrompt() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.directions,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Enter destination to get directions',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _swapLocations() {
    final temp = _originController.text;
    _originController.text = _destinationController.text;
    _destinationController.text = temp;
  }

  Future<void> _calculateRoute() async {
    if (widget.origin == null || widget.destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select origin and destination')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _directionsService.getDirections(
        origin: widget.origin!,
        destination: widget.destination!,
        travelMode: _travelMode,
        avoidTolls: _avoidTolls,
        avoidHighways: _avoidHighways,
      );

      setState(() {
        _currentRoute = result;
        _isLoading = false;
      });

      widget.onRouteCalculated?.call(result);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating route: $e')),
      );
    }
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}
