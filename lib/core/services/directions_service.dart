import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Service for handling Google Maps Directions API
class DirectionsService {
  static DirectionsService? _instance;
  static DirectionsService get instance => _instance ??= DirectionsService._();

  DirectionsService._();

  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static const String _apiKey = 'AIzaSyANV1A4ONRj7u-Ys9lt2MKNPI364lhjOM8';

  /// Get directions between two points
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    String travelMode = 'driving',
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) async {
    try {
      String waypointsStr = '';
      if (waypoints != null && waypoints.isNotEmpty) {
        waypointsStr = '&waypoints=' +
            waypoints.map((w) => '${w.latitude},${w.longitude}').join('|');
      }

      String avoid = '';
      if (avoidTolls || avoidHighways) {
        List<String> avoidList = [];
        if (avoidTolls) avoidList.add('tolls');
        if (avoidHighways) avoidList.add('highways');
        avoid = '&avoid=${avoidList.join('|')}';
      }

      final url = '$_baseUrl/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '$waypointsStr'
          '&mode=$travelMode'
          '$avoid'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return DirectionsResult.fromJson(data['routes'][0]);
        } else {
          debugPrint('Directions API error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting directions: $e');
      return null;
    }
  }

  /// Decode polyline string to List of LatLng
  static List<LatLng> decodePolyline(String polyline) {
    List<LatLng> coordinates = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      coordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return coordinates;
  }
}

/// Directions result model
class DirectionsResult {
  final String summary;
  final String duration;
  final String distance;
  final List<LatLng> polylinePoints;
  final List<DirectionStep> steps;
  final LatLng startLocation;
  final LatLng endLocation;

  DirectionsResult({
    required this.summary,
    required this.duration,
    required this.distance,
    required this.polylinePoints,
    required this.steps,
    required this.startLocation,
    required this.endLocation,
  });

  factory DirectionsResult.fromJson(Map<String, dynamic> json) {
    final leg = json['legs'][0];
    final polylinePoints = DirectionsService.decodePolyline(
      json['overview_polyline']['points'],
    );

    List<DirectionStep> steps = [];
    if (leg['steps'] != null) {
      for (var step in leg['steps']) {
        steps.add(DirectionStep.fromJson(step));
      }
    }

    return DirectionsResult(
      summary: json['summary'] ?? '',
      duration: leg['duration']['text'] ?? '',
      distance: leg['distance']['text'] ?? '',
      polylinePoints: polylinePoints,
      steps: steps,
      startLocation: LatLng(
        leg['start_location']['lat'],
        leg['start_location']['lng'],
      ),
      endLocation: LatLng(
        leg['end_location']['lat'],
        leg['end_location']['lng'],
      ),
    );
  }
}

/// Individual direction step
class DirectionStep {
  final String instructions;
  final String duration;
  final String distance;
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver;

  DirectionStep({
    required this.instructions,
    required this.duration,
    required this.distance,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
  });

  factory DirectionStep.fromJson(Map<String, dynamic> json) {
    return DirectionStep(
      instructions: json['html_instructions'] ?? '',
      duration: json['duration']['text'] ?? '',
      distance: json['distance']['text'] ?? '',
      startLocation: LatLng(
        json['start_location']['lat'],
        json['start_location']['lng'],
      ),
      endLocation: LatLng(
        json['end_location']['lat'],
        json['end_location']['lng'],
      ),
      maneuver: json['maneuver'] ?? '',
    );
  }

  /// Get icon for maneuver
  IconData get maneuverIcon {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'straight':
        return Icons.straight;
      case 'ramp-left':
        return Icons.ramp_left;
      case 'ramp-right':
        return Icons.ramp_right;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
      case 'fork-right':
        return Icons.call_split;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      default:
        return Icons.navigation;
    }
  }
}
