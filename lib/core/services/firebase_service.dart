import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/foundation.dart';
import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../models/trip_model.dart';
import '../models/alert_model.dart';
import '../models/geofence_model.dart';

class FirebaseService extends ChangeNotifier {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  late FirebaseFirestore _firestore;
  late rtdb.FirebaseDatabase _realtimeDb;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      _realtimeDb = rtdb.FirebaseDatabase.instance;

      // Configure Firestore settings
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _isInitialized = true;
      debugPrint('Firebase services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      throw Exception('Failed to initialize Firebase services');
    }
  }

  // User Management
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set(user.toMap());
    } catch (e) {
      debugPrint('Error creating user: $e');
      throw Exception('Failed to create user');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      throw Exception('Failed to get user');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(data);
    } catch (e) {
      debugPrint('Error updating user: $e');
      throw Exception('Failed to update user');
    }
  }

  Future<List<UserModel>> getUsersByOrganization(String organizationId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('organizationId', isEqualTo: organizationId)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting users by organization: $e');
      throw Exception('Failed to get organization users');
    }
  }

  // Location Management
  Future<void> saveLocation(LocationModel location) async {
    try {
      // Save to Firestore for permanent storage
      await _firestore
          .collection(AppConstants.locationsCollection)
          .add(location.toMap());

      // Also save to Realtime Database for live tracking
      await _realtimeDb
          .ref('locations/${location.userId}')
          .set(location.toMap());
    } catch (e) {
      debugPrint('Error saving location: $e');
      throw Exception('Failed to save location');
    }
  }

  Stream<LocationModel?> getUserLocationStream(String userId) {
    return _realtimeDb.ref('locations/$userId').onValue.map((event) {
      if (event.snapshot.value != null) {
        Map<String, dynamic> data = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );
        return LocationModel.fromMap(data, '');
      }
      return null;
    });
  }

  Future<List<LocationModel>> getLocationHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.locationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting location history: $e');
      throw Exception('Failed to get location history');
    }
  }

  // Trip Management
  Future<String> createTrip(TripModel trip) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(AppConstants.tripsCollection)
          .add(trip.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating trip: $e');
      throw Exception('Failed to create trip');
    }
  }

  Future<void> updateTrip(String tripId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore
          .collection(AppConstants.tripsCollection)
          .doc(tripId)
          .update(data);
    } catch (e) {
      debugPrint('Error updating trip: $e');
      throw Exception('Failed to update trip');
    }
  }

  Future<TripModel?> getTrip(String tripId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.tripsCollection)
          .doc(tripId)
          .get();

      if (doc.exists) {
        return TripModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting trip: $e');
      throw Exception('Failed to get trip');
    }
  }

  Future<List<TripModel>> getUserTrips(
    String userId, {
    int? limit,
    TripStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.tripsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true);

      if (status != null) {
        String statusString = status == TripStatus.active
            ? 'active'
            : status == TripStatus.completed
            ? 'completed'
            : 'paused';
        query = query.where('status', isEqualTo: statusString);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user trips: $e');
      throw Exception('Failed to get user trips');
    }
  }

  // Alert Management
  Future<void> createAlert(AlertModel alert) async {
    try {
      await _firestore
          .collection(AppConstants.alertsCollection)
          .add(alert.toMap());
    } catch (e) {
      debugPrint('Error creating alert: $e');
      throw Exception('Failed to create alert');
    }
  }

  Future<List<AlertModel>> getUserAlerts(
    String userId, {
    int? limit,
    bool? isRead,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.alertsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (isRead != null) {
        query = query.where('isRead', isEqualTo: isRead);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user alerts: $e');
      throw Exception('Failed to get user alerts');
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _firestore
          .collection(AppConstants.alertsCollection)
          .doc(alertId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking alert as read: $e');
      throw Exception('Failed to mark alert as read');
    }
  }

  // Geofence Management
  Future<String> createGeofence(GeofenceModel geofence) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(AppConstants.geofencesCollection)
          .add(geofence.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating geofence: $e');
      throw Exception('Failed to create geofence');
    }
  }

  Future<void> updateGeofence(
    String geofenceId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore
          .collection(AppConstants.geofencesCollection)
          .doc(geofenceId)
          .update(data);
    } catch (e) {
      debugPrint('Error updating geofence: $e');
      throw Exception('Failed to update geofence');
    }
  }

  Future<void> deleteGeofence(String geofenceId) async {
    try {
      await _firestore
          .collection(AppConstants.geofencesCollection)
          .doc(geofenceId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting geofence: $e');
      throw Exception('Failed to delete geofence');
    }
  }

  Future<List<GeofenceModel>> getUserGeofences(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.geofencesCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => GeofenceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user geofences: $e');
      throw Exception('Failed to get user geofences');
    }
  }

  // Organization Management
  Future<List<UserModel>> getOrganizationDrivers(String organizationId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('organizationId', isEqualTo: organizationId)
          .where('role', isEqualTo: AppConstants.roleDriver)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting organization drivers: $e');
      throw Exception('Failed to get organization drivers');
    }
  }

  // Real-time streams
  Stream<List<UserModel>> getOrganizationUsersStream(String organizationId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<AlertModel>> getUserAlertsStream(String userId) {
    return _firestore
        .collection(AppConstants.alertsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AlertModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Utility methods
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var operation in operations) {
        String collection = operation['collection'];
        String? docId = operation['docId'];
        Map<String, dynamic> data = operation['data'];
        String type = operation['type']; // 'set', 'update', 'delete'

        DocumentReference docRef = docId != null
            ? _firestore.collection(collection).doc(docId)
            : _firestore.collection(collection).doc();

        switch (type) {
          case 'set':
            batch.set(docRef, data);
            break;
          case 'update':
            batch.update(docRef, data);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in batch write: $e');
      throw Exception('Failed to execute batch write');
    }
  }

  Future<void> cleanup() async {
    // Cleanup old location data, logs, etc.
    DateTime cutoffDate = DateTime.now().subtract(const Duration(days: 30));

    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .where('timestamp', isLessThan: cutoffDate)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint(
        'Cleanup completed: ${snapshot.docs.length} old records removed',
      );
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }
}
