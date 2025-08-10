import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleStatus { active, inactive, maintenance, out_of_service }
enum VehicleType { car, bike, truck, bus, van, rickshaw }

class VehicleModel {
  final String id;
  final String licensePlate;
  final String make;
  final String model;
  final int year;
  final String? color;
  final VehicleType type;
  final VehicleStatus status;
  final String? vin;
  final String? engineDetails;
  final String? fuelType;
  final int? capacity;
  final double? mileage;
  final String? currentDriverId;
  final String? organizationId;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDate;
  final DateTime? registrationExpiry;
  final DateTime? insuranceExpiry;
  final double? fuelEfficiency;
  final Map<String, dynamic>? specifications;
  final List<String>? deviceIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  VehicleModel({
    required this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    this.color,
    required this.type,
    this.status = VehicleStatus.active,
    this.vin,
    this.engineDetails,
    this.fuelType,
    this.capacity,
    this.mileage,
    this.currentDriverId,
    this.organizationId,
    this.lastServiceDate,
    this.nextServiceDate,
    this.registrationExpiry,
    this.insuranceExpiry,
    this.fuelEfficiency,
    this.specifications,
    this.deviceIds,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return VehicleModel(
      id: id,
      licensePlate: map['licensePlate'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      color: map['color'],
      type: VehicleType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => VehicleType.car,
      ),
      status: VehicleStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => VehicleStatus.active,
      ),
      vin: map['vin'],
      engineDetails: map['engineDetails'],
      fuelType: map['fuelType'],
      capacity: map['capacity'],
      mileage: map['mileage']?.toDouble(),
      currentDriverId: map['currentDriverId'],
      organizationId: map['organizationId'],
      lastServiceDate: (map['lastServiceDate'] as Timestamp?)?.toDate(),
      nextServiceDate: (map['nextServiceDate'] as Timestamp?)?.toDate(),
      registrationExpiry: (map['registrationExpiry'] as Timestamp?)?.toDate(),
      insuranceExpiry: (map['insuranceExpiry'] as Timestamp?)?.toDate(),
      fuelEfficiency: map['fuelEfficiency']?.toDouble(),
      specifications: map['specifications']?.cast<String, dynamic>(),
      deviceIds: map['deviceIds']?.cast<String>(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VehicleModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'licensePlate': licensePlate,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'type': type.toString(),
      'status': status.toString(),
      'vin': vin,
      'engineDetails': engineDetails,
      'fuelType': fuelType,
      'capacity': capacity,
      'mileage': mileage,
      'currentDriverId': currentDriverId,
      'organizationId': organizationId,
      'lastServiceDate': lastServiceDate != null ? Timestamp.fromDate(lastServiceDate!) : null,
      'nextServiceDate': nextServiceDate != null ? Timestamp.fromDate(nextServiceDate!) : null,
      'registrationExpiry': registrationExpiry != null ? Timestamp.fromDate(registrationExpiry!) : null,
      'insuranceExpiry': insuranceExpiry != null ? Timestamp.fromDate(insuranceExpiry!) : null,
      'fuelEfficiency': fuelEfficiency,
      'specifications': specifications,
      'deviceIds': deviceIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  VehicleModel copyWith({
    String? licensePlate,
    String? make,
    String? model,
    int? year,
    String? color,
    VehicleType? type,
    VehicleStatus? status,
    String? vin,
    String? engineDetails,
    String? fuelType,
    int? capacity,
    double? mileage,
    String? currentDriverId,
    String? organizationId,
    DateTime? lastServiceDate,
    DateTime? nextServiceDate,
    DateTime? registrationExpiry,
    DateTime? insuranceExpiry,
    double? fuelEfficiency,
    Map<String, dynamic>? specifications,
    List<String>? deviceIds,
    bool? isActive,
  }) {
    return VehicleModel(
      id: id,
      licensePlate: licensePlate ?? this.licensePlate,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      type: type ?? this.type,
      status: status ?? this.status,
      vin: vin ?? this.vin,
      engineDetails: engineDetails ?? this.engineDetails,
      fuelType: fuelType ?? this.fuelType,
      capacity: capacity ?? this.capacity,
      mileage: mileage ?? this.mileage,
      currentDriverId: currentDriverId ?? this.currentDriverId,
      organizationId: organizationId ?? this.organizationId,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
      specifications: specifications ?? this.specifications,
      deviceIds: deviceIds ?? this.deviceIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper getters
  String get displayName => '$make $model ($year)';
  String get statusString => status.toString().split('.').last;
  String get typeString => type.toString().split('.').last;
  
  bool get needsService {
    if (nextServiceDate == null) return false;
    return DateTime.now().isAfter(nextServiceDate!);
  }
  
  bool get registrationExpired {
    if (registrationExpiry == null) return false;
    return DateTime.now().isAfter(registrationExpiry!);
  }
  
  bool get insuranceExpired {
    if (insuranceExpiry == null) return false;
    return DateTime.now().isAfter(insuranceExpiry!);
  }

  // Vadodara specific - Check if vehicle is suitable for city roads
  bool get isSuitableForVadodaraRoads {
    switch (type) {
      case VehicleType.car:
      case VehicleType.bike:
      case VehicleType.rickshaw:
        return true;
      case VehicleType.truck:
      case VehicleType.bus:
        return capacity != null && capacity! <= 50; // Smaller vehicles for city
      case VehicleType.van:
        return true;
    }
  }
}
