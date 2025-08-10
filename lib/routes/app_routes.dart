import 'package:get/get.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/phone_auth_screen.dart';
import '../features/auth/otp_verification_screen.dart';
import '../features/auth/user_registration_screen.dart';
import '../app.dart';

class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String phoneAuth = '/phone-auth';
  static const String otpVerification = '/otp-verification';
  static const String userRegistration = '/user-registration';
  static const String register = '/register';
  static const String roleSelector = '/role-selector';
  static const String mainDashboard = '/main-dashboard';
  static const String driverHome = '/driver-home';
  static const String liveTracking = '/live-tracking';
  static const String driverProfile = '/driver-profile';
  static const String dashboard = '/dashboard';
  static const String vehicleDetail = '/vehicle-detail';
  static const String mapOverview = '/map-overview';
  static const String geofenceEditor = '/geofence-editor';
  static const String alerts = '/alerts';
  static const String reports = '/reports';
  static const String booking = '/booking';

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
      name: phoneAuth,
      page: () => const PhoneAuthScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: otpVerification,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        return OTPVerificationScreen(
          phoneNumber: args['phoneNumber'] ?? '',
          verificationId: args['verificationId'] ?? '',
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: userRegistration,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        return UserRegistrationScreen(
          phoneNumber: args['phoneNumber'] ?? '',
        );
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: mainDashboard,
      page: () => const MainDashboard(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: mapOverview,
      page: () => const MapPage(),
      transition: Transition.rightToLeft,
    ),
    // Note: Additional routes can be added here when the corresponding screens are implemented
    // GetPage(
    //   name: register,
    //   page: () => const RegisterScreen(),
    //   transition: Transition.rightToLeft,
    // ),
    // GetPage(
    //   name: roleSelector,
    //   page: () => const RoleSelectorScreen(),
    //   transition: Transition.rightToLeft,
    // ),
    // Driver Routes
    // GetPage(
    //   name: driverHome,
    //   page: () => const DriverHomeScreen(),
    //   transition: Transition.rightToLeft,
    // ),
    // GetPage(
    //   name: liveTracking,
    //   page: () => const LiveTrackingScreen(),
    //   transition: Transition.rightToLeft,
    // ),
    // GetPage(
    //   name: driverProfile,
    //   page: () => const ProfileScreen(),
    //   transition: Transition.rightToLeft,
    // ),
    // Manager Routes
    // GetPage(
    //   name: dashboard,
    //   page: () => const DashboardScreen(),
    //   transition: Transition.rightToLeft,
    // ),
    // GetPage(
    //   name: vehicleDetail,
    //   page: () => const VehicleDetailScreen(),
    //   transition: Transition.rightToLeft,
    // ),
    // GetPage(
    //   name: mapOverview,
    //   page: () => const MapOverviewScreen(),
    //   transition: Transition.rightToLeft,
    // ),
    // Common Routes
    // GetPage(
    //   name: geofenceEditor,
    //   page: () => const GeofenceEditorScreen(),
    //   transition: Transition.rightToLeft,
    // ),
    // GetPage(
    //   name: alerts,
    //   page: () => const AlertsScreen(),
    //   transition: Transition.rightToLeft,
    // ),
    // GetPage(
    //   name: reports,
    //   page: () => const ReportsScreen(),
    //   transition: Transition.rightToLeft,
    // ),
  ];

  // Convenience getter for pages
  static List<GetPage> get pages => routes;
}
