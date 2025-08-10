import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'auth_service.dart';
import 'google_maps_service.dart';

/// Vehicle booking service for Ola/Uber-like functionality
class VehicleBookingService {
  static VehicleBookingService? _instance;
  static VehicleBookingService get instance => _instance ??= VehicleBookingService._();

  VehicleBookingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleMapsService _mapsService = GoogleMapsService.instance;
  final AuthService _authService = AuthService();

  // Stream controllers for real-time updates
  final StreamController<BookingStatus> _bookingStatusController = 
      StreamController<BookingStatus>.broadcast();
  final StreamController<DriverLocation> _driverLocationController = 
      StreamController<DriverLocation>.broadcast();

  Stream<BookingStatus> get bookingStatusStream => _bookingStatusController.stream;
  Stream<DriverLocation> get driverLocationStream => _driverLocationController.stream;

  /// Book a vehicle for ride
  Future<BookingResult> bookVehicle({
    required String pickupAddress,
    required String dropAddress,
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    required String vehicleType,
    String? specialRequests,
    bool isScheduled = false,
    DateTime? scheduledTime,
  }) async {
    try {
      if (_authService.currentUser == null) {
        return BookingResult(
          success: false,
          message: 'Please login to book a vehicle',
        );
      }

      // Check if pickup is in Vadodara
      if (!_isInVadodara(pickupLat, pickupLng)) {
        return BookingResult(
          success: false,
          message: 'Pickup location must be within Vadodara city limits',
        );
      }

      // Get route information
      final routeResult = await _mapsService.getDirections(
        origin: LatLng(pickupLat, pickupLng),
        destination: LatLng(dropLat, dropLng),
      );

      if (routeResult == null) {
        return BookingResult(
          success: false,
          message: 'Unable to find route to destination',
        );
      }

      // Convert DirectionsResult to routeInfo map for compatibility
      final routeInfo = {
        'distance': '${(routeResult.distance / 1000).toStringAsFixed(1)} km',
        'duration': '${routeResult.duration.inMinutes} min',
        'distanceValue': routeResult.distance.toInt(), // distance in meters
        'durationValue': routeResult.duration.inSeconds, // duration in seconds
      };

      // Find available drivers
      final availableDrivers = await _findAvailableDrivers(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        vehicleType: vehicleType,
      );

      if (availableDrivers.isEmpty) {
        return BookingResult(
          success: false,
          message: 'No drivers available in your area. Please try again later.',
        );
      }

      // Calculate fare
      final fareDetails = _calculateFare(
        distance: (routeInfo['distanceValue'] as int) / 1000.0, // Convert to km
        duration: (routeInfo['durationValue'] as int) / 60.0, // Convert to minutes
        vehicleType: vehicleType,
        isScheduled: isScheduled,
      );

      // Create booking
      final booking = VehicleBooking(
        id: _generateBookingId(),
        customerId: _authService.currentUser!.uid,
        customerName: _authService.currentUserModel?.name ?? 'Customer',
        customerPhone: _authService.currentUserModel?.phone ?? '',
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        pickupLocation: GeoPoint(pickupLat, pickupLng),
        dropLocation: GeoPoint(dropLat, dropLng),
        vehicleType: vehicleType,
        fareDetails: fareDetails,
        routeInfo: routeInfo,
        specialRequests: specialRequests,
        isScheduled: isScheduled,
        scheduledTime: scheduledTime,
        status: BookingStatus.searching,
        createdAt: DateTime.now(),
      );

      // Save booking to Firestore
      await _firestore
          .collection('bookings')
          .doc(booking.id)
          .set(booking.toMap());

      // Assign driver (simplified - in real app, this would be more complex)
      final assignedDriver = availableDrivers.first;
      await _assignDriverToBooking(booking.id, assignedDriver);

      return BookingResult(
        success: true,
        message: 'Booking created successfully',
        bookingId: booking.id,
        estimatedFare: fareDetails['totalFare'] as int,
        estimatedTime: routeInfo['duration'] as String,
      );

    } catch (e) {
      debugPrint('Error booking vehicle: $e');
      return BookingResult(
        success: false,
        message: 'Failed to create booking. Please try again.',
      );
    }
  }

  /// Get booking details
  Future<VehicleBooking?> getBookingDetails(String bookingId) async {
    try {
      final doc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (doc.exists) {
        return VehicleBooking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting booking details: $e');
      return null;
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId, String reason) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': BookingStatus.cancelled.toString(),
        'cancellationReason': reason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
      });

