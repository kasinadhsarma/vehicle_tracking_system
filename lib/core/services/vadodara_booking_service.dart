import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import 'vadodara_pdf_service.dart';

enum BookingStatus {
  requesting,
  searching,
  driverFound,
  driverArriving,
  tripStarted,
  tripCompleted,
  cancelled,
}

enum VehicleType {
  auto('Auto Rickshaw', 'assets/icons/auto.png', 15.0),
  car('Car', 'assets/icons/car.png', 20.0),
  motorcycle('Motorcycle', 'assets/icons/bike.png', 10.0),
  taxi('Taxi', 'assets/icons/taxi.png', 25.0);

  const VehicleType(this.displayName, this.iconPath, this.baseFare);
  final String displayName;
  final String iconPath;
  final double baseFare;
}

class VadodaraBookingService extends ChangeNotifier {
  static VadodaraBookingService? _instance;
  static VadodaraBookingService get instance => _instance ??= VadodaraBookingService._();
  VadodaraBookingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VadodaraPDFService _pdfService = VadodaraPDFService.instance;

  // Current booking state
  BookingStatus _status = BookingStatus.requesting;
  String? _currentBookingId;
  Map<String, dynamic>? _currentDriver;
  Map<String, dynamic>? _currentVehicle;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  String? _pickupAddress;
  String? _destinationAddress;
  VehicleType _selectedVehicleType = VehicleType.auto;
  double _estimatedFare = 0.0;
  double _estimatedDistance = 0.0;
  int _estimatedTime = 0;
  
  // Trip data
  DateTime? _tripStartTime;
  DateTime? _tripEndTime;
  double _actualDistance = 0.0;
  double _actualFare = 0.0;
  String _paymentMethod = 'Cash';

  // Getters
  BookingStatus get status => _status;
  String? get currentBookingId => _currentBookingId;
  Map<String, dynamic>? get currentDriver => _currentDriver;
  Map<String, dynamic>? get currentVehicle => _currentVehicle;
  LatLng? get pickupLocation => _pickupLocation;
  LatLng? get destinationLocation => _destinationLocation;
  String? get pickupAddress => _pickupAddress;
  String? get destinationAddress => _destinationAddress;
  VehicleType get selectedVehicleType => _selectedVehicleType;
  double get estimatedFare => _estimatedFare;
  double get estimatedDistance => _estimatedDistance;
  int get estimatedTime => _estimatedTime;
  String get paymentMethod => _paymentMethod;

  // Set pickup location
  Future<void> setPickupLocation(LatLng location) async {
    _pickupLocation = location;
    _pickupAddress = await _getAddressFromLatLng(location);
    if (_destinationLocation != null) {
      await _calculateRoute();
    }
    notifyListeners();
  }

  // Set destination location
  Future<void> setDestinationLocation(LatLng location) async {
    _destinationLocation = location;
    _destinationAddress = await _getAddressFromLatLng(location);
    if (_pickupLocation != null) {
      await _calculateRoute();
    }
    notifyListeners();
  }

  // Set vehicle type
  void setVehicleType(VehicleType type) {
    _selectedVehicleType = type;
    if (_pickupLocation != null && _destinationLocation != null) {
      _calculateFare();
    }
    notifyListeners();
  }

  // Set payment method
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // Calculate route and fare
  Future<void> _calculateRoute() async {
    if (_pickupLocation == null || _destinationLocation == null) return;

    try {
      // Calculate distance using Haversine formula for demo
      _estimatedDistance = _calculateDistance(
        _pickupLocation!.latitude,
        _pickupLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );

      // Estimate time (assuming average speed of 25 km/h in Vadodara traffic)
      _estimatedTime = ((_estimatedDistance / 25.0) * 60).round();

      _calculateFare();
    } catch (e) {
      debugPrint('Error calculating route: $e');
    }
  }

  // Calculate fare based on distance and vehicle type
  void _calculateFare() {
    if (_estimatedDistance == 0) return;

    double baseFare = _selectedVehicleType.baseFare;
    double distanceCharge = _estimatedDistance * 12.0; // ₹12 per km
    double timeCharge = (_estimatedTime / 60.0) * 5.0; // ₹5 per minute

    // Vadodara specific surge pricing (demo)
    double surgeFactor = _getSurgeFactor();
    
    _estimatedFare = (baseFare + distanceCharge + timeCharge) * surgeFactor;
    
    // Round to nearest ₹5
    _estimatedFare = ((_estimatedFare / 5).round()) * 5.0;
  }

