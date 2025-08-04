import 'package:get/get.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/auth/views/role_selector_screen.dart';
import '../features/driver/views/driver_home_screen.dart';
import '../features/driver/views/live_tracking_screen.dart';
import '../features/driver/views/profile_screen.dart';
import '../features/manager/views/dashboard_screen.dart';
import '../features/manager/views/vehicle_detail_screen.dart';
import '../features/manager/views/map_overview_screen.dart';
import '../features/geofence/views/geofence_editor_screen.dart';
import '../features/alerts/views/alerts_screen.dart';
import '../features/reports/views/reports_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelector = '/role-selector';

  // Driver routes
  static const String driverHome = '/driver/home';
  static const String liveTracking = '/driver/tracking';
  static const String driverProfile = '/driver/profile';

  // Manager routes
  static const String dashboard = '/manager/dashboard';
  static const String vehicleDetail = '/manager/vehicle-detail';
  static const String mapOverview = '/manager/map';

  // Common routes
  static const String geofenceEditor = '/geofence-editor';
  static const String alerts = '/alerts';
  static const String reports = '/reports';
  static const String settings = '/settings';

  // Route pages
  static List<GetPage> routes = [
    // Splash and Auth
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: register,
      page: () => const RegisterScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: roleSelector,
      page: () => const RoleSelectorScreen(),
      transition: Transition.rightToLeft,
    ),

    // Driver Routes
    GetPage(
      name: driverHome,
      page: () => const DriverHomeScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: liveTracking,
      page: () => const LiveTrackingScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: driverProfile,
      page: () => const ProfileScreen(),
      transition: Transition.rightToLeft,
    ),

    // Manager Routes
    GetPage(
      name: dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: vehicleDetail,
      page: () => const VehicleDetailScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: mapOverview,
      page: () => const MapOverviewScreen(),
      transition: Transition.rightToLeft,
    ),

    // Common Routes
    GetPage(
      name: geofenceEditor,
      page: () => const GeofenceEditorScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: alerts,
      page: () => const AlertsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: reports,
      page: () => const ReportsScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}

// Splash Screen - temporary implementation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(seconds: 2));

    // Navigate to appropriate screen based on auth state
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Vehicle Tracking System',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
