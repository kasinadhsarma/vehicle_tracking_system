import 'package:flutter/foundation.dart';

/// Configuration for Google Maps API
class MapsConfig {
  // Google Maps API key from Google Cloud Console
  // Get your API key from: https://console.cloud.google.com/
  // 1. Create/Select project
  // 2. Enable Maps JavaScript API
  // 3. Go to Credentials > Create API Key
  // 4. Restrict the key for security (optional but recommended)
  
  static const String _developmentApiKey = 'AIzaSyANV1A4ONRj7u-Ys9lt2MKNPI364lhjOM8';
  static const String _productionApiKey = 'AIzaSyANV1A4ONRj7u-Ys9lt2MKNPI364lhjOM8';
  
  /// Get the appropriate API key based on environment
  static String get apiKey {
    if (kDebugMode) {
      return _developmentApiKey;
    } else {
      return _productionApiKey;
    }
  }
  
  /// Check if API key is configured
  static bool get isConfigured {
    return apiKey != 'YOUR_DEVELOPMENT_API_KEY_HERE' && 
           apiKey != 'YOUR_PRODUCTION_API_KEY_HERE' &&
           apiKey.isNotEmpty;
  }
  
  /// Default map center (Vadodara, Gujarat, India)
  static const double defaultLatitude = 22.3072;
  static const double defaultLongitude = 73.1812;
  
  /// Default zoom level
  static const double defaultZoom = 13.0;
}
