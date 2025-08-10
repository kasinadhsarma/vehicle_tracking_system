import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

/// Enhanced Google Maps service for real-world vehicle tracking
/// Implements route optimization, geocoding, and advanced mapping features
class GoogleMapsService {
  static GoogleMapsService? _instance;
  static GoogleMapsService get instance => _instance ??= GoogleMapsService._();

  GoogleMapsService._();

  // API Configuration
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static const String _apiKey =
      'AIzaSyANV1A4ONRj7u-Ys9lt2MKNPI364lhjOM8'; // Updated API key

  // Cache for API responses
  final Map<String, dynamic> _geocodeCache = {};
  final Map<String, String> _routeCache = {};
  final Map<String, double> _speedLimitCache = {};

  // HTTP client for API calls
  late http.Client _httpClient;
  bool _isInitialized = false;

  // Public getters
  bool get isInitialized => _isInitialized;

  /// Initialize the Google Maps service
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      _httpClient = http.Client();
      _isInitialized = true;

      debugPrint('GoogleMapsService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('GoogleMapsService: Initialization failed: $e');
      return false;
    }
  }

  /// Dispose of all resources
  void dispose() {
    _httpClient.close();
    _isInitialized = false;
  }

  /// Get directions between two points
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    TravelMode travelMode = TravelMode.driving,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool optimizeWaypoints = false,
  }) async {
    try {
      if (!_isInitialized) {
        throw Exception('GoogleMapsService not initialized');
      }

      // Create cache key
      final cacheKey = _createDirectionsCacheKey(
        origin,
        destination,
        waypoints,
        travelMode,
        avoidTolls,
        avoidHighways,
      );

      // Check cache first
      if (_routeCache.containsKey(cacheKey)) {
        return DirectionsResult.fromEncodedPolyline(_routeCache[cacheKey]!);
      }

      // Build request URL
      final url = _buildDirectionsUrl(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        travelMode: travelMode,
        avoidTolls: avoidTolls,
        avoidHighways: avoidHighways,
        optimizeWaypoints: optimizeWaypoints,
      );

      // Make API call
      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final encodedPolyline = route['overview_polyline']['points'];

          // Cache the result
          _routeCache[cacheKey] = encodedPolyline;

          return DirectionsResult.fromApiResponse(data);
        } else {
          debugPrint(
            'GoogleMapsService: Directions API error: ${data['status']}',
          );
          return null;
        }
      } else {
        debugPrint('GoogleMapsService: HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('GoogleMapsService: Error getting directions: $e');
      return null;
    }
  }

  /// Get route polyline for trip visualization
  Future<List<LatLng>?> getRoutePolyline({
    required List<LocationModel> locations,
    bool snapToRoads = true,
  }) async {
    try {
      if (locations.length < 2) return null;

      if (snapToRoads) {
        // Use Snap to Roads API for high-quality route visualization
        return await _snapToRoads(locations);
      } else {
        // Simple polyline from raw coordinates
        return locations
            .map((loc) => LatLng(loc.latitude, loc.longitude))
            .toList();
      }
    } catch (e) {
      debugPrint('GoogleMapsService: Error getting route polyline: $e');
      return null;
    }
  }

  /// Snap coordinates to roads for accurate route visualization
  Future<List<LatLng>?> _snapToRoads(List<LocationModel> locations) async {
    try {
      // Batch locations in groups of 100 (API limit)
      const int batchSize = 100;
      List<LatLng> allSnappedPoints = [];

      for (int i = 0; i < locations.length; i += batchSize) {
        final end = (i + batchSize < locations.length)
            ? i + batchSize
            : locations.length;
        final batch = locations.sublist(i, end);

        final snappedBatch = await _snapBatchToRoads(batch);
        if (snappedBatch != null) {
          allSnappedPoints.addAll(snappedBatch);
        }
      }

      return allSnappedPoints.isNotEmpty ? allSnappedPoints : null;
    } catch (e) {
      debugPrint('GoogleMapsService: Error snapping to roads: $e');
      return null;
    }
  }

  Future<List<LatLng>?> _snapBatchToRoads(List<LocationModel> locations) async {
    try {
      // Build path parameter
      final path = locations
          .map((loc) => '${loc.latitude},${loc.longitude}')
          .join('|');

      final url =
          '$_baseUrl/snapToRoads/v1/snapToRoads'
          '?path=$path'
          '&interpolate=true'
          '&key=$_apiKey';

      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['snappedPoints'] != null) {
          return (data['snappedPoints'] as List)
              .map(
                (point) => LatLng(
                  point['location']['latitude'],
                  point['location']['longitude'],
                ),
              )
              .toList();
        }
      }

      return null;
    } catch (e) {
      debugPrint('GoogleMapsService: Error in snap batch: $e');
      return null;
    }
  }

  /// Get geocoding information for coordinates
  Future<GeocodeResult?> reverseGeocode(LatLng coordinates) async {
    try {
      final cacheKey = '${coordinates.latitude},${coordinates.longitude}';

      // Check cache first
      if (_geocodeCache.containsKey(cacheKey)) {
        return GeocodeResult.fromCache(_geocodeCache[cacheKey]);
      }

      final url =
          '$_baseUrl/geocode/json'
          '?latlng=${coordinates.latitude},${coordinates.longitude}'
          '&key=$_apiKey';

      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = GeocodeResult.fromApiResponse(data['results'][0]);

          // Cache the result
          _geocodeCache[cacheKey] = data['results'][0];

          return result;
        }
      }

      return null;
    } catch (e) {
      debugPrint('GoogleMapsService: Error in reverse geocoding: $e');
      return null;
    }
  }

  /// Get forward geocoding for address
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final url =
          '$_baseUrl/geocode/json'
          '?address=${Uri.encodeComponent(address)}'
          '&key=$_apiKey';

      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }

      return null;
    } catch (e) {
      debugPrint('GoogleMapsService: Error geocoding address: $e');
      return null;
    }
  }

  /// Get speed limit for a location
  Future<double?> getSpeedLimit(LatLng location) async {
    try {
      final cacheKey = '${location.latitude},${location.longitude}';

      // Check cache first
      if (_speedLimitCache.containsKey(cacheKey)) {
        return _speedLimitCache[cacheKey];
      }

      final url =
          '$_baseUrl/roads/v1/speedLimits'
          '?path=${location.latitude},${location.longitude}'
          '&key=$_apiKey';

      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['speedLimits'] != null && data['speedLimits'].isNotEmpty) {
          final speedLimit = data['speedLimits'][0]['speedLimit'].toDouble();

          // Cache the result
          _speedLimitCache[cacheKey] = speedLimit;

          return speedLimit;
        }
      }

      return null;
    } catch (e) {
      debugPrint('GoogleMapsService: Error getting speed limit: $e');
      return null;
    }
  }

  /// Get nearest roads information
  Future<List<RoadInfo>?> getNearestRoads(
    LatLng location, {
    double radius = 50,
  }) async {
    try {
      final url =
          '$_baseUrl/roads/v1/nearestRoads'
          '?points=${location.latitude},${location.longitude}'
          '&key=$_apiKey';

      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['snappedPoints'] != null) {
          return (data['snappedPoints'] as List)
              .map((point) => RoadInfo.fromApiResponse(point))
              .toList();
        }
      }

      return null;
    } catch (e) {
      debugPrint('GoogleMapsService: Error getting nearest roads: $e');
      return null;
    }
  }

  /// Calculate estimated travel time between points
  Future<Duration?> getEstimatedTravelTime({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
    DateTime? departureTime,
  }) async {
    try {
      var url =
          '$_baseUrl/distancematrix/json'
          '?origins=${origin.latitude},${origin.longitude}'
          '&destinations=${destination.latitude},${destination.longitude}'
          '&mode=${travelMode.toString().toLowerCase()}'
          '&key=$_apiKey';

      if (departureTime != null) {
        url +=
            '&departure_time=${departureTime.millisecondsSinceEpoch ~/ 1000}';
      }

      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['rows'].isNotEmpty &&
            data['rows'][0]['elements'].isNotEmpty) {
          final element = data['rows'][0]['elements'][0];

          if (element['status'] == 'OK' && element['duration'] != null) {
            return Duration(seconds: element['duration']['value']);
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('GoogleMapsService: Error getting travel time: $e');
      return null;
    }
  }

  /// Clear all caches
  void clearCaches() {
    _geocodeCache.clear();
    _routeCache.clear();
    _speedLimitCache.clear();
  }

  // Private helper methods

  String _buildDirectionsUrl({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    required TravelMode travelMode,
    required bool avoidTolls,
    required bool avoidHighways,
    required bool optimizeWaypoints,
  }) {
    var url =
        '$_baseUrl/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=${travelMode.toString().toLowerCase()}'
        '&key=$_apiKey';

    if (waypoints != null && waypoints.isNotEmpty) {
      final waypointsStr = waypoints
          .map((wp) => '${wp.latitude},${wp.longitude}')
          .join('|');

      url += '&waypoints=';
      if (optimizeWaypoints) {
        url += 'optimize:true|';
      }
      url += waypointsStr;
    }

    if (avoidTolls || avoidHighways) {
      final avoid = <String>[];
      if (avoidTolls) avoid.add('tolls');
      if (avoidHighways) avoid.add('highways');
      url += '&avoid=${avoid.join('|')}';
    }

    return url;
  }

  String _createDirectionsCacheKey(
    LatLng origin,
    LatLng destination,
    List<LatLng>? waypoints,
    TravelMode travelMode,
    bool avoidTolls,
    bool avoidHighways,
  ) {
    final wayStr =
        waypoints?.map((w) => '${w.latitude},${w.longitude}').join('|') ?? '';
    return '${origin.latitude},${origin.longitude}->'
        '${destination.latitude},${destination.longitude}|'
        '$wayStr|$travelMode|$avoidTolls|$avoidHighways';
  }
}

