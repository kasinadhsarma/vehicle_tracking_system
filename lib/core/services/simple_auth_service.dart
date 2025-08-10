import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class SimpleAuthService extends GetxService {
  // Observable state
  final RxBool _isLoading = false.obs;
  final RxBool _isLoggedIn = false.obs;
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isLoggedIn => _isLoggedIn.value;
  UserModel? get currentUser => _currentUser.value;
  RxBool get isLoggedInStream => _isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    // Check if user was previously logged in
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // For demo purposes, we'll just set logged out initially
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoggedIn.value = false;
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      _isLoading.value = true;
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Demo credentials for easy testing
      final validCredentials = [
        {'email': 'admin@vts.com', 'password': 'admin123', 'role': AppConstants.roleAdmin},
        {'email': 'manager@vts.com', 'password': 'manager123', 'role': AppConstants.roleManager},
        {'email': 'driver@vts.com', 'password': 'driver123', 'role': AppConstants.roleDriver},
        {'email': 'test@test.com', 'password': '123456', 'role': AppConstants.roleDriver},
      ];

      // Check credentials
      bool isValidUser = false;
      String userRole = AppConstants.roleDriver;
      
      for (var cred in validCredentials) {
        if (cred['email'] == email && cred['password'] == password) {
          isValidUser = true;
          userRole = cred['role'] as String;
          break;
        }
      }

      // Also accept any email/password combination for demo purposes
      if (!isValidUser && email.isNotEmpty && password.isNotEmpty && password.length >= 3) {
        isValidUser = true;
        userRole = _determineRoleFromEmail(email);
      }

      if (isValidUser) {
        final user = UserModel(
          id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: _extractNameFromEmail(email),
          role: userRole,
          phone: '+1234567890',
          organizationId: 'demo_org',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _currentUser.value = user;
        _isLoggedIn.value = true;
        
        return AuthResult.success('Login successful');
      } else {
        return AuthResult.error('Invalid email or password');
      }
    } catch (e) {
      return AuthResult.error('Login failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      _isLoading.value = true;
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final user = UserModel(
        id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        role: role,
        phone: phone,
        organizationId: 'demo_org',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _currentUser.value = user;
      _isLoggedIn.value = true;
      
      return AuthResult.success('Registration successful');
    } catch (e) {
      return AuthResult.error('Registration failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading.value = true;
      
      // Simulate logout process
      await Future.delayed(const Duration(seconds: 1));
      
      _currentUser.value = null;
      _isLoggedIn.value = false;
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      _isLoading.value = true;
      
      // Simulate password reset
      await Future.delayed(const Duration(seconds: 1));
      
      return AuthResult.success('Password reset email sent');
    } catch (e) {
      return AuthResult.error('Password reset failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  String _extractNameFromEmail(String email) {
    final username = email.split('@').first;
    final parts = username.split('.');
    if (parts.length >= 2) {
      return '${parts[0].capitalizeFirst} ${parts[1].capitalizeFirst}';
    }
    return username.capitalizeFirst ?? 'User';
  }

  String _determineRoleFromEmail(String email) {
    if (email.toLowerCase().contains('admin')) {
      return AppConstants.roleAdmin;
    } else if (email.toLowerCase().contains('manager')) {
      return AppConstants.roleManager;
    } else {
      return AppConstants.roleDriver;
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final String message;
  final dynamic data;

  AuthResult.success(this.message, {this.data}) : isSuccess = true;
  AuthResult.error(this.message, {this.data}) : isSuccess = false;
}
