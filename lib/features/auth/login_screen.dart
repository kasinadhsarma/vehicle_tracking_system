import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/controllers/theme_controller.dart';
import '../../app.dart';
import 'controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final AuthController _authController = Get.put(AuthController());
  bool _isLoginMode = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => themeController.toggleTheme(),
        child: Obx(() => Icon(themeController.themeIcon)),
        tooltip: 'Toggle Theme',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.primaryGradientDark
              : AppGradients.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    elevation: 20,
                    shadowColor: Colors.black.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildForm(),
                          const SizedBox(height: 16),
                          if (_isLoginMode) _buildDemoCredentials(),
                          const SizedBox(height: 24),
                          _buildActionButton(),
                          const SizedBox(height: 16),
                          _buildToggleMode(),
                          const SizedBox(height: 24),
                          _buildDivider(),
                          const SizedBox(height: 16),
                          _buildGuestAccess(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.location_on,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Vehicle Tracking System',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isLoginMode
              ? 'Welcome back! Please sign in to continue.'
              : 'Create your account to get started.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _isLoginMode
          ? _authController.loginFormKey
          : _authController.registerFormKey,
      child: Column(
        children: [
          if (!_isLoginMode) ...[
            _buildTextField(
              controller: _authController.nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _authController.emailController,
            label: 'Email Address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!GetUtils.isEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Obx(() => _buildTextField(
            controller: _authController.passwordController,
            label: 'Password',
            icon: Icons.lock,
            obscureText: !_authController.isPasswordVisible.value,
            suffixIcon: IconButton(
              icon: Icon(
                _authController.isPasswordVisible.value
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () => _authController.isPasswordVisible.toggle(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!_isLoginMode && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          )),
          if (!_isLoginMode) ...[
            const SizedBox(height: 16),
            Obx(() => _buildTextField(
              controller: _authController.confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: !_authController.isConfirmPasswordVisible.value,
              suffixIcon: IconButton(
                icon: Icon(
                  _authController.isConfirmPasswordVisible.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () => _authController.isConfirmPasswordVisible.toggle(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _authController.passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            )),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _authController.phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildRoleSelector(),
          ],
          if (_isLoginMode) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Focus(
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Obx(() => Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Select Role',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          RadioListTile<String>(
            title: const Text('Driver'),
            subtitle: const Text('Vehicle operator with tracking features'),
            value: 'driver',
            groupValue: _authController.selectedRole.value,
            onChanged: (value) => _authController.selectedRole.value = value!,
            activeColor: Theme.of(context).primaryColor,
          ),
          RadioListTile<String>(
            title: const Text('Manager'),
            subtitle: const Text('Fleet management and monitoring'),
            value: 'manager',
            groupValue: _authController.selectedRole.value,
            onChanged: (value) => _authController.selectedRole.value = value!,
            activeColor: Theme.of(context).primaryColor,
          ),
          RadioListTile<String>(
            title: const Text('Admin'),
            subtitle: const Text('Full system administration'),
            value: 'admin',
            groupValue: _authController.selectedRole.value,
            onChanged: (value) => _authController.selectedRole.value = value!,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    ));
  }

  Widget _buildActionButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _authController.isLoading.value
            ? null
            : () {
                if (_isLoginMode) {
                  _handleLogin();
                } else {
                  _handleRegister();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _authController.isLoading.value
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isLoginMode ? 'Sign In' : 'Create Account',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ));
  }

  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLoginMode
              ? "Don't have an account? "
              : "Already have an account? ",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isLoginMode = !_isLoginMode;
            });
            _clearForm();
          },
          child: Text(
            _isLoginMode ? 'Sign Up' : 'Sign In',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildGuestAccess() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        onPressed: _handleGuestAccess,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Continue as Guest',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    await _authController.login();
  }

  void _handleRegister() async {
    await _authController.register();
  }

  void _handleGuestAccess() {
    Get.offAll(() => const MainDashboard());
    
    Get.snackbar(
      'Guest Mode',
      'You are using the app in guest mode. Some features may be limited.',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }

  void _clearForm() {
    _authController.emailController.clear();
    _authController.passwordController.clear();
    _authController.confirmPasswordController.clear();
    _authController.nameController.clear();
    _authController.phoneController.clear();
    _authController.errorMessage.value = '';
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.snackbar(
                'Email Sent',
                'Password reset link has been sent to your email.',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
                icon: const Icon(Icons.email, color: Colors.white),
              );
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCredentials() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Demo Credentials',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Admin: admin@vts.com / admin123\n'
            'Manager: manager@vts.com / manager123\n'
            'Driver: driver@vts.com / driver123\n'
            'Test: test@test.com / 123456',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// Import this in your app.dart