// Enums
enum TravelMode { driving, walking, bicycling, transit }

// Data classes
class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String encodedPolyline;
  final Duration duration;
  final double distance;
  final String summary;
  final List<RouteStep> steps;

  DirectionsResult({
    required this.polylinePoints,
    required this.encodedPolyline,
    required this.duration,
    required this.distance,
    required this.summary,
    required this.steps,
  });

  factory DirectionsResult.fromEncodedPolyline(String encoded) {
    return DirectionsResult(
      polylinePoints: _decodePolyline(encoded),
      encodedPolyline: encoded,
      duration: Duration.zero,
      distance: 0.0,
      summary: '',
      steps: [],
    );
  }

  factory DirectionsResult.fromApiResponse(Map<String, dynamic> data) {
    final route = data['routes'][0];
    final leg = route['legs'][0];
    final polyline = route['overview_polyline']['points'];

    return DirectionsResult(
      polylinePoints: _decodePolyline(polyline),
      encodedPolyline: polyline,
      duration: Duration(seconds: leg['duration']['value']),
      distance: leg['distance']['value'].toDouble(),
      summary: route['summary'] ?? '',
      steps: (leg['steps'] as List)
          .map((step) => RouteStep.fromApiResponse(step))
          .toList(),
    );
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }
}

class RouteStep {
  final String instruction;
  final Duration duration;
  final double distance;
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver;

