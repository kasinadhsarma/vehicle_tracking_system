import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'core/controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'features/auth/phone_auth_screen.dart';

class VehicleTrackingApp extends StatelessWidget {
  const VehicleTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: GetMaterialApp(
        title: 'Vadodara Vehicle Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const PhoneAuthScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late Animation<double> _iconAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToHome();
  }

  void _setupAnimations() {
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    _iconController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Get.offAllNamed('/phone-auth');
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.primaryGradientDark
              : AppGradients.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _iconAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _iconAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _textAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'Vehicle Tracking System',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Real-time GPS tracking for your fleet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const MapPage(),
    const VehiclesPage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).navigationRailTheme.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: Text('Map'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.directions_car_outlined),
                  selectedIcon: Icon(Icons.directions_car),
                  label: Text('Vehicles'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assessment_outlined),
                  selectedIcon: Icon(Icons.assessment),
                  label: Text('Reports'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: themeController.toggleTheme,
                          icon: Icon(themeController.themeIcon),
                          tooltip: themeController.themeName,
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: () {
                            Get.toNamed('/phone-auth');
                          },
                          icon: const Icon(Icons.phone_android),
                          tooltip: 'Phone Authentication',
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: () {
                            Get.snackbar(
                              'Booking',
                              'Book a ride in Vadodara!',
                              backgroundColor: Colors.blue,
                              colorText: Colors.white,
                              icon: const Icon(Icons.local_taxi, color: Colors.white),
                            );
                          },
                          icon: const Icon(Icons.local_taxi),
                          tooltip: 'Book Ride',
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.location_on,
                          size: 24,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with greeting and controls
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, Vadodara Manager',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your fleet status across Vadodara, Gujarat',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              CustomButton(
                text: 'Refresh Data',
                icon: Icons.refresh,
                onPressed: () {},
                isOutlined: true,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Overview Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Active Vehicles',
                  '48',
                  '8 on route',
                  Icons.directions_car,
                  Colors.green,
                  true,
                  '5%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Total Distance',
                  '2,847',
                  'km today',
                  Icons.route,
                  Colors.blue,
                  true,
                  '12%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Alerts',
                  '3',
                  '1 critical',
                  Icons.warning,
                  Colors.orange,
                  false,
                  '2',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Fuel Efficiency',
                  '12.4',
                  'km/l avg',
                  Icons.local_gas_station,
                  Colors.teal,
                  true,
                  '3%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Vadodara Booking Section
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_taxi,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Book a Ride in Vadodara',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Quick auto/cab booking service for Vadodara city - Railway Station to Alkapuri, Sayajigunj to Makarpura and more!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to phone auth first if not authenticated
                        Get.toNamed('/phone-auth');
                      },
                      icon: const Icon(Icons.phone_android),
                      label: const Text('Book Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Show a snackbar and inform user to use the Map tab
                        Get.snackbar(
                          'Live Map',
                          'Use the Map tab in the navigation rail to view live tracking',
                          backgroundColor: Colors.blue,
                          colorText: Colors.white,
                          icon: const Icon(Icons.map, color: Colors.white),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('View Live Map'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Main Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Fleet Status
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fleet Status',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildStatusChip(
                                      context,
                                      'Active',
                                      48,
                                      Colors.green,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStatusChip(
                                      context,
                                      'Maintenance',
                                      5,
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildStatusChip(
                                      context,
                                      'Idle',
                                      12,
                                      Colors.grey,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStatusChip(
                                      context,
                                      'Offline',
                                      2,
                                      Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recent Activity
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recent Activity',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(5, (index) {
                            final activities = [
                              {
                                'vehicle': 'TRK-001',
                                'activity': 'Route completed',
                                'time': '2 min ago',
                                'color': Colors.green,
                              },
                              {
                                'vehicle': 'VAN-234',
                                'activity': 'Maintenance due',
                                'time': '15 min ago',
                                'color': Colors.orange,
                              },
                              {
                                'vehicle': 'TRK-007',
                                'activity': 'Speed limit exceeded',
                                'time': '1 hour ago',
                                'color': Colors.red,
                              },
                              {
                                'vehicle': 'VAN-112',
                                'activity': 'Delivery completed',
                                'time': '2 hours ago',
                                'color': Colors.green,
                              },
                              {
                                'vehicle': 'TRK-045',
                                'activity': 'Started journey',
                                'time': '3 hours ago',
                                'color': Colors.blue,
                              },
                            ];
                            final activity = activities[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (activity['color'] as Color)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: (activity['color'] as Color)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      activity['vehicle'] as String,
                                      style: TextStyle(
                                        color: activity['color'] as Color,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      activity['activity'] as String,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    activity['time'] as String,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Right Column
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Quick Actions
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bolt,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Quick Actions',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Add Vehicle',
                              icon: Icons.add,
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Generate Report',
                              icon: Icons.description,
                              onPressed: () {},
                              isOutlined: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.location_on),
                            label: const Text('Set Geofence'),
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // System Status
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.health_and_safety,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'System Status',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatusRow(context, 'GPS Tracking', true),
                          _buildStatusRow(context, 'Data Sync', true),
                          _buildStatusRow(context, 'Notifications', false),
                          _buildStatusRow(context, 'Backup', true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    bool isUp,
    String trendValue,
  ) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUp
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isUp ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendValue,
                      style: TextStyle(
                        color: isUp ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String label, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isOnline ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final RealTimeTrackingService _trackingService =
      RealTimeTrackingService.instance;
  final DirectionsService _directionsService = DirectionsService.instance;

  bool _isInitialized = false;
  bool _isTracking = false;
  FleetOverview? _fleetOverview;
  DirectionsResult? _currentRoute;
  LatLng? _selectedOrigin;
  LatLng? _selectedDestination;
  bool _showRoutePanel = false;

  // Mock vehicle data for demonstration - Vadodara locations
  final List<Map<String, dynamic>> _vehicles = [
    {
      'id': 'GJ-06-VH-001',
      'lat': 22.3072, // Vadodara Railway Station
      'lng': 73.1812,
      'status': 'Active',
      'driverId': 'driver_001',
    },
    {
      'id': 'GJ-06-VH-002', 
      'lat': 22.3511, // MS University
      'lng': 73.1350,
      'status': 'Idle',
      'driverId': 'driver_002',
    },
    {
      'id': 'GJ-06-VH-003',
      'lat': 22.3178, // Sayajigunj
      'lng': 73.1562,
      'status': 'Active',
      'driverId': 'driver_003',
    },
    {
      'id': 'GJ-06-VH-004',
      'lat': 22.2587, // Makarpura
      'lng': 73.2137,
      'status': 'Offline',
      'driverId': 'driver_004',
    },
    {
      'id': 'GJ-06-VH-005',
      'lat': 22.3264, // Alkapuri
      'lng': 73.1673,
      'status': 'Active',
      'driverId': 'driver_005',
    },
  ];

  String? _selectedVehicleId;
  String? _selectedDriverId;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadFleetOverview();
  }

  Future<void> _initializeServices() async {
    try {
      final success = await _trackingService.initialize();
      if (success && mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  Future<void> _loadFleetOverview() async {
    try {
      final overview = await _trackingService.getFleetOverview();
      if (mounted) {
        setState(() {
          _fleetOverview = overview;
        });
      }
    } catch (e) {
      debugPrint('Error loading fleet overview: $e');
    }
  }

  Future<void> _startTracking(String vehicleId, String driverId) async {
    if (!_isInitialized) return;

    try {
      final success = await _trackingService.startTracking(
        vehicleId: vehicleId,
        driverId: driverId,
        mode: TrackingMode.normal,
      );

      if (success && mounted) {
        setState(() {
          _isTracking = true;
          _selectedVehicleId = vehicleId;
          _selectedDriverId = driverId;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started tracking vehicle $vehicleId'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start tracking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopTracking() async {
    try {
      await _trackingService.stopTracking();
      if (mounted) {
        setState(() {
          _isTracking = false;
          _selectedVehicleId = null;
          _selectedDriverId = null;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stopped tracking'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop tracking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFleetOverview,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showMapSettings,
          ),
          if (_isTracking)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopTracking,
              tooltip: 'Stop Tracking',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCards(),
          Expanded(
            child: _isInitialized ? _buildAdvancedMap() : _buildLoadingView(),
          ),
        ],
      ),
      floatingActionButton: _buildTrackingFAB(),
    );
  }

  Widget _buildStatusCards() {
    final activeCount =
        _fleetOverview?.activeVehicles ??
        _vehicles.where((v) => v['status'] == 'Active').length;
    final idleCount = _vehicles.where((v) => v['status'] == 'Idle').length;
    final offlineCount = _vehicles
        .where((v) => v['status'] == 'Offline')
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              icon: Icons.directions_car,
              color: Colors.green,
              count: activeCount,
              label: 'Active',
            ),
          ),
          Expanded(
            child: _buildStatusCard(
              icon: Icons.pause_circle,
              color: Colors.orange,
              count: idleCount,
              label: 'Idle',
            ),
          ),
          Expanded(
            child: _buildStatusCard(
              icon: Icons.offline_bolt,
              color: Colors.red,
              count: offlineCount,
              label: 'Offline',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color color,
    required int count,
    required String label,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedMap() {
    return Stack(
      children: [
        RealWorldMapWidget(
          vehicleId: _selectedVehicleId,
          driverId: _selectedDriverId,
          showGeofences: true,
          showRoutes: true,
          showBehaviorEvents: true,
          mapType: MapType.normal,
          initialZoom: 12.0,
          initialCenter: const LatLng(22.3072, 73.1812), // Vadodara Railway Station
          onMapReady: () {
            debugPrint('Advanced map ready - Centered on Vadodara');
          },
          onLocationTap: (position) {
            _showLocationOptions(position);
          },
        ),
        // Route Planning Panel
        if (_showRoutePanel)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: RoutePlanningPanel(
              currentLocation: const LatLng(22.3072, 73.1812),
              onRouteSelected: (routePoints) {
                // Handle route selection - this would update the map with the route
                debugPrint('Route selected with ${routePoints.length} points');
              },
            ),
          ),
        // Toggle Route Panel Button
        Positioned(
          top: 16,
          left: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: "route_planning",
            onPressed: () {
              setState(() {
                _showRoutePanel = !_showRoutePanel;
              });
            },
            backgroundColor: _showRoutePanel ? Colors.blue : Colors.white,
            foregroundColor: _showRoutePanel ? Colors.white : Colors.blue,
            child: const Icon(Icons.directions),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing Real-Time Tracking...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Setting up GPS, geofences, and behavior monitoring',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildTrackingFAB() {
    if (!_isInitialized) return null;

    return FloatingActionButton.extended(
      onPressed: _isTracking ? null : _showVehicleSelector,
      icon: Icon(_isTracking ? Icons.gps_fixed : Icons.gps_not_fixed),
      label: Text(
        _isTracking ? 'Tracking ${_selectedVehicleId}' : 'Start Tracking',
      ),
      backgroundColor: _isTracking ? Colors.green : Colors.blue,
    );
  }

  void _showVehicleSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Vehicle to Track',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = _vehicles[index];
                  final isOffline = vehicle['status'] == 'Offline';

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isOffline ? Colors.red : Colors.green,
                        child: Icon(Icons.directions_car, color: Colors.white),
                      ),
                      title: Text('Vehicle ${vehicle['id']}'),
                      subtitle: Text(
                        'Status: ${vehicle['status']}\n'
                        'Driver: ${vehicle['driverId']}\n'
                        'Location: ${_getVadodaraLocationName(vehicle['lat'], vehicle['lng'])}',
                      ),
                      trailing: isOffline
                          ? const Icon(Icons.block, color: Colors.red)
                          : const Icon(Icons.arrow_forward_ios),
                      enabled: !isOffline,
                      onTap: isOffline
                          ? null
                          : () {
                              Navigator.pop(context);
                              _startTracking(
                                vehicle['id'],
                                vehicle['driverId'],
                              );
                            },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationOptions(LatLng position) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_location),
              title: const Text('Create Geofence'),
              subtitle: Text(
                'Lat: ${position.latitude.toStringAsFixed(6)}\n'
                'Lng: ${position.longitude.toStringAsFixed(6)}',
              ),
              onTap: () {
                Navigator.pop(context);
                _createGeofence(position);
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text('Get Directions'),
              subtitle: const Text('Navigate to this location'),
              onTap: () {
                Navigator.pop(context);
                _getDirections(position);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Location Info'),
              subtitle: const Text('View detailed information'),
              onTap: () {
                Navigator.pop(context);
                _showLocationInfo(position);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMapSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Show Geofences'),
              value: true,
              onChanged: (value) {
                // TODO: Implement geofence toggle
              },
            ),
            SwitchListTile(
              title: const Text('Show Routes'),
              value: true,
              onChanged: (value) {
                // TODO: Implement route toggle
              },
            ),
            SwitchListTile(
              title: const Text('Show Behavior Events'),
              value: true,
              onChanged: (value) {
                // TODO: Implement behavior events toggle
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _createGeofence(LatLng position) {
    // TODO: Implement geofence creation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Geofence creation feature will be implemented'),
      ),
    );
  }

  void _getDirections(LatLng position) {
    // TODO: Implement directions feature
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Directions feature will be implemented')),
    );
  }

  void _showLocationInfo(LatLng position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${position.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${position.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            const Text('Address: Loading...'),
            const Text('Nearest Road: Loading...'),
            const Text('Speed Limit: Loading...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Helper method to get Vadodara location names from coordinates
  String _getVadodaraLocationName(double lat, double lng) {
    // Map coordinates to Vadodara location names
    if (lat == 22.3072 && lng == 73.1812) return 'Vadodara Railway Station';
    if (lat == 22.3511 && lng == 73.1350) return 'MS University';
    if (lat == 22.3178 && lng == 73.1562) return 'Sayajigunj';
    if (lat == 22.2587 && lng == 73.2137) return 'Makarpura';
    if (lat == 22.3264 && lng == 73.1673) return 'Alkapuri';
    
    // Fallback to area names based on approximate coordinates
    if (lat >= 22.30 && lat <= 22.35 && lng >= 73.10 && lng <= 73.20) {
      return 'Central Vadodara';
    } else if (lat >= 22.25 && lat <= 22.30 && lng >= 73.15 && lng <= 73.25) {
      return 'Makarpura Industrial Area';
    } else if (lat >= 22.32 && lat <= 22.37 && lng >= 73.15 && lng <= 73.22) {
      return 'Gotri Area';
    }
    
    return 'Vadodara, Gujarat';
  }

  @override
  void dispose() {
    // Stop tracking service and clean up resources
    if (_isTracking) {
      _trackingService.stopTracking();
    }
    super.dispose();
  }
}

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final List<Map<String, dynamic>> _vehicles = [
    {
      'id': 'VH-001',
      'driver': 'John Smith',
      'status': 'Active',
      'location': 'Downtown NYC',
      'speed': '45 km/h',
      'fuel': '75%',
      'lastUpdate': '2 min ago',
    },
    {
      'id': 'VH-002',
      'driver': 'Jane Doe',
      'status': 'Idle',
      'location': 'Central Park',
      'speed': '0 km/h',
      'fuel': '89%',
      'lastUpdate': '5 min ago',
    },
    {
      'id': 'VH-003',
      'driver': 'Mike Johnson',
      'status': 'Active',
      'location': 'Brooklyn Bridge',
      'speed': '32 km/h',
      'fuel': '45%',
      'lastUpdate': '1 min ago',
    },
    {
      'id': 'VH-004',
      'driver': 'Sarah Wilson',
      'status': 'Offline',
      'location': 'Unknown',
      'speed': '0 km/h',
      'fuel': '60%',
      'lastUpdate': '2 hours ago',
    },
    {
      'id': 'VH-005',
      'driver': 'Tom Brown',
      'status': 'Active',
      'location': 'Times Square',
      'speed': '28 km/h',
      'fuel': '92%',
      'lastUpdate': '30 sec ago',
    },
  ];

  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredVehicles = _filterStatus == 'All'
        ? _vehicles
        : _vehicles
              .where((vehicle) => vehicle['status'] == _filterStatus)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Vehicles')),
              const PopupMenuItem(value: 'Active', child: Text('Active Only')),
              const PopupMenuItem(value: 'Idle', child: Text('Idle Only')),
              const PopupMenuItem(
                value: 'Offline',
                child: Text('Offline Only'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddVehicleDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_vehicles.where((v) => v['status'] == 'Active').length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Active Vehicles'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pause_circle,
                            color: Colors.orange.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_vehicles.where((v) => v['status'] == 'Idle').length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Idle Vehicles'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error,
                            color: Colors.red.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_vehicles.where((v) => v['status'] == 'Offline').length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Offline Vehicles'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Showing ${filteredVehicles.length} of ${_vehicles.length} vehicles',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Chip(
                  label: Text(_filterStatus),
                  onDeleted: _filterStatus != 'All'
                      ? () {
                          setState(() {
                            _filterStatus = 'All';
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = filteredVehicles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: vehicle['status'] == 'Active'
                          ? Colors.green.shade100
                          : vehicle['status'] == 'Idle'
                          ? Colors.orange.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        Icons.directions_car,
                        color: vehicle['status'] == 'Active'
                            ? Colors.green.shade700
                            : vehicle['status'] == 'Idle'
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    title: Text(vehicle['id']),
                    subtitle: Text('Driver: ${vehicle['driver']}'),
                    trailing: Chip(
                      label: Text(vehicle['status']),
                      backgroundColor: vehicle['status'] == 'Active'
                          ? Colors.green.shade100
                          : vehicle['status'] == 'Idle'
                          ? Colors.orange.shade100
                          : Colors.red.shade100,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Location',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(vehicle['location']),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Speed',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(vehicle['speed']),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Fuel Level',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(vehicle['fuel']),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Last Update',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(vehicle['lastUpdate']),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _showVehicleDetails(vehicle);
                                  },
                                  icon: const Icon(Icons.info),
                                  label: const Text('Details'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _trackVehicle(vehicle);
                                  },
                                  icon: const Icon(Icons.location_on),
                                  label: const Text('Track'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _sendCommand(vehicle);
                                  },
                                  icon: const Icon(Icons.send),
                                  label: const Text('Command'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Vehicle'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Vehicle ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Driver Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vehicle added successfully!')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showVehicleDetails(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vehicle ${vehicle['id']} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: ${vehicle['driver']}'),
            Text('Status: ${vehicle['status']}'),
            Text('Location: ${vehicle['location']}'),
            Text('Speed: ${vehicle['speed']}'),
            Text('Fuel: ${vehicle['fuel']}'),
            Text('Last Update: ${vehicle['lastUpdate']}'),
            const SizedBox(height: 16),
            const Text(
              'Recent Trips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Trip to Brooklyn - 2 hours'),
            const Text('• Trip to Queens - 1.5 hours'),
            const Text('• Trip to Manhattan - 45 minutes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _trackVehicle(Map<String, dynamic> vehicle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tracking ${vehicle['id']} on map...')),
    );
  }

  void _sendCommand(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Command to ${vehicle['id']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.lock), title: Text('Lock Vehicle')),
            ListTile(
              leading: Icon(Icons.lock_open),
              title: Text('Unlock Vehicle'),
            ),
            ListTile(
              leading: Icon(Icons.report),
              title: Text('Request Status Report'),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Get Current Location'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedPeriod = 'Today';

  final Map<String, Map<String, dynamic>> _reportData = {
    'Today': {
      'totalDistance': '1,245 km',
      'totalTrips': '47',
      'fuelConsumed': '89.5 L',
      'avgSpeed': '42.3 km/h',
      'alerts': '12',
      'efficiency': '87%',
    },
    'This Week': {
      'totalDistance': '8,932 km',
      'totalTrips': '342',
      'fuelConsumed': '645.2 L',
      'avgSpeed': '45.7 km/h',
      'alerts': '89',
      'efficiency': '91%',
    },
    'This Month': {
      'totalDistance': '34,567 km',
      'totalTrips': '1,234',
      'fuelConsumed': '2,456.8 L',
      'avgSpeed': '43.9 km/h',
      'alerts': '234',
      'efficiency': '89%',
    },
  };

  @override
  Widget build(BuildContext context) {
    final currentData = _reportData[_selectedPeriod]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Today', child: Text('Today')),
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(
                value: 'This Month',
                child: Text('This Month'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _exportReport();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Analytics Overview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Chip(
                  label: Text(_selectedPeriod),
                  backgroundColor: Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Key Metrics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  'Total Distance',
                  currentData['totalDistance'],
                  Icons.straighten,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Total Trips',
                  currentData['totalTrips'],
                  Icons.route,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Fuel Consumed',
                  currentData['fuelConsumed'],
                  Icons.local_gas_station,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Avg Speed',
                  currentData['avgSpeed'],
                  Icons.speed,
                  Colors.purple,
                ),
                _buildMetricCard(
                  'Alerts',
                  currentData['alerts'],
                  Icons.warning,
                  Colors.red,
                ),
                _buildMetricCard(
                  'Efficiency',
                  currentData['efficiency'],
                  Icons.eco,
                  Colors.teal,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Chart Section
            Text(
              'Trend Analysis',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Interactive Charts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'FL Chart integration for detailed analytics',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Report Types Grid
            Text(
              'Detailed Reports',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildReportCard(
                  'Trip Reports',
                  'Detailed trip analysis and history',
                  Icons.route,
                  Colors.blue,
                  () => _showTripReport(),
                ),
                _buildReportCard(
                  'Driver Behavior',
                  'Driving patterns and safety metrics',
                  Icons.person,
                  Colors.green,
                  () => _showDriverReport(),
                ),
                _buildReportCard(
                  'Fuel Analysis',
                  'Consumption patterns and efficiency',
                  Icons.local_gas_station,
                  Colors.orange,
                  () => _showFuelReport(),
                ),
                _buildReportCard(
                  'Maintenance',
                  'Vehicle health and service records',
                  Icons.build,
                  Colors.purple,
                  () => _showMaintenanceReport(),
                ),
                _buildReportCard(
                  'Geofence',
                  'Zone violations and compliance',
                  Icons.location_city,
                  Colors.red,
                  () => _showGeofenceReport(),
                ),
                _buildReportCard(
                  'Custom Report',
                  'Create your own custom analytics',
                  Icons.tune,
                  Colors.teal,
                  () => _showCustomReport(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Export as PDF'),
            ),
            ListTile(
              leading: Icon(Icons.table_chart),
              title: Text('Export as Excel'),
            ),
            ListTile(leading: Icon(Icons.code), title: Text('Export as CSV')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTripReport() {
    _showDetailedReport('Trip Reports', [
      'Total trips completed: 342',
      'Average trip duration: 1.2 hours',
      'Longest trip: 4.5 hours (NYC to Boston)',
      'Shortest trip: 15 minutes',
      'Most frequent route: Downtown to Airport',
    ]);
  }

  void _showDriverReport() {
    _showDetailedReport('Driver Behavior Analysis', [
      'Average driver score: 87/100',
      'Speed violations: 23 incidents',
      'Harsh braking events: 45',
      'Best performing driver: John Smith (95/100)',
      'Needs improvement: Mike Johnson (72/100)',
    ]);
  }

  void _showFuelReport() {
    _showDetailedReport('Fuel Analysis', [
      'Total fuel consumed: 645.2 L',
      'Average fuel efficiency: 8.5 km/L',
      'Most efficient vehicle: VH-003 (9.2 km/L)',
      'Least efficient vehicle: VH-001 (7.1 km/L)',
      'Potential savings: \$234/month',
    ]);
  }

  void _showMaintenanceReport() {
    _showDetailedReport('Maintenance Overview', [
      'Vehicles due for service: 3',
      'Total maintenance cost: \$2,450',
      'Most recent service: VH-002 (Oil change)',
      'Overdue maintenance: VH-004 (Brake check)',
      'Next scheduled service: VH-001 (Tire rotation)',
    ]);
  }

  void _showGeofenceReport() {
    _showDetailedReport('Geofence Compliance', [
      'Total geofence violations: 12',
      'Most violated zone: Construction Area #3',
      'Compliance rate: 94.2%',
      'Recent violation: VH-005 at Industrial Zone',
      'Alert response time: 2.3 minutes average',
    ]);
  }

  void _showCustomReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Report Builder'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Report Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Date Range',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.date_range),
              ),
            ),
            SizedBox(height: 16),
            Text('Select metrics to include:'),
            CheckboxListTile(
              title: Text('Distance Traveled'),
              value: true,
              onChanged: null,
            ),
            CheckboxListTile(
              title: Text('Fuel Consumption'),
              value: true,
              onChanged: null,
            ),
            CheckboxListTile(
              title: Text('Driver Behavior'),
              value: false,
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom report generated!')),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showDetailedReport(String title, List<String> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details
                .map(
                  (detail) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(detail)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportReport();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _locationSharing = true;
  bool _autoBackup = true;
  String _updateFrequency = '30 seconds';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Settings',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Manage your preferences and account',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),

          // User Profile Section
          CustomCard(
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fleet Manager',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'admin@vehicletracking.com',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomButton(
                  text: 'Edit',
                  icon: Icons.edit,
                  onPressed: _editProfile,
                  isOutlined: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Settings
          Text(
            'Appearance',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Column(
              children: [
                Obx(
                  () => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        themeController.themeIcon,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: const Text('Theme'),
                    subtitle: Text(themeController.themeName),
                    trailing: Switch(
                      value: themeController.isDarkMode,
                      onChanged: (_) => themeController.toggleTheme(),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.language,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: const Text('Language'),
                  subtitle: Text(_language),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showLanguageDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // System Settings
          Text(
            'System',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.update, color: Colors.blue),
                  ),
                  title: const Text('Update Frequency'),
                  subtitle: Text(_updateFrequency),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showUpdateFrequencyDialog,
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications, color: Colors.green),
                  ),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive alerts and updates'),
                  value: _notifications,
                  onChanged: (value) {
                    setState(() {
                      _notifications = value;
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.orange),
                  ),
                  title: const Text('Location Sharing'),
                  subtitle: const Text('Share location data with fleet'),
                  value: _locationSharing,
                  onChanged: (value) {
                    setState(() {
                      _locationSharing = value;
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.backup, color: Colors.purple),
                  ),
                  title: const Text('Auto Backup'),
                  subtitle: const Text('Automatically backup data'),
                  value: _autoBackup,
                  onChanged: (value) {
                    setState(() {
                      _autoBackup = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security & Privacy
          Text(
            'Security & Privacy',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock, color: Colors.red),
                  ),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your account password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security, color: Colors.teal),
                  ),
                  title: const Text('Two-Factor Authentication'),
                  subtitle: const Text('Enable 2FA for extra security'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Support & About
          Text(
            'Support & About',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          CustomCard(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.help, color: Colors.blue),
                  ),
                  title: const Text('Help Center'),
                  subtitle: const Text('Get help and tutorials'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.contact_support,
                      color: Colors.green,
                    ),
                  ),
                  title: const Text('Contact Support'),
                  subtitle: const Text('Get in touch with our team'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info, color: Colors.purple),
                  ),
                  title: const Text('About'),
                  subtitle: const Text('Version 1.0.0 - Build 001'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showAboutDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Logout',
              icon: Icons.logout,
              onPressed: _showLogoutDialog,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'Spanish',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('French'),
              value: 'French',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('10 seconds'),
              value: '10 seconds',
              groupValue: _updateFrequency,
              onChanged: (value) {
                setState(() {
                  _updateFrequency = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('30 seconds'),
              value: '30 seconds',
              groupValue: _updateFrequency,
              onChanged: (value) {
                setState(() {
                  _updateFrequency = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('1 minute'),
              value: '1 minute',
              groupValue: _updateFrequency,
              onChanged: (value) {
                setState(() {
                  _updateFrequency = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Vehicle Tracking System',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.location_on, size: 48),
      children: [
        const Text(
          'A comprehensive vehicle tracking system with real-time monitoring, geofencing, and driver behavior analysis.',
        ),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Real-time GPS tracking'),
        const Text('• Fleet management'),
        const Text('• Driver behavior analysis'),
        const Text('• Geofencing alerts'),
        const Text('• Comprehensive reporting'),
      ],
    );
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