      _bookingStatusController.add(BookingStatus.cancelled);
      return true;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      return false;
    }
  }

  /// Get user's booking history
  Future<List<VehicleBooking>> getBookingHistory({
    int limit = 20,
    String? lastBookingId,
  }) async {
    try {
      if (_authService.currentUser == null) return [];

      Query query = _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: _authService.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastBookingId != null) {
        final lastDoc = await _firestore
            .collection('bookings')
            .doc(lastBookingId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => VehicleBooking.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting booking history: $e');
      return [];
    }
  }

  /// Track booking real-time
  Stream<VehicleBooking?> trackBooking(String bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return VehicleBooking.fromFirestore(snapshot);
      }
      return null;
    });
  }

  /// Get available vehicle types with pricing
  List<VehicleTypeInfo> getAvailableVehicleTypes() {
    return [
      VehicleTypeInfo(
        type: 'hatchback',
        name: 'Hatchback',
        description: 'Comfortable rides for up to 4 people',
        capacity: 4,
        baseFare: 35,
        perKmRate: 10,
        perMinuteRate: 1.0,
        estimatedArrival: '3-5 mins',
        icon: '🚗',
      ),
      VehicleTypeInfo(
        type: 'sedan',
        name: 'Sedan',
        description: 'Premium comfort for up to 4 people',
        capacity: 4,
        baseFare: 45,
        perKmRate: 12,
        perMinuteRate: 1.5,
        estimatedArrival: '4-6 mins',
        icon: '🚙',
      ),
      VehicleTypeInfo(
        type: 'suv',
        name: 'SUV',
        description: 'Spacious rides for up to 6 people',
        capacity: 6,
        baseFare: 65,
        perKmRate: 15,
        perMinuteRate: 2.0,
        estimatedArrival: '5-8 mins',
        icon: '🚐',
      ),
      VehicleTypeInfo(
        type: 'auto',
        name: 'Auto Rickshaw',
        description: 'Quick and affordable rides for up to 3 people',
        capacity: 3,
        baseFare: 25,
        perKmRate: 8,
        perMinuteRate: 0.5,
        estimatedArrival: '2-4 mins',
        icon: '🛺',
      ),
    ];
  }

  /// Find available drivers near pickup location
  Future<List<DriverInfo>> _findAvailableDrivers({
    required double pickupLat,
    required double pickupLng,
    required String vehicleType,
    double radiusKm = 5.0,
  }) async {
    try {
      // In a real app, you'd query actual driver locations
      // For demo, we'll simulate available drivers in Vadodara
      if (!_isInVadodara(pickupLat, pickupLng)) {
        return [];
      }

      // Simulate finding drivers
      final List<DriverInfo> drivers = [
        DriverInfo(
          driverId: 'DRV001',
          name: 'Rajesh Patel',
          phone: '+91 98765 43210',
          vehicleNumber: 'GJ-06-AB-1234',
          vehicleType: vehicleType,
          rating: 4.5,
          location: GeoPoint(pickupLat + 0.001, pickupLng + 0.001),
          distanceKm: 0.2,
          isAvailable: true,
        ),
        DriverInfo(
          driverId: 'DRV002',
          name: 'Amit Shah',
          phone: '+91 98765 43211',
          vehicleNumber: 'GJ-06-CD-5678',
          vehicleType: vehicleType,
          rating: 4.2,
          location: GeoPoint(pickupLat - 0.002, pickupLng + 0.001),
          distanceKm: 0.4,
          isAvailable: true,
        ),
      ];

      return drivers.where((driver) => 
          driver.vehicleType == vehicleType && 
          driver.isAvailable &&
          driver.distanceKm <= radiusKm
      ).toList();
    } catch (e) {
      debugPrint('Error finding available drivers: $e');
      return [];
    }
  }

  /// Assign driver to booking
  Future<void> _assignDriverToBooking(String bookingId, DriverInfo driver) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
        'driverId': driver.driverId,
        'driverName': driver.name,
        'driverPhone': driver.phone,
        'vehicleNumber': driver.vehicleNumber,
        'driverRating': driver.rating,
        'status': BookingStatus.confirmed.toString(),
        'estimatedArrival': DateTime.now().add(Duration(
          minutes: (driver.distanceKm * 2).round(), // Estimate based on distance
        )).toIso8601String(),
      });

      _bookingStatusController.add(BookingStatus.confirmed);
    } catch (e) {
      debugPrint('Error assigning driver: $e');
    }
  }

  /// Calculate fare based on distance, time, and vehicle type
  Map<String, dynamic> _calculateFare({
    required double distance, // in km
    required double duration, // in minutes
    required String vehicleType,
    bool isScheduled = false,
  }) {
    final vehicleTypes = getAvailableVehicleTypes();
    final vehicleInfo = vehicleTypes.firstWhere(
      (v) => v.type == vehicleType,
      orElse: () => vehicleTypes.first,
    );

    double baseFare = vehicleInfo.baseFare.toDouble();
    double distanceFare = distance * vehicleInfo.perKmRate;
    double timeFare = duration * vehicleInfo.perMinuteRate;

    // Add surge pricing for peak hours
    double surgeFactor = _getSurgeFactor();
    double surgeAmount = (distanceFare + timeFare) * (surgeFactor - 1);

    // Add scheduling fee if applicable
    double schedulingFee = isScheduled ? 20.0 : 0.0;

    double subtotal = baseFare + distanceFare + timeFare + surgeAmount + schedulingFee;
    double gst = subtotal * 0.05; // 5% GST
    double totalFare = subtotal + gst;

    return {
      'baseFare': baseFare.round(),
      'distanceFare': distanceFare.round(),
      'timeFare': timeFare.round(),
      'surgeAmount': surgeAmount.round(),
      'surgeFactor': surgeFactor,
      'schedulingFee': schedulingFee.round(),
      'subtotal': subtotal.round(),
      'gst': gst.round(),
      'totalFare': totalFare.round(),
      'currency': 'INR',
    };
  }

  /// Get surge pricing factor based on time and demand
  double _getSurgeFactor() {
    final now = DateTime.now();
    final hour = now.hour;

    // Peak hours: 8-10 AM and 6-9 PM
    if ((hour >= 8 && hour <= 10) || (hour >= 18 && hour <= 21)) {
      return 1.5; // 50% surge
    }
    // Moderate hours: 7-8 AM, 10-11 AM, 5-6 PM, 9-10 PM
    else if ((hour >= 7 && hour <= 11) || (hour >= 17 && hour <= 22)) {
      return 1.2; // 20% surge
    }
    // Normal hours
    else {
      return 1.0; // No surge
    }
  }

  /// Generate unique booking ID
  String _generateBookingId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'VTS${timestamp.toString().substring(8)}$random';
  }

  /// Check if location is within Vadodara
  bool _isInVadodara(double lat, double lng) {
    // Vadodara city bounds
    return lat >= 22.2500 && lat <= 22.3500 && 
           lng >= 73.1000 && lng <= 73.2500;
  }

  /// Dispose resources
  void dispose() {
    _bookingStatusController.close();
    _driverLocationController.close();
  }
}

