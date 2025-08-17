import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app.dart';
import '../login_screen.dart';

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
    super.onClose();
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
        _showSuccessSnackbar('Login Successful', result.message);
        _clearForm();
        // The AuthWrapper will automatically navigate to MainDashboard
        // when isLoggedIn becomes true
      } else {
        errorMessage.value = result.message;
        _showErrorSnackbar('Login Failed', result.message);
      }
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred';
      _showErrorSnackbar('Error', 'An unexpected error occurred: $e');
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
        _showSuccessSnackbar('Registration Successful', result.message);
        _clearForm();
        // Navigate to Main Dashboard after successful registration
        Get.offAll(() => const MainDashboard());
      } else {
        errorMessage.value = result.message;
        _showErrorSnackbar('Registration Failed', result.message);
      }
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred';
      _showErrorSnackbar('Error', 'An unexpected error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      _showErrorSnackbar('Error', 'Please enter your email address');
      return;
    }

    try {
      isLoading.value = true;
      
      final result = await _authService.resetPassword(emailController.text.trim());
      
      if (result.isSuccess) {
        _showSuccessSnackbar('Password Reset', result.message);
      } else {
        _showErrorSnackbar('Reset Failed', result.message);
      }
    } catch (e) {
      _showErrorSnackbar('Error', 'An unexpected error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _authService.logout();
      _clearForm();
      Get.offAll(() => const LoginScreen());
      _showSuccessSnackbar('Signed Out', 'You have been signed out successfully');
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to sign out: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFF6C5CE7),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  void _clearForm() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    nameController.clear();
    phoneController.clear();
    errorMessage.value = '';
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // Getters for user role checks
  bool get isDriver => _authService.currentUser?.role == AppConstants.roleDriver;
  bool get isManager => _authService.currentUser?.role == AppConstants.roleManager;
  bool get isAdmin => _authService.currentUser?.role == AppConstants.roleAdmin;

  // Validation methods
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!GetUtils.isPhoneNumber(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}