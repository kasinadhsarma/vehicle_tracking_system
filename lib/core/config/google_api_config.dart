import 'package:flutter/foundation.dart';

/// Google API configuration for the vehicle tracking system
class GoogleApiConfig {
  // Google Maps API Keys for different platforms
  static const String _androidApiKey = 'AIzaSyANV1A4ONRj7u-Ys9lt2MKNPI364lhjOM8';
  static const String _iosApiKey = 'AIzaSyANV1A4ONRj7u-Ys9lt2MKNPI364lhjOM8';
  static const String _webApiKey = 'AIzaSyANV1A4ONRj7u-Ys9lt2MKNPI364lhjOM8';

  /// Get the appropriate Google Maps API key for the current platform
  static String get googleMapsApiKey {
    if (kIsWeb) {
      return _webApiKey;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidApiKey;
      case TargetPlatform.iOS:
        return _iosApiKey;
      default:
        return _androidApiKey; // Fallback to Android key
    }
  }

  /// Vadodara-specific configuration
  static const Map<String, dynamic> vadodaraConfig = {
    'cityName': 'Vadodara',
    'cityBounds': {
      'northeast': {'lat': 22.3500, 'lng': 73.2500},
      'southwest': {'lat': 22.2500, 'lng': 73.1000},
    },
    'defaultCenter': {'lat': 22.3072, 'lng': 73.1812},
    'defaultZoom': 12.0,
    'searchRadius': 50000, // 50km radius for vehicle search
  };

  /// Google Places API configuration for Vadodara
  static const Map<String, String> placesConfig = {
    'language': 'en',
    'region': 'IN',
    'types': 'establishment|point_of_interest|transit_station',
  };

  /// Geocoding API configuration
  static const Map<String, String> geocodingConfig = {
    'language': 'en',
    'region': 'IN',
    'components': 'administrative_area:Gujarat|locality:Vadodara',
  };

  /// Routes API configuration for Ola/Uber-like features
  static const Map<String, dynamic> routesConfig = {
    'avoid': ['tolls'], // Avoid tolls by default for cost-effective routes
    'units': 'metric',
    'language': 'en',
    'region': 'IN',
    'departure_time': 'now',
    'traffic_model': 'best_guess',
  };

  /// Get formatted API URL for Google Maps Static API
  static String getStaticMapUrl({
    required double lat,
    required double lng,
    int zoom = 15,
    String mapType = 'roadmap',
    String size = '400x400',
    List<String>? markers,
  }) {
    String baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';
    String url = '$baseUrl?center=$lat,$lng&zoom=$zoom&size=$size&maptype=$mapType&key=$googleMapsApiKey';
    
    if (markers != null && markers.isNotEmpty) {
      for (String marker in markers) {
        url += '&markers=$marker';
      }
    }
    
    return url;
  }

  /// Get formatted URL for Google Places API
  static String getPlacesUrl({
    required String query,
    double? lat,
    double? lng,
    int radius = 5000,
  }) {
    String baseUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json';
    String url = '$baseUrl?query=$query&key=$googleMapsApiKey';
    
    if (lat != null && lng != null) {
      url += '&location=$lat,$lng&radius=$radius';
    }
    
    // Add Vadodara-specific components
    url += '&region=${geocodingConfig['region']}';
    url += '&language=${geocodingConfig['language']}';
    
    return url;
  }

  /// Get formatted URL for Google Geocoding API
  static String getGeocodingUrl({
    String? address,
    double? lat,
    double? lng,
  }) {
    String baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
    String url = '$baseUrl?key=$googleMapsApiKey';
    
    if (address != null) {
      url += '&address=${Uri.encodeComponent(address)}';
      // Add Vadodara component for better local results
      url += '&components=${geocodingConfig['components']}';
    } else if (lat != null && lng != null) {
      url += '&latlng=$lat,$lng';
    }
    
    url += '&language=${geocodingConfig['language']}';
    url += '&region=${geocodingConfig['region']}';
    
    return url;
  }

  /// Get formatted URL for Google Directions API
  static String getDirectionsUrl({
    required String origin,
    required String destination,
    String mode = 'driving',
    List<String>? waypoints,
    bool optimizeWaypoints = true,
    String avoid = 'tolls',
  }) {
    String baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
    String url = '$baseUrl?origin=${Uri.encodeComponent(origin)}';
    url += '&destination=${Uri.encodeComponent(destination)}';
    url += '&mode=$mode';
    url += '&key=$googleMapsApiKey';
    
    if (waypoints != null && waypoints.isNotEmpty) {
      if (optimizeWaypoints) {
        url += '&waypoints=optimize:true|${waypoints.join('|')}';
      } else {
        url += '&waypoints=${waypoints.join('|')}';
      }
    }
    
    url += '&avoid=$avoid';
    url += '&language=${routesConfig['language']}';
    url += '&region=${routesConfig['region']}';
    url += '&units=${routesConfig['units']}';
    
    return url;
  }

  /// Check if coordinates are within Vadodara bounds
  static bool isWithinVadodara(double lat, double lng) {
    final bounds = vadodaraConfig['cityBounds'] as Map<String, dynamic>;
    final northeast = bounds['northeast'] as Map<String, double>;
    final southwest = bounds['southwest'] as Map<String, double>;
    
    return lat >= southwest['lat']! && 
           lat <= northeast['lat']! &&
           lng >= southwest['lng']! && 
           lng <= northeast['lng']!;
  }

  /// Get Vadodara city center coordinates
  static Map<String, double> get vadodaraCityCenter {
    return vadodaraConfig['defaultCenter'] as Map<String, double>;
  }

  /// Get default zoom level for Vadodara
  static double get vadodaraDefaultZoom {
    return vadodaraConfig['defaultZoom'] as double;
  }
}
