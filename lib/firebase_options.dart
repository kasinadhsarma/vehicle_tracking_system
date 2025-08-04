import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCHGKlQgQkm9p3Zm7xJjO3pFYC8-XdUx_s',
    appId: '1:372855430234:web:8f2e2f3c4a5b6789012345',
    messagingSenderId: '372855430234',
    projectId: 'vehicle-tracking-system-f4934',
    authDomain: 'vehicle-tracking-system-f4934.firebaseapp.com',
    storageBucket: 'vehicle-tracking-system-f4934.appspot.com',
    measurementId: 'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCHGKlQgQkm9p3Zm7xJjO3pFYC8-XdUx_s',
    appId: '1:372855430234:android:8f2e2f3c4a5b6789012345',
    messagingSenderId: '372855430234',
    projectId: 'vehicle-tracking-system-f4934',
    storageBucket: 'vehicle-tracking-system-f4934.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCHGKlQgQkm9p3Zm7xJjO3pFYC8-XdUx_s',
    appId: '1:372855430234:ios:8f2e2f3c4a5b6789012345',
    messagingSenderId: '372855430234',
    projectId: 'vehicle-tracking-system-f4934',
    storageBucket: 'vehicle-tracking-system-f4934.appspot.com',
    iosBundleId: 'com.example.vehicleTrackingSystem',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCHGKlQgQkm9p3Zm7xJjO3pFYC8-XdUx_s',
    appId: '1:372855430234:macos:8f2e2f3c4a5b6789012345',
    messagingSenderId: '372855430234',
    projectId: 'vehicle-tracking-system-f4934',
    storageBucket: 'vehicle-tracking-system-f4934.appspot.com',
    iosBundleId: 'com.example.vehicleTrackingSystem',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAZ9-Yp3hZwJ6rFJ5yx3Gw3Y8Kb0C8zJ0o',
    appId: '1:123456789012:web:abc123def456ghi789',
    messagingSenderId: '123456789012',
    projectId: 'vehicle-tracking-system-f4934',
    authDomain: 'vehicle-tracking-system-f4934.firebaseapp.com',
    storageBucket: 'vehicle-tracking-system-f4934.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyAZ9-Yp3hZwJ6rFJ5yx3Gw3Y8Kb0C8zJ0o',
    appId: '1:123456789012:web:abc123def456ghi789',
    messagingSenderId: '123456789012',
    projectId: 'vehicle-tracking-system-f4934',
    authDomain: 'vehicle-tracking-system-f4934.firebaseapp.com',
    storageBucket: 'vehicle-tracking-system-f4934.appspot.com',
  );
}
