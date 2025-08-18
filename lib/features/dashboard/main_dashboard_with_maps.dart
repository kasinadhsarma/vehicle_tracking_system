import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  
  // Vadodara coordinates
  static const LatLng _vadodaraCenter = LatLng(22.3072, 73.1812);
  
  Set<Marker> _markers = {};
  int _selectedBottomIndex = 0;
  bool _isRideBooked = false;
  String _rideStatus = 'Looking for nearby vehicles...';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Sample vehicle data
  final List<Map<String, dynamic>> _nearbyVehicles = [
    {
      'id': 'VH001',
      'type': 'Auto',
      'driver': 'Ravi Patel',
      'rating': 4.8,
      'distance': '2 min away',
      'location': const LatLng(22.3100, 73.1850),
      'fare': '₹45',
    },
    {
      'id': 'VH002', 
      'type': 'Car',
      'driver': 'Amit Shah',
      'rating': 4.9,
      'distance': '4 min away',
      'location': const LatLng(22.3000, 73.1900),
      'fare': '₹120',
    },
    {
      'id': 'VH003',
      'type': 'Bike',
      'driver': 'Kiran Modi',
      'rating': 4.7,
      'distance': '1 min away', 
      'location': const LatLng(22.3120, 73.1780),
      'fare': '₹25',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _addVehicleMarkers();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _addVehicleMarkers() {
    _markers = _nearbyVehicles.map((vehicle) {
      return Marker(
        markerId: MarkerId(vehicle['id']),
        position: vehicle['location'],
        icon: BitmapDescriptor.defaultMarkerWithHue(
          vehicle['type'] == 'Auto' ? BitmapDescriptor.hueGreen :
          vehicle['type'] == 'Car' ? BitmapDescriptor.hueBlue :
          BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: '${vehicle['type']} - ${vehicle['driver']}',
          snippet: '${vehicle['distance']} • ${vehicle['fare']}',
        ),
      );
    }).toSet();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedBottomIndex,
        children: [
          _buildMapView(),
          _buildRideHistory(),
          _buildProfile(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _selectedBottomIndex == 0 ? _buildBookRideFab() : null,
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController.complete(controller);
          },
          initialCameraPosition: const CameraPosition(
            target: _vadodaraCenter,
            zoom: 14.0,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),
        
        // Top App Bar
        _buildTopAppBar(),
        
        // Search Bar
        _buildSearchBar(),
        
        // Vehicle Selection Bottom Sheet
        if (_isRideBooked) _buildRideStatusSheet(),
        
        // My Location Button
        _buildMyLocationButton(),
      ],
    );
  }

  Widget _buildTopAppBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu,
                color: Color(0xFF2E3A59),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_city, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Vadodara',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Current Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2E3A59),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.only(left: 24),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Where do you want to go?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ),
                Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      right: 16,
      bottom: 200,
      child: FloatingActionButton(
        heroTag: "my_location_fab",
        onPressed: _goToCurrentLocation,
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.my_location,
          color: Color(0xFF4CAF50),
        ),
      ),
    );
  }

  Widget _buildBookRideFab() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: FloatingActionButton.extended(
        heroTag: "book_ride_fab",
        onPressed: _bookRide,
        backgroundColor: const Color(0xFF4CAF50),
        label: const Text(
          'Book a Ride',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.directions_car, color: Colors.white),
      ),
    );
  }

  Widget _buildRideStatusSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(_pulseAnimation.value),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _rideStatus,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E3A59),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'We\'ll notify you when a driver accepts',
                            style: TextStyle(
                              color: Color(0xFF6C757D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isRideBooked = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF4CAF50)),
                    ),
                    child: const Text(
                      'Cancel Request',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRideHistory() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Ride History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E3A59),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car, color: Color(0xFF4CAF50)),
              ),
              title: Text(
                'Ride to ${index % 2 == 0 ? 'Alkapuri' : 'Fatehgunj'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Aug ${15 - index}, 2025 • 2:${30 + index}0 PM'),
                  const SizedBox(height: 4),
                  Text(
                    '₹${80 + index * 20}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfile() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E3A59),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF4CAF50),
                      child: const Text(
                        'U',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Name',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '+91 6305953487',
                            style: TextStyle(
                              color: Color(0xFF6C757D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileOption(Icons.person, 'Edit Profile'),
            _buildProfileOption(Icons.payment, 'Payment Methods'),
            _buildProfileOption(Icons.help, 'Help & Support'),
            _buildProfileOption(Icons.settings, 'Settings'),
            _buildProfileOption(Icons.logout, 'Logout', isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {bool isLogout = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : const Color(0xFF4CAF50),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: isLogout ? _logout : null,
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedBottomIndex,
      onTap: (index) {
        setState(() {
          _selectedBottomIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  void _goToCurrentLocation() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLng(_vadodaraCenter),
    );
  }

  void _bookRide() {
    setState(() {
      _isRideBooked = true;
      _rideStatus = 'Looking for nearby vehicles...';
    });

    // Simulate finding a driver
    Timer(const Duration(seconds: 3), () {
      if (mounted && _isRideBooked) {
        setState(() {
          _rideStatus = 'Driver found! Ravi is coming to pick you up';
        });
      }
    });
  }

  void _logout() {
    Get.offAllNamed('/phone-auth');
  }
}
