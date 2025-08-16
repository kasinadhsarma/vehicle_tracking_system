import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'full_screen_map_view.dart';
import '../reports/simple_reports_screen.dart';
import 'dart:async';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard>
    with TickerProviderStateMixin {
  int _selectedBottomIndex = 0;
  bool _isTracking = false;
  String _trackingStatus = 'GPS Ready - Tap to start tracking';
  String _currentLocation = 'Vadodara, Gujarat';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Mobile tracking mode
  String _userMode = 'rider'; // 'rider' or 'driver'
  Position? _currentPosition;
  double _currentSpeed = 0.0;
  
  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  static const CameraPosition _vadodaraCenter = CameraPosition(
    target: LatLng(22.3072, 73.1812), // Vadodara coordinates
    zoom: 14.0,
  );
  
  // Vadodara specific locations
  final List<Map<String, dynamic>> _vadodaraLandmarks = [
    {
      'name': 'Laxmi Vilas Palace',
      'distance': '3.2 km',
      'type': 'Heritage Site',
      'icon': Icons.account_balance,
    },
    {
      'name': 'Sayaji Garden',
      'distance': '1.8 km', 
      'type': 'Park',
      'icon': Icons.park,
    },
    {
      'name': 'Vadodara Railway Station',
      'distance': '5.1 km',
      'type': 'Transport Hub',
      'icon': Icons.train,
    },
    {
      'name': 'Alkapuri Circle',
      'distance': '2.3 km',
      'type': 'Shopping Area',
      'icon': Icons.shopping_bag,
    },
  ];

  // Sample tracking data for family/friends
  final List<Map<String, dynamic>> _familyTracking = [
    {
      'name': 'Papa',
      'phone': '+91 98765 43210',
      'location': 'Near Alkapuri',
      'lastSeen': '2 min ago',
      'isOnline': true,
      'vehicleType': 'Car',
    },
    {
      'name': 'Mummy', 
      'phone': '+91 98765 43211',
      'location': 'Sayaji Garden',
      'lastSeen': '5 min ago',
      'isOnline': true,
      'vehicleType': 'Scooter',
    },
    {
      'name': 'Bhai',
      'phone': '+91 98765 43212',
      'location': 'Railway Station',
      'lastSeen': '15 min ago', 
      'isOnline': false,
      'vehicleType': 'Bike',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _requestLocationPermission();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _trackingStatus = 'Location services are disabled';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _trackingStatus = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _trackingStatus = 'Location permissions are permanently denied';
      });
      return;
    }

    setState(() {
      _trackingStatus = 'GPS Ready - Tap to start tracking';
    });
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      setState(() {
        _isTracking = false;
        _trackingStatus = 'GPS tracking stopped';
      });
    } else {
      setState(() {
        _isTracking = true;
        _trackingStatus = 'GPS tracking active...';
      });
      
      try {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = position;
          _currentLocation = 'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
          _currentSpeed = position.speed * 3.6; // Convert m/s to km/h
          _trackingStatus = 'Tracking your location in Vadodara';
        });
      } catch (e) {
        setState(() {
          _trackingStatus = 'Error getting location: $e';
          _isTracking = false;
        });
      }
    }
  }

  void _toggleUserMode() {
    setState(() {
      _userMode = _userMode == 'rider' ? 'driver' : 'rider';
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        title: const Text(
          'Vadodara Vehicle Tracker',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleUserMode,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _userMode == 'driver' ? Icons.drive_eta : Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _userMode == 'driver' ? 'Driver' : 'Rider',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedBottomIndex,
        children: [
          _buildHomeTab(),
          _buildTrackingTab(),
          _buildFamilyTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50),
                  const Color(0xFF45A049),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isTracking ? _pulseAnimation.value : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  _trackingStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _currentLocation,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _toggleTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _isTracking ? 'Stop Tracking' : 'Start Tracking',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Mode Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _userMode == 'driver' ? Icons.drive_eta : Icons.person,
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _userMode == 'driver' ? 'Driver Mode' : 'Rider Mode',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E3A59),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _userMode == 'driver' 
                    ? 'You\'re sharing your vehicle location with others'
                    : 'You can track family vehicles and book rides',
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 14,
                  ),
                ),
                if (_currentSpeed > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.speed,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Speed: ${_currentSpeed.toStringAsFixed(1)} km/h',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3A59),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 12),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildQuickActionCard(
                'Emergency SOS',
                Icons.emergency,
                Colors.red,
                () => _showEmergencyDialog(),
              ),
              _buildQuickActionCard(
                'PDF Reports',
                Icons.analytics,
                const Color(0xFF4CAF50),
                () => _openReports(),
              ),
              _buildQuickActionCard(
                'Share Location',
                Icons.share_location,
                const Color(0xFF2196F3),
                () => _shareLocation(),
              ),
              _buildQuickActionCard(
                'Route History',
                Icons.history,
                const Color(0xFF9C27B0),
                () => _showRouteHistory(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Section
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    initialCameraPosition: _vadodaraCenter,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      _addVadodaraMarkers();
                    },
                    markers: _markers,
                    zoomControlsEnabled: true,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapType: MapType.normal,
                    compassEnabled: true,
                    trafficEnabled: false,
                  ),
                ),
                // Full-screen map button
                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    heroTag: "fullscreen_map",
                    onPressed: () => Get.to(() => const FullScreenMapView()),
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.fullscreen,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Location Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E3A59),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Vadodara, Gujarat - Demo Mode',
                            style: TextStyle(
                              color: Color(0xFF8A8A8A),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_currentPosition != null) ...[
                  Text(
                    'Coordinates: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8A8A),
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (_currentSpeed > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.speed,
                          color: Color(0xFF4CAF50),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Speed: ${_currentSpeed.toStringAsFixed(1)} km/h',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E3A59),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  const Text(
                    'Tap "Start Tracking" on Home tab to get your GPS location',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8A8A8A),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Nearby Landmarks
          const Text(
            'Nearby Vadodara Landmarks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 12),
          
          ..._vadodaraLandmarks.map((landmark) => 
            _buildLandmarkCard(landmark)),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Family Tracking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3A59),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addFamilyMember(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ..._familyTracking.map((member) => 
            _buildFamilyMemberCard(member)),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF4CAF50),
                  child: Text(
                    'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vadodara User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3A59),
                  ),
                ),
                const Text(
                  '+91 6305953487',
                  style: TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _userMode == 'driver' ? 'Driver Mode' : 'Rider Mode',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Settings Options
          ...([
            {'icon': Icons.location_history, 'title': 'Trip History', 'subtitle': 'View your past trips'},
            {'icon': Icons.security, 'title': 'Privacy Settings', 'subtitle': 'Manage location sharing'},
            {'icon': Icons.notifications, 'title': 'Notifications', 'subtitle': 'Alert preferences'},
            {'icon': Icons.help, 'title': 'Help & Support', 'subtitle': 'Get help with the app'},
            {'icon': Icons.info, 'title': 'About', 'subtitle': 'App version and info'},
            {'icon': Icons.logout, 'title': 'Logout', 'subtitle': 'Sign out of your account'},
          ].map((item) => _buildSettingsItem(
            item['icon'] as IconData,
            item['title'] as String,
            item['subtitle'] as String,
          ))),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandmarkCard(Map<String, dynamic> landmark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              landmark['icon'],
              color: const Color(0xFF4CAF50),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  landmark['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  landmark['type'],
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                landmark['distance'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 4),
              const Icon(
                Icons.navigation,
                color: Color(0xFF8A8A8A),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF4CAF50),
                child: Text(
                  member['name'][0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: member['isOnline'] ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      member['vehicleType'] == 'Car' 
                        ? Icons.directions_car
                        : member['vehicleType'] == 'Bike'
                          ? Icons.motorcycle
                          : Icons.moped,
                      size: 16,
                      color: const Color(0xFF8A8A8A),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  member['location'],
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member['lastSeen'],
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _callFamilyMember(member),
            icon: const Icon(
              Icons.phone,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4CAF50),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF8A8A8A),
        ),
        onTap: () => _handleSettingsTap(title),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onTap: (index) => setState(() => _selectedBottomIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: const Color(0xFF8A8A8A),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gps_fixed),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Action methods
  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text('This will send your location to emergency contacts and authorities. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _triggerEmergencySOS();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _triggerEmergencySOS() {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency SOS sent! Location shared with emergency contacts.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _shareLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location shared successfully!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _openReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleReportsScreen()),
    );
  }

  void _showRouteHistory() {
    // Navigate to route history screen
    Get.snackbar(
      'Route History',
      'Your trip history will be displayed here',
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  void _openSettings() {
    // Navigate to settings screen
    Get.snackbar(
      'Settings',
      'App settings will be displayed here',
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  void _addFamilyMember() {
    Get.snackbar(
      'Add Family Member',
      'Feature to add family members for tracking',
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  void _callFamilyMember(Map<String, dynamic> member) {
    Get.snackbar(
      'Calling ${member['name']}',
      'Dialing ${member['phone']}',
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  void _handleSettingsTap(String title) {
    if (title == 'Logout') {
      _showLogoutDialog();
    } else {
      Get.snackbar(
        title,
        'This feature will be implemented soon',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.offAllNamed('/phone-auth');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _addVadodaraMarkers() {
    // Add markers for Vadodara landmarks
    for (int i = 0; i < _vadodaraLandmarks.length; i++) {
      final landmark = _vadodaraLandmarks[i];
      _markers.add(
        Marker(
          markerId: MarkerId('landmark_$i'),
          position: LatLng(
            // Approximate coordinates around Vadodara
            22.3072 + (i * 0.01) - 0.015,  
            73.1812 + (i * 0.01) - 0.015,
          ),
          infoWindow: InfoWindow(
            title: landmark['name'],
            snippet: '${landmark['type']} • ${landmark['distance']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Add current user location marker if available
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current GPS Position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    setState(() {});
  }

  Timer? _locationTimer;

  void _startTracking() {
    setState(() {
      _isTracking = true;
    });
    _getCurrentLocation();
    
    // Start location updates
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _getCurrentLocation();
    });
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
    });
    _locationTimer?.cancel();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        _currentSpeed = position.speed * 3.6; // Convert m/s to km/h
      });
      
      // Update map camera and marker if map is loaded
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
        
        // Add current position marker
        _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'Current GPS Position',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }
}