  RouteStep({
    required this.instruction,
    required this.duration,
    required this.distance,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
  });

  factory RouteStep.fromApiResponse(Map<String, dynamic> data) {
    return RouteStep(
      instruction: data['html_instructions'] ?? '',
      duration: Duration(seconds: data['duration']['value']),
      distance: data['distance']['value'].toDouble(),
      startLocation: LatLng(
        data['start_location']['lat'],
        data['start_location']['lng'],
      ),
      endLocation: LatLng(
        data['end_location']['lat'],
        data['end_location']['lng'],
      ),
      maneuver: data['maneuver'] ?? '',
    );
  }
}

class GeocodeResult {
  final String formattedAddress;
  final String streetNumber;
  final String route;
  final String locality;
  final String administrativeArea;
  final String country;
  final String postalCode;
  final LatLng location;

  GeocodeResult({
    required this.formattedAddress,
    required this.streetNumber,
    required this.route,
    required this.locality,
    required this.administrativeArea,
    required this.country,
    required this.postalCode,
    required this.location,
  });

  factory GeocodeResult.fromCache(Map<String, dynamic> data) {
    return GeocodeResult.fromApiResponse(data);
  }

  factory GeocodeResult.fromApiResponse(Map<String, dynamic> data) {
    final components = data['address_components'] as List;

    String streetNumber = '';
    String route = '';
    String locality = '';
    String administrativeArea = '';
    String country = '';
    String postalCode = '';

    for (final component in components) {
      final types = component['types'] as List;

      if (types.contains('street_number')) {
        streetNumber = component['long_name'];
      } else if (types.contains('route')) {
        route = component['long_name'];
      } else if (types.contains('locality')) {
        locality = component['long_name'];
      } else if (types.contains('administrative_area_level_1')) {
        administrativeArea = component['long_name'];
      } else if (types.contains('country')) {
        country = component['long_name'];
      } else if (types.contains('postal_code')) {
        postalCode = component['long_name'];
      }
    }

    return GeocodeResult(
      formattedAddress: data['formatted_address'],
      streetNumber: streetNumber,
      route: route,
      locality: locality,
      administrativeArea: administrativeArea,
      country: country,
      postalCode: postalCode,
      location: LatLng(
        data['geometry']['location']['lat'],
        data['geometry']['location']['lng'],
      ),
    );
  }
}

class RoadInfo {
  final String placeId;
  final LatLng location;
  final double speedLimit;

  RoadInfo({
    required this.placeId,
    required this.location,
    required this.speedLimit,
  });

  factory RoadInfo.fromApiResponse(Map<String, dynamic> data) {
    return RoadInfo(
      placeId: data['placeId'] ?? '',
      location: LatLng(
        data['location']['latitude'],
        data['location']['longitude'],
      ),
      speedLimit: (data['speedLimit'] ?? 0).toDouble(),
    );
  }
}