  // Get surge factor based on time and area
  double _getSurgeFactor() {
    final hour = DateTime.now().hour;
    
    // Peak hours in Vadodara: 8-10 AM, 5-8 PM
    if ((hour >= 8 && hour <= 10) || (hour >= 17 && hour <= 20)) {
      return 1.5; // 50% surge
    }
    
    // Night hours: 10 PM - 6 AM
    if (hour >= 22 || hour <= 6) {
      return 1.3; // 30% surge
    }
    
    return 1.0; // No surge
  }

  // Book a ride
  Future<bool> bookRide() async {
    if (_pickupLocation == null || _destinationLocation == null) {
      throw Exception('Please set both pickup and destination locations');
    }

    try {
      _status = BookingStatus.searching;
      notifyListeners();

      // Create booking in Firestore
      final bookingRef = await _firestore.collection('bookings').add({
        'userId': 'current_user_id', // Replace with actual user ID
        'pickupLat': _pickupLocation!.latitude,
        'pickupLng': _pickupLocation!.longitude,
        'pickupAddress': _pickupAddress,
        'destinationLat': _destinationLocation!.latitude,
        'destinationLng': _destinationLocation!.longitude,
        'destinationAddress': _destinationAddress,
        'vehicleType': _selectedVehicleType.name,
        'estimatedFare': _estimatedFare,
        'estimatedDistance': _estimatedDistance,
        'estimatedTime': _estimatedTime,
        'paymentMethod': _paymentMethod,
        'status': 'searching',
        'createdAt': Timestamp.now(),
        'operatingArea': 'Vadodara',
      });

      _currentBookingId = bookingRef.id;

      // Search for nearby drivers
      await _findNearbyDriver();

      return true;
    } catch (e) {
      debugPrint('Error booking ride: $e');
      _status = BookingStatus.requesting;
      notifyListeners();
      return false;
    }
  }

  // Find nearby driver (mock implementation)
  Future<void> _findNearbyDriver() async {
    // Simulate driver search
    await Future.delayed(const Duration(seconds: 3));

    // Mock driver data for Vadodara
    _currentDriver = {
      'id': 'driver_${DateTime.now().millisecondsSinceEpoch}',
      'name': 'Ramesh Patel',
      'phone': '+91 98765 43210',
      'rating': 4.8,
      'totalTrips': 1250,
      'photo': null,
      'currentLat': _pickupLocation!.latitude + (math.Random().nextDouble() - 0.5) * 0.01,
      'currentLng': _pickupLocation!.longitude + (math.Random().nextDouble() - 0.5) * 0.01,
    };

    _currentVehicle = {
      'number': 'GJ-06-AB-${1000 + math.Random().nextInt(9000)}',
      'type': _selectedVehicleType.name,
      'make': 'Maruti',
      'model': 'Alto',
      'color': 'White',
      'year': 2020,
    };

    _status = BookingStatus.driverFound;
    notifyListeners();

    // Update booking in Firestore
    if (_currentBookingId != null) {
      await _firestore.collection('bookings').doc(_currentBookingId).update({
        'driverId': _currentDriver!['id'],
        'driverName': _currentDriver!['name'],
        'driverPhone': _currentDriver!['phone'],
        'vehicleNumber': _currentVehicle!['number'],
        'status': 'driver_assigned',
        'assignedAt': Timestamp.now(),
      });
    }

    // Simulate driver arriving
    await Future.delayed(const Duration(seconds: 2));
    _status = BookingStatus.driverArriving;
    notifyListeners();
  }

  // Start trip
  Future<void> startTrip() async {
    _status = BookingStatus.tripStarted;
    _tripStartTime = DateTime.now();
    notifyListeners();

    // Update booking status
    if (_currentBookingId != null) {
      await _firestore.collection('bookings').doc(_currentBookingId).update({
        'status': 'trip_started',
        'tripStartTime': Timestamp.fromDate(_tripStartTime!),
      });
    }
  }

  // Complete trip
  Future<void> completeTrip() async {
    _tripEndTime = DateTime.now();
    _status = BookingStatus.tripCompleted;
    
    // Calculate actual fare (for demo, using estimated values)
    _actualDistance = _estimatedDistance;
    _actualFare = _estimatedFare;

    notifyListeners();

    // Update booking status
    if (_currentBookingId != null) {
      await _firestore.collection('bookings').doc(_currentBookingId).update({
        'status': 'completed',
        'tripEndTime': Timestamp.fromDate(_tripEndTime!),
        'actualDistance': _actualDistance,
        'actualFare': _actualFare,
        'completedAt': Timestamp.now(),
      });
    }
  }

