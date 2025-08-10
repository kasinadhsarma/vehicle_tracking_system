import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../app.dart';

class AuthController extends GetxController {
  final SimpleAuthService _authService = Get.put(SimpleAuthService());

  // Observables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  // Form keys
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();

  // Selected role for registration
  final Rx<String> selectedRole = AppConstants.roleDriver.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    ever(_authService.isLoggedInStream, _handleAuthStateChange);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _handleAuthStateChange(bool isLoggedIn) {
    if (isLoggedIn) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    final user = _authService.currentUser;
    if (user != null) {
      // Navigate based on user role if needed
      debugPrint('User ${user.name} logged in with role: ${user.role}');
    }
  }

  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _authService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (result.isSuccess) {
        Get.snackbar(
          'Success',
          result.message,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
        _clearForm();
        // Navigate to Main Dashboard after successful login
        Get.offAll(() => const MainDashboard());
      } else {
        errorMessage.value = result.message;
        Get.snackbar(
          'Login Failed',
          result.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred';
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _authService.register(
        email: emailController.text.trim(),
        password: passwordController.text,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        role: selectedRole.value,
      );

      if (result.isSuccess) {
        Get.snackbar(
          'Success',
          result.message,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
        _clearForm();
        // Navigate to Main Dashboard after successful registration
        Get.offAll(() => const MainDashboard());
      } else {
        errorMessage.value = result.message;
        Get.snackbar(
          'Registration Failed',
          result.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred';
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _authService.logout();
      
      Get.snackbar(
        'Logged Out',
        'You have been successfully logged out.',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.logout, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    try {
      isLoading.value = true;
      
      final result = await _authService.resetPassword(emailController.text.trim());
      
      if (result.isSuccess) {
        Get.snackbar(
          'Email Sent',
          result.message,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          icon: const Icon(Icons.email, color: Colors.white),
        );
      } else {
        Get.snackbar(
          'Error',
          result.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send reset email: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _clearForm() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    nameController.clear();
    phoneController.clear();
    errorMessage.value = '';
    isPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
  }

  // Role checking helpers
  bool get isDriver => _authService.currentUser?.role == AppConstants.roleDriver;
  bool get isManager => _authService.currentUser?.role == AppConstants.roleManager;
  bool get isAdmin => _authService.currentUser?.role == AppConstants.roleAdmin;
  bool get isAuthenticated => _authService.isLoggedIn;
}
