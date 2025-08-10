import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/tracking_service_factory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Only initialize Firebase on supported platforms
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows)) {
      debugPrint(
        'Running on desktop platform - Firebase initialization skipped',
      );
      // Initialize services without Firebase for desktop MVP
      await _initializeServicesForDesktop();
    } else {
      // Initialize Firebase for supported platforms
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _initializeServices();
    }
  } catch (e) {
    debugPrint('Initialization error: $e');
    // Fallback to desktop mode
    await _initializeServicesForDesktop();
  }

  runApp(VehicleTrackingApp());
}

Future<void> _initializeServices() async {
  // Register services with GetX for Firebase-enabled platforms
  try {
    // Initialize basic services only for now
    debugPrint('Services initialized successfully');
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
}

Future<void> _initializeServicesForDesktop() async {
  // Initialize local services for desktop MVP
  debugPrint('Desktop services initialized');
  
  // Initialize the tracking service factory
  await TrackingServiceFactory.instance.initializeTrackingService();
}