  // Cancel booking
  Future<void> cancelBooking() async {
    _status = BookingStatus.cancelled;
    notifyListeners();

    if (_currentBookingId != null) {
      await _firestore.collection('bookings').doc(_currentBookingId).update({
        'status': 'cancelled',
        'cancelledAt': Timestamp.now(),
      });
    }

    _resetBooking();
  }

  // Generate trip receipt
  Future<void> generateTripReceipt() async {
    if (_currentBookingId == null || _currentDriver == null || _currentVehicle == null) {
      throw Exception('Trip data not available');
    }

    final tripData = {
      'tripId': _currentBookingId,
      'dateTime': _tripStartTime?.toString() ?? DateTime.now().toString(),
      'pickup': _pickupAddress ?? 'Unknown',
      'destination': _destinationAddress ?? 'Unknown',
      'distance': _actualDistance,
      'duration': _tripEndTime != null && _tripStartTime != null
          ? _tripEndTime!.difference(_tripStartTime!).inMinutes.toString() + ' min'
          : '${_estimatedTime} min',
      'baseFare': _selectedVehicleType.baseFare,
      'distanceCharge': _actualDistance * 12.0,
      'timeCharge': (_estimatedTime / 60.0) * 5.0,
      'tolls': 0,
      'taxes': _actualFare * 0.05, // 5% tax
      'totalAmount': _actualFare,
      'paymentMethod': _paymentMethod,
    };

    final pdfData = await _pdfService.generateTripReceipt(
      tripData: tripData,
      driverData: _currentDriver!,
      vehicleData: {
        'number': _currentVehicle!['number'],
        'type': _currentVehicle!['type'],
        'licensePlate': _currentVehicle!['number'],
      },
    );

    await _pdfService.sharePDF(pdfData, 'trip_receipt_${_currentBookingId}.pdf');
  }

  // Get available vehicle types for Vadodara
  List<VehicleType> getAvailableVehicleTypes() {
    return VehicleType.values;
  }

  // Reset booking state
  void _resetBooking() {
    _currentBookingId = null;
    _currentDriver = null;
    _currentVehicle = null;
    _tripStartTime = null;
    _tripEndTime = null;
    _status = BookingStatus.requesting;
  }

  // Get address from coordinates
  Future<String> _getAddressFromLatLng(LatLng location) async {
    try {
      // For demo, return mock Vadodara addresses
      final vadodaraAreas = [
        'Alkapuri, Vadodara',
        'Fatehgunj, Vadodara',
        'Sayajigunj, Vadodara',
        'Gotri, Vadodara',
        'Manjalpur, Vadodara',
        'Karelibaug, Vadodara',
        'Nizampura, Vadodara',
        'Productivity Road, Vadodara',
        'Race Course Circle, Vadodara',
        'Sursagar Lake, Vadodara',
      ];
      
      return vadodaraAreas[math.Random().nextInt(vadodaraAreas.length)];
    } catch (e) {
      return 'Vadodara, Gujarat';
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double lat1Rad = lat1 * (math.pi / 180);
    double lat2Rad = lat2 * (math.pi / 180);
    double deltaLat = (lat2 - lat1) * (math.pi / 180);
    double deltaLon = (lon2 - lon1) * (math.pi / 180);

    double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(deltaLon / 2) * math.sin(deltaLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Get trip history for current user
  Future<List<Map<String, dynamic>>> getTripHistory() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: 'current_user_id') // Replace with actual user ID
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting trip history: $e');
      return [];
    }
  }

  // Get estimated arrival time for driver
  int getDriverArrivalTime() {
    if (_currentDriver == null || _pickupLocation == null) return 0;
    
    // Calculate distance from driver to pickup
    double driverLat = _currentDriver!['currentLat'];
    double driverLng = _currentDriver!['currentLng'];
    
    double distance = _calculateDistance(
      driverLat,
      driverLng,
      _pickupLocation!.latitude,
      _pickupLocation!.longitude,
    );
    
    // Assume average speed of 20 km/h in city traffic
    return ((distance / 20.0) * 60).round(); // minutes
  }
}
