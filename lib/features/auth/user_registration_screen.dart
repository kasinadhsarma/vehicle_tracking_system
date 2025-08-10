import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/app_colors.dart';

class UserRegistrationScreen extends StatefulWidget {
  final String phoneNumber;

  const UserRegistrationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _licenseController = TextEditingController();
  
  String _selectedRole = 'driver';
  String _selectedVehicleType = 'car';
  bool _isLoading = false;
  bool _wantsToRegisterVehicle = true;

  final List<Map<String, dynamic>> _roles = [
    {'value': 'driver', 'label': 'Driver', 'icon': Icons.person_outline},
    {'value': 'consumer', 'label': 'Rider/Customer', 'icon': Icons.person},
    {'value': 'manager', 'label': 'Fleet Manager', 'icon': Icons.supervisor_account},
  ];

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'value': 'car', 'label': 'Car', 'icon': Icons.directions_car},
    {'value': 'motorcycle', 'label': 'Motorcycle', 'icon': Icons.two_wheeler},
    {'value': 'auto', 'label': 'Auto Rickshaw', 'icon': Icons.electric_rickshaw},
    {'value': 'taxi', 'label': 'Taxi', 'icon': Icons.local_taxi},
    {'value': 'truck', 'label': 'Truck', 'icon': Icons.local_shipping},
    {'value': 'bus', 'label': 'Bus', 'icon': Icons.directions_bus},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _vehicleNumberController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      
      // Register user with phone number
      await authService.registerWithPhoneNumber(
        smsCode: '', // Already verified
        name: _nameController.text.trim(),
        role: _selectedRole,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );

      // Register vehicle if driver wants to
      if (_wantsToRegisterVehicle && _selectedRole == 'driver') {
        final vehicleRegistered = await authService.registerVehicleWithPhone(
          phoneNumber: widget.phoneNumber,
          vehicleNumber: _vehicleNumberController.text.trim(),
          driverName: _nameController.text.trim(),
          vehicleType: _selectedVehicleType,
          licenseNumber: _licenseController.text.trim().isEmpty ? null : _licenseController.text.trim(),
        );

        if (vehicleRegistered) {
          _showSuccess('Vehicle registered successfully!');
        }
      }

      if (mounted) {
        _showSuccess('Registration completed successfully!');
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } catch (e) {
      _showError('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Complete Registration',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add,
                          size: 50,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome to Vadodara!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Phone: ${widget.phoneNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Basic Information
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Email (optional)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (Optional)',
                    hintText: 'Enter your email address',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Role Selection
                const Text(
                  'Select Your Role',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ...(_roles.map((role) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      value: role['value'],
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                          _wantsToRegisterVehicle = value == 'driver';
                        });
                      },
                      title: Text(role['label']),
                      secondary: Icon(role['icon']),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: _selectedRole == role['value'] 
                              ? AppColors.primary 
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ).toList()),
                
                const SizedBox(height: 24),
                
                // Vehicle Registration (only for drivers)
                if (_selectedRole == 'driver') ...[
                  Row(
                    children: [
                      const Text(
                        'Vehicle Registration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _wantsToRegisterVehicle,
                        onChanged: (value) {
                          setState(() => _wantsToRegisterVehicle = value);
                        },
                      ),
                    ],
                  ),
                  
                  if (_wantsToRegisterVehicle) ...[
                    const SizedBox(height: 16),
                    
                    // Vehicle Type Selection
                    const Text(
                      'Vehicle Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _vehicleTypes.map((type) =>
                        FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(type['icon'], size: 16),
                              const SizedBox(width: 4),
                              Text(type['label']),
                            ],
                          ),
                          selected: _selectedVehicleType == type['value'],
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedVehicleType = type['value']);
                            }
                          },
                        ),
                      ).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vehicle Number
                    TextFormField(
                      controller: _vehicleNumberController,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Number *',
                        hintText: 'e.g., 1234 or AB-12-CD-1234',
                        prefixIcon: const Icon(Icons.directions_car),
                        prefixText: 'GJ-06-',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: _wantsToRegisterVehicle ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter vehicle number';
                        }
                        return null;
                      } : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // License Number (optional)
                    TextFormField(
                      controller: _licenseController,
                      decoration: InputDecoration(
                        labelText: 'Driving License (Optional)',
                        hintText: 'Enter your license number',
                        prefixIcon: const Icon(Icons.card_membership),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
                
                const SizedBox(height: 32),
                
                // Register button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Complete Registration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Vadodara specific note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_city, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Vadodara Operations',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'We operate across all major areas in Vadodara including Alkapuri, Fatehgunj, Sayajigunj, Gotri, Manjalpur, and surrounding areas. Gujarat registration preferred.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
