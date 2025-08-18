import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'features/auth/phone_auth_screen.dart';
import 'features/auth/otp_verification_screen.dart';
import 'features/auth/user_registration_screen.dart';
import 'features/dashboard/main_dashboard.dart';

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
        getPages: [
          GetPage(
            name: '/phone-auth',
            page: () => const PhoneAuthScreen(),
          ),
          GetPage(
            name: '/otp-verification',
            page: () {
              final args = Get.arguments as Map<String, dynamic>? ?? {};
              return OTPVerificationScreen(
                phoneNumber: args['phoneNumber'] ?? '',
                verificationId: args['verificationId'] ?? '',
              );
            },
          ),
          GetPage(
            name: '/user-registration',
            page: () {
              final args = Get.arguments as Map<String, dynamic>? ?? {};
              return UserRegistrationScreen(
                phoneNumber: args['phoneNumber'] ?? '',
              );
            },
          ),
          GetPage(
            name: '/dashboard',
            page: () => const MainDashboard(),
          ),
        ],
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
