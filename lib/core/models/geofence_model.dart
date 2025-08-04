import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

enum GeofenceType { circle, polygon }

class GeofenceModel {
  final String id;
  final String name;
  final String description;
  final String userId;
  final String? organizationId;
  final GeofenceType type;
  final List<GeoPoint> coordinates;
  final double? radius; // for circle type
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? rules;
  final String? color;

  GeofenceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    this.organizationId,
    required this.type,
    required this.coordinates,
    this.radius,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.rules,
    this.color,
  });

  factory GeofenceModel.fromMap(Map<String, dynamic> map, String id) {
    List<dynamic> coordsList = map['coordinates'] ?? [];
    List<GeoPoint> coords = coordsList.map((coord) {
      if (coord is GeoPoint) {
        return coord;
      } else if (coord is Map<String, dynamic>) {
        return GeoPoint(
          (coord['latitude'] ?? 0.0).toDouble(),
          (coord['longitude'] ?? 0.0).toDouble(),
        );
      }
      return GeoPoint(0.0, 0.0);
    }).toList();

    return GeofenceModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      organizationId: map['organizationId'],
      type: map['type'] == 'polygon'
          ? GeofenceType.polygon
          : GeofenceType.circle,
      coordinates: coords,
      radius: map['radius']?.toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rules: map['rules'],
      color: map['color'],
    );
  }

  factory GeofenceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GeofenceModel.fromMap(data, doc.id);
  }

  factory GeofenceModel.createCircle({
    required String name,
    required String description,
    required String userId,
    String? organizationId,
    required GeoPoint center,
    required double radius,
    bool isActive = true,
    Map<String, dynamic>? rules,
    String? color,
  }) {
    return GeofenceModel(
      id: '',
      name: name,
      description: description,
      userId: userId,
      organizationId: organizationId,
      type: GeofenceType.circle,
      coordinates: [center],
      radius: radius,
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      rules: rules,
      color: color,
    );
  }

  factory GeofenceModel.createPolygon({
    required String name,
    required String description,
    required String userId,
    String? organizationId,
    required List<GeoPoint> vertices,
    bool isActive = true,
    Map<String, dynamic>? rules,
    String? color,
  }) {
    return GeofenceModel(
      id: '',
      name: name,
      description: description,
      userId: userId,
      organizationId: organizationId,
      type: GeofenceType.polygon,
      coordinates: vertices,
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      rules: rules,
      color: color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'userId': userId,
      'organizationId': organizationId,
      'type': type == GeofenceType.circle ? 'circle' : 'polygon',
      'coordinates': coordinates,
      'radius': radius,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rules': rules,
      'color': color,
    };
  }

  bool containsPoint(GeoPoint point) {
    if (type == GeofenceType.circle) {
      return _isPointInCircle(point);
    } else {
      return _isPointInPolygon(point);
    }
  }

  bool _isPointInCircle(GeoPoint point) {
    if (coordinates.isEmpty || radius == null) return false;

    GeoPoint center = coordinates.first;
    double distance = _calculateDistance(center, point);
    return distance <= radius!;
  }

  bool _isPointInPolygon(GeoPoint point) {
    if (coordinates.length < 3) return false;

    int intersections = 0;
    for (int i = 0; i < coordinates.length; i++) {
      GeoPoint p1 = coordinates[i];
      GeoPoint p2 = coordinates[(i + 1) % coordinates.length];

      if (_rayIntersectsSegment(point, p1, p2)) {
        intersections++;
      }
    }

    return intersections % 2 == 1;
  }

  bool _rayIntersectsSegment(GeoPoint point, GeoPoint p1, GeoPoint p2) {
    double px = point.longitude;
    double py = point.latitude;
    double x1 = p1.longitude;
    double y1 = p1.latitude;
    double x2 = p2.longitude;
    double y2 = p2.latitude;

    if (y1 > py == y2 > py) return false;

    double slope = (x2 - x1) / (y2 - y1);
    double intersectX = x1 + slope * (py - y1);

    return intersectX > px;
  }

  double _calculateDistance(GeoPoint p1, GeoPoint p2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    double lat1Rad = p1.latitude * (math.pi / 180);
    double lat2Rad = p2.latitude * (math.pi / 180);
    double deltaLatRad = (p2.latitude - p1.latitude) * (math.pi / 180);
    double deltaLonRad = (p2.longitude - p1.longitude) * (math.pi / 180);

    double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLonRad / 2) *
            math.sin(deltaLonRad / 2);

    double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  GeoPoint get center {
    if (type == GeofenceType.circle) {
      return coordinates.first;
    } else {
      // Calculate centroid for polygon
      double lat = 0;
      double lng = 0;
      for (GeoPoint point in coordinates) {
        lat += point.latitude;
        lng += point.longitude;
      }
      return GeoPoint(lat / coordinates.length, lng / coordinates.length);
    }
  }

  GeofenceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? userId,
    String? organizationId,
    GeofenceType? type,
    List<GeoPoint>? coordinates,
    double? radius,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? rules,
    String? color,
  }) {
    return GeofenceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      type: type ?? this.type,
      coordinates: coordinates ?? this.coordinates,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rules: rules ?? this.rules,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'GeofenceModel(id: $id, name: $name, type: $type, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeofenceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
