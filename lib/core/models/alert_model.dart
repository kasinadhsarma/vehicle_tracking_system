import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType {
  geofence,
  speeding,
  harshBraking,
  harshAcceleration,
  harshCornering,
  deviceOffline,
  maintenance,
  custom,
}

enum AlertSeverity { low, medium, high, critical }

class AlertModel {
  final String id;
  final String userId;
  final String? vehicleId;
  final String? tripId;
  final String? organizationId;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? notes;

  AlertModel({
    required this.id,
    required this.userId,
    this.vehicleId,
    this.tripId,
    this.organizationId,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.metadata,
    this.isRead = false,
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
    this.notes,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    return AlertModel(
      id: id,
      userId: map['userId'] ?? '',
      vehicleId: map['vehicleId'],
      tripId: map['tripId'],
      organizationId: map['organizationId'],
      type: _typeFromString(map['type'] ?? 'custom'),
      severity: _severityFromString(map['severity'] ?? 'low'),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
      isRead: map['isRead'] ?? false,
      isResolved: map['isResolved'] ?? false,
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: map['resolvedBy'],
      notes: map['notes'],
    );
  }

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AlertModel.fromMap(data, doc.id);
  }

  static AlertType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'geofence':
        return AlertType.geofence;
      case 'speeding':
        return AlertType.speeding;
      case 'harsh_braking':
        return AlertType.harshBraking;
      case 'harsh_acceleration':
        return AlertType.harshAcceleration;
      case 'harsh_cornering':
        return AlertType.harshCornering;
      case 'device_offline':
        return AlertType.deviceOffline;
      case 'maintenance':
        return AlertType.maintenance;
      default:
        return AlertType.custom;
    }
  }

  static String _typeToString(AlertType type) {
    switch (type) {
      case AlertType.geofence:
        return 'geofence';
      case AlertType.speeding:
        return 'speeding';
      case AlertType.harshBraking:
        return 'harsh_braking';
      case AlertType.harshAcceleration:
        return 'harsh_acceleration';
      case AlertType.harshCornering:
        return 'harsh_cornering';
      case AlertType.deviceOffline:
        return 'device_offline';
      case AlertType.maintenance:
        return 'maintenance';
      case AlertType.custom:
        return 'custom';
    }
  }

  static AlertSeverity _severityFromString(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return AlertSeverity.low;
      case 'medium':
        return AlertSeverity.medium;
      case 'high':
        return AlertSeverity.high;
      case 'critical':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.low;
    }
  }

  static String _severityToString(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'low';
      case AlertSeverity.medium:
        return 'medium';
      case AlertSeverity.high:
        return 'high';
      case AlertSeverity.critical:
        return 'critical';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'tripId': tripId,
      'organizationId': organizationId,
      'type': _typeToString(type),
      'severity': _severityToString(severity),
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'isRead': isRead,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'notes': notes,
    };
  }

  AlertModel copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? tripId,
    String? organizationId,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    bool? isRead,
    bool? isResolved,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? notes,
  }) {
    return AlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      tripId: tripId ?? this.tripId,
      organizationId: organizationId ?? this.organizationId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      notes: notes ?? this.notes,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case AlertType.geofence:
        return 'Geofence Violation';
      case AlertType.speeding:
        return 'Speeding';
      case AlertType.harshBraking:
        return 'Harsh Braking';
      case AlertType.harshAcceleration:
        return 'Harsh Acceleration';
      case AlertType.harshCornering:
        return 'Harsh Cornering';
      case AlertType.deviceOffline:
        return 'Device Offline';
      case AlertType.maintenance:
        return 'Maintenance Required';
      case AlertType.custom:
        return 'Custom Alert';
    }
  }

  String get severityDisplayName {
    switch (severity) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  @override
  String toString() {
    return 'AlertModel(id: $id, type: $type, severity: $severity, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlertModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
