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
