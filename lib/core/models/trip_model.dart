import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

enum TripStatus { active, completed, paused }

class TripModel {
  final String id;
  final String userId;
  final String vehicleId;
  final String? organizationId;
  final DateTime startTime;
  final DateTime? endTime;
  final TripStatus status;
  final double? totalDistance;
  final double? totalDuration;
  final LocationModel? startLocation;
  final LocationModel? endLocation;
  final List<LocationModel> waypoints;
  final String? routePolyline;
  final Map<String, dynamic>? driverScore;
  final Map<String, dynamic>? tripStats;
  final String? notes;

  // Additional computed properties for PDF generation
  double get maxSpeed {
    if (tripStats == null) return 0.0;
    return (tripStats!['maxSpeed'] as num?)?.toDouble() ?? 0.0;
  }

  double get averageSpeed {
    if (tripStats == null || totalDuration == null || totalDuration == 0) return 0.0;
    final distance = totalDistance ?? 0.0;
    final durationHours = totalDuration! / 3600; // Convert seconds to hours
    return durationHours > 0 ? distance / durationHours : 0.0;
  }

  double get fuelEfficiency {
    if (tripStats == null) return 15.0; // Default fuel efficiency
    return (tripStats!['fuelEfficiency'] as num?)?.toDouble() ?? 15.0;
  }

  List<LocationModel> get route => waypoints;

  String? get startLocationString => startLocation?.address ?? 
      '${startLocation?.latitude.toStringAsFixed(4)}, ${startLocation?.longitude.toStringAsFixed(4)}';

  String? get endLocationString => endLocation?.address ?? 
      '${endLocation?.latitude.toStringAsFixed(4)}, ${endLocation?.longitude.toStringAsFixed(4)}';

  TripModel({
    required this.id,
    required this.userId,
    required this.vehicleId,
    this.organizationId,
    required this.startTime,
    this.endTime,
    this.status = TripStatus.active,
    this.totalDistance,
    this.totalDuration,
    this.startLocation,
    this.endLocation,
    this.waypoints = const [],
    this.routePolyline,
    this.driverScore,
    this.tripStats,
    this.notes,
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      id: id,
      userId: map['userId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      organizationId: map['organizationId'],
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      status: _statusFromString(map['status'] ?? 'active'),
      totalDistance: map['totalDistance']?.toDouble(),
      totalDuration: map['totalDuration']?.toDouble(),
      startLocation: map['startLocation'] != null
          ? LocationModel.fromMap(map['startLocation'], '')
          : null,
      endLocation: map['endLocation'] != null
          ? LocationModel.fromMap(map['endLocation'], '')
          : null,
      waypoints:
          (map['waypoints'] as List<dynamic>?)
              ?.map((w) => LocationModel.fromMap(w, ''))
              .toList() ??
          [],
      routePolyline: map['routePolyline'],
      driverScore: map['driverScore'],
      tripStats: map['tripStats'],
      notes: map['notes'],
    );
  }

  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TripModel.fromMap(data, doc.id);
  }

  static TripStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return TripStatus.active;
      case 'completed':
        return TripStatus.completed;
      case 'paused':
        return TripStatus.paused;
      default:
        return TripStatus.active;
    }
  }

  static String _statusToString(TripStatus status) {
    switch (status) {
      case TripStatus.active:
        return 'active';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.paused:
        return 'paused';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'organizationId': organizationId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': _statusToString(status),
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'startLocation': startLocation?.toMap(),
      'endLocation': endLocation?.toMap(),
      'waypoints': waypoints.map((w) => w.toMap()).toList(),
      'routePolyline': routePolyline,
      'driverScore': driverScore,
      'tripStats': tripStats,
      'notes': notes,
    };
  }

  TripModel copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? organizationId,
    DateTime? startTime,
    DateTime? endTime,
    TripStatus? status,
    double? totalDistance,
    double? totalDuration,
    LocationModel? startLocation,
    LocationModel? endLocation,
    List<LocationModel>? waypoints,
    String? routePolyline,
    Map<String, dynamic>? driverScore,
    Map<String, dynamic>? tripStats,
    String? notes,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      organizationId: organizationId ?? this.organizationId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      waypoints: waypoints ?? this.waypoints,
      routePolyline: routePolyline ?? this.routePolyline,
      driverScore: driverScore ?? this.driverScore,
      tripStats: tripStats ?? this.tripStats,
      notes: notes ?? this.notes,
    );
  }

  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  bool get isActive => status == TripStatus.active;
  bool get isCompleted => status == TripStatus.completed;
  bool get isPaused => status == TripStatus.paused;

  String get statusDisplayName {
    switch (status) {
      case TripStatus.active:
        return 'Active';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.paused:
        return 'Paused';
    }
  }

  @override
  String toString() {
    return 'TripModel(id: $id, status: $status, startTime: $startTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
