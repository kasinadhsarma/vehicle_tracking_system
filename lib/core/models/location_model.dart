import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class LocationModel {
  final String id;
  final String userId;
  final String? vehicleId;
  final String? driverId;
  final String? tripId;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final String? address;
  final Map<String, dynamic>? sensorData;
  final String? geohash;

  LocationModel({
    required this.id,
    required this.userId,
    this.vehicleId,
    this.driverId,
    this.tripId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
    this.address,
    this.sensorData,
    this.geohash,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map, String id) {
    return LocationModel(
      id: id,
      userId: map['userId'] ?? '',
      vehicleId: map['vehicleId'],
      driverId: map['driverId'],
      tripId: map['tripId'],
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      altitude: map['altitude']?.toDouble(),
      accuracy: map['accuracy']?.toDouble(),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: map['address'],
      sensorData: map['sensorData'],
      geohash: map['geohash'],
    );
  }

  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LocationModel.fromMap(data, doc.id);
  }

  factory LocationModel.fromGeoPoint(
    GeoPoint geoPoint,
    String userId, {
    String? vehicleId,
    String? driverId,
    String? tripId,
    double? speed,
    double? heading,
    double? accuracy,
    Map<String, dynamic>? sensorData,
  }) {
    return LocationModel(
      id: '',
      userId: userId,
      vehicleId: vehicleId,
      driverId: driverId,
      tripId: tripId,
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      speed: speed,
      heading: heading,
      accuracy: accuracy,
      timestamp: DateTime.now(),
      sensorData: sensorData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'tripId': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'timestamp': Timestamp.fromDate(timestamp),
      'address': address,
      'sensorData': sensorData,
      'geohash': geohash,
      'coordinates': GeoPoint(latitude, longitude),
    };
  }

  GeoPoint get geoPoint => GeoPoint(latitude, longitude);

  LocationModel copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? driverId,
    String? tripId,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    double? speed,
    double? heading,
    DateTime? timestamp,
    String? address,
    Map<String, dynamic>? sensorData,
    String? geohash,
  }) {
    return LocationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      tripId: tripId ?? this.tripId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      sensorData: sensorData ?? this.sensorData,
      geohash: geohash ?? this.geohash,
    );
  }

  double distanceTo(LocationModel other) {
    // Simple distance calculation using Haversine formula
    const double earthRadius = 6371000; // Earth's radius in meters
    double lat1Rad = latitude * (math.pi / 180);
    double lat2Rad = other.latitude * (math.pi / 180);
    double deltaLatRad = (other.latitude - latitude) * (math.pi / 180);
    double deltaLonRad = (other.longitude - longitude) * (math.pi / 180);

    double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLonRad / 2) *
            math.sin(deltaLonRad / 2);

    double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  @override
  String toString() {
    return 'LocationModel(id: $id, lat: $latitude, lng: $longitude, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