// Data classes
class VehicleBooking {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String pickupAddress;
  final String dropAddress;
  final GeoPoint pickupLocation;
  final GeoPoint dropLocation;
  final String vehicleType;
  final Map<String, dynamic> fareDetails;
  final Map<String, dynamic> routeInfo;
  final String? specialRequests;
  final bool isScheduled;
  final DateTime? scheduledTime;
  final BookingStatus status;
  final DateTime createdAt;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;
  final double? driverRating;

  VehicleBooking({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupLocation,
    required this.dropLocation,
    required this.vehicleType,
    required this.fareDetails,
    required this.routeInfo,
    this.specialRequests,
    required this.isScheduled,
    this.scheduledTime,
    required this.status,
    required this.createdAt,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
    this.driverRating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'vehicleType': vehicleType,
      'fareDetails': fareDetails,
      'routeInfo': routeInfo,
      'specialRequests': specialRequests,
      'isScheduled': isScheduled,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleNumber': vehicleNumber,
      'driverRating': driverRating,
    };
  }

  factory VehicleBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleBooking(
      id: data['id'],
      customerId: data['customerId'],
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      pickupAddress: data['pickupAddress'],
      dropAddress: data['dropAddress'],
      pickupLocation: data['pickupLocation'],
      dropLocation: data['dropLocation'],
      vehicleType: data['vehicleType'],
      fareDetails: data['fareDetails'],
      routeInfo: data['routeInfo'],
      specialRequests: data['specialRequests'],
      isScheduled: data['isScheduled'],
      scheduledTime: data['scheduledTime'] != null 
          ? DateTime.parse(data['scheduledTime']) 
          : null,
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => BookingStatus.searching,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      vehicleNumber: data['vehicleNumber'],
      driverRating: data['driverRating']?.toDouble(),
    );
  }
}

class BookingResult {
  final bool success;
  final String message;
  final String? bookingId;
  final int? estimatedFare;
  final String? estimatedTime;

  BookingResult({
    required this.success,
    required this.message,
    this.bookingId,
    this.estimatedFare,
    this.estimatedTime,
  });
}

class VehicleTypeInfo {
  final String type;
  final String name;
  final String description;
  final int capacity;
  final int baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final String estimatedArrival;
  final String icon;

  VehicleTypeInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.capacity,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.estimatedArrival,
    required this.icon,
  });
}

class DriverInfo {
  final String driverId;
  final String name;
  final String phone;
  final String vehicleNumber;
  final String vehicleType;
  final double rating;
  final GeoPoint location;
  final double distanceKm;
  final bool isAvailable;

  DriverInfo({
    required this.driverId,
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.rating,
    required this.location,
    required this.distanceKm,
    required this.isAvailable,
  });
}

class DriverLocation {
  final String driverId;
  final double lat;
  final double lng;
  final DateTime timestamp;

  DriverLocation({
    required this.driverId,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });
}

enum BookingStatus {
  searching,
  confirmed,
  driverAssigned,
  driverArriving,
  tripStarted,
  tripCompleted,
  cancelled,
}
