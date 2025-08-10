import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../constants/app_colors.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  UserModel? _currentUserModel;
  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;

  User? get currentUser => _currentUser;
  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get verificationId => _verificationId;

  AuthService() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _auth.authStateChanges().listen((User? user) async {
      _currentUser = user;
      if (user != null) {
        await _loadUserModel();
      } else {
        _currentUserModel = null;
        await _clearLocalStorage();
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserModel() async {
    if (_currentUser == null) return;

    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        _currentUserModel = UserModel.fromFirestore(doc);
        await _saveToLocalStorage();
      }
    } catch (e) {
      debugPrint('Error loading user model: $e');
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? organizationId,
  }) async {
    try {
      _setLoading(true);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        UserModel userModel = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          phone: phone,
          role: role,
          organizationId: organizationId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(result.user!.uid)
            .set(userModel.toMap());

        // Update display name
        await result.user!.updateDisplayName(name);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _auth.signOut();
      await _clearLocalStorage();
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Failed to sign out');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null || _currentUserModel == null) return;

    try {
      _setLoading(true);

      Map<String, dynamic> updates = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) {
        updates['name'] = name;
        await _currentUser!.updateDisplayName(name);
      }
      if (phone != null) updates['phone'] = phone;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.uid)
          .update(updates);

      await _loadUserModel();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: currentPassword,
      );
      await _currentUser!.reauthenticateWithCredential(credential);

      // Update password
      await _currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount(String password) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: password,
      );
      await _currentUser!.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.uid)
          .delete();

      // Delete Firebase Auth account
      await _currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      _setLoading(false);
    }
  }

  // Phone Authentication Methods
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      _setLoading(true);
      
      // Format phone number for India (+91)
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        if (phoneNumber.startsWith('91')) {
          formattedPhone = '+$phoneNumber';
        } else if (phoneNumber.length == 10) {
          formattedPhone = '+91$phoneNumber';
        } else {
          formattedPhone = '+91$phoneNumber';
        }
      }
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      debugPrint('Error verifying phone number: $e');
      throw Exception('Failed to verify phone number');
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> signInWithPhoneNumber({
    required String smsCode,
    String? verificationId,
  }) async {
    try {
      _setLoading(true);
      
      String vidToUse = verificationId ?? _verificationId ?? '';
      if (vidToUse.isEmpty) {
        throw Exception('Verification ID not found. Please request OTP again.');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: vidToUse,
        smsCode: smsCode,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      
      // Check if user exists in Firestore, if not create a new user record
      if (result.user != null) {
        await _checkAndCreateUserRecord(result.user!);
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> registerWithPhoneNumber({
    required String smsCode,
    required String name,
    required String role,
    String? email,
    String? organizationId,
    String? verificationId,
  }) async {
    try {
      _setLoading(true);
      
      String vidToUse = verificationId ?? _verificationId ?? '';
      if (vidToUse.isEmpty) {
        throw Exception('Verification ID not found. Please request OTP again.');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: vidToUse,
        smsCode: smsCode,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        // Create user record in Firestore
        UserModel userModel = UserModel(
          id: result.user!.uid,
          email: email ?? '',
          name: name,
          phone: result.user!.phoneNumber ?? '',
          role: role,
          organizationId: organizationId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(result.user!.uid)
            .set(userModel.toMap());

        // Update display name
        await result.user!.updateDisplayName(name);
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _checkAndCreateUserRecord(User user) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Create a default user record for phone auth users
        UserModel userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'User',
          phone: user.phoneNumber ?? '',
          role: AppConstants.roleConsumer, // Default role
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(userModel.toMap());
      }
    } catch (e) {
      debugPrint('Error checking/creating user record: $e');
    }
  }

  // Vadodara-specific location services
  Future<bool> isInVadodara(double latitude, double longitude) async {
    // Vadodara city bounds (approximate)
    const double vadodaraMinLat = 22.2500;
    const double vadodaraMaxLat = 22.3500;
    const double vadodaraMinLng = 73.1000;
    const double vadodaraMaxLng = 73.2500;
    
    return latitude >= vadodaraMinLat && 
           latitude <= vadodaraMaxLat &&
           longitude >= vadodaraMinLng && 
           longitude <= vadodaraMaxLng;
  }

  /// Register vehicle with phone number
  Future<bool> registerVehicleWithPhone({
    required String phoneNumber,
    required String vehicleNumber,
    required String driverName,
    required String vehicleType,
    String? licenseNumber,
  }) async {
    try {
      _setLoading(true);
      
      if (_currentUser == null) {
        throw Exception('User must be logged in to register vehicle');
      }

      // Format vehicle number for Gujarat
      String formattedVehicleNumber = vehicleNumber.toUpperCase();
      if (!formattedVehicleNumber.startsWith('GJ-')) {
        formattedVehicleNumber = 'GJ-06-$formattedVehicleNumber';
      }

      // Create vehicle record in Firestore
      final vehicleData = {
        'vehicleNumber': formattedVehicleNumber,
        'driverName': driverName,
        'driverPhone': phoneNumber,
        'vehicleType': vehicleType,
        'licenseNumber': licenseNumber,
        'ownerId': _currentUser!.uid,
        'isActive': true,
        'registeredAt': Timestamp.fromDate(DateTime.now()),
        'lastLocation': null,
        'status': 'offline',
        'operatingArea': 'Vadodara, Gujarat',
      };

      await _firestore
          .collection('vehicles')
          .doc(formattedVehicleNumber)
          .set(vehicleData);

      debugPrint('Vehicle registered: $formattedVehicleNumber');
      return true;
    } catch (e) {
      debugPrint('Error registering vehicle: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get user's registered vehicles
  Future<List<Map<String, dynamic>>> getUserVehicles() async {
    try {
      if (_currentUser == null) return [];

      final snapshot = await _firestore
          .collection('vehicles')
          .where('ownerId', isEqualTo: _currentUser!.uid)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting user vehicles: $e');
      return [];
    }
  }

  Future<void> _saveToLocalStorage() async {
    if (_currentUserModel == null) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, _currentUserModel!.id);
      await prefs.setString(AppConstants.keyUserRole, _currentUserModel!.role);
      await prefs.setString(
        AppConstants.keyOrganizationId,
        _currentUserModel!.organizationId ?? '',
      );
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  Future<void> _clearLocalStorage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyUserRole);
      await prefs.remove(AppConstants.keyOrganizationId);
      await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    } catch (e) {
      debugPrint('Error clearing local storage: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper methods for role checking
  bool get isDriver => _currentUserModel?.role == AppConstants.roleDriver;
  bool get isManager => _currentUserModel?.role == AppConstants.roleManager;
  bool get isAdmin => _currentUserModel?.role == AppConstants.roleAdmin;
  bool get isConsumer => _currentUserModel?.role == AppConstants.roleConsumer;

  bool hasRole(String role) => _currentUserModel?.role == role;

  bool get hasOrganization =>
      _currentUserModel?.organizationId != null &&
      _currentUserModel!.organizationId!.isNotEmpty;
}
