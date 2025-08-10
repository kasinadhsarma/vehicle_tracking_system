import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/services/auth_service.dart';
import '../../core/constants/app_colors.dart';
import 'user_registration_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = 
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = 
      List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool get _isOtpComplete {
    return _otpCode.length == 6;
  }

  Future<void> _verifyOTP() async {
    if (!_isOtpComplete) {
      _showError('Please enter the complete OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      
      final userCredential = await authService.signInWithPhoneNumber(
        smsCode: _otpCode,
        verificationId: widget.verificationId,
      );

      if (userCredential != null && mounted) {
        // Check if this is a new user who needs to complete registration
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserRegistrationScreen(
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        } else {
          // Existing user, go to dashboard
          _showSuccess('Welcome back!');
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      }
    } catch (e) {
      _showError('Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });

    try {
      final authService = context.read<AuthService>();
      
      await authService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (credential) {},
        verificationFailed: (error) {
          _showError('Failed to resend OTP: ${error.message}');
        },
        codeSent: (verificationId, resendToken) {
          _showSuccess('OTP sent successfully!');
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } catch (e) {
      _showError('Failed to resend OTP: $e');
      setState(() => _canResend = true);
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_isOtpComplete && !_isLoading) {
      _verifyOTP();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header
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
                        Icons.message,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Enter verification code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a 6-digit code to\n${widget.phoneNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => _onOtpChanged(value, index),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              
              // Verify button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || !_isOtpComplete ? null : _verifyOTP,
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
                          'Verify & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Resend OTP
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _resendOTP,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Text(
                        'Resend OTP in ${_resendTimer}s',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
              
              const SizedBox(height: 20),
              
              // Change phone number
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Change phone number',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Alert',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Never share this OTP with anyone. Vadodara Vehicle Tracker will never ask for your OTP.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
