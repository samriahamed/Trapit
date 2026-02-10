import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _showEmailError = false;
  bool _showPasswordError = false;
  bool _otpVerified = false;

  bool get _isEmailValid =>
      _emailController.text.isNotEmpty &&
          _emailController.text.contains('@');

  bool get _isFormValid =>
      _emailController.text.isNotEmpty &&
          _otpController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmController.text.isNotEmpty &&
          _otpVerified &&
          _formKey.currentState?.validate() == true;

  bool _isPasswordValid(String value) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(value);
  }

  @override
  void initState() {
    super.initState();
    _confirmFocus.addListener(() {
      if (_confirmFocus.hasFocus) {
        setState(() => _showPasswordError = true);
        _formKey.currentState?.validate();
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() => _showEmailError = true);
    _formKey.currentState?.validate();
    try {
      await ApiService.sendOtp(_emailController.text.trim());
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("OTP sent to email")));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to send OTP")));
    }
  }

  Future<void> _verifyOtp() async {
    try {
      await ApiService.verifyOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );
      setState(() => _otpVerified = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("OTP Verified")));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid or expired OTP")));
    }
  }

  Future<void> _resetPassword() async {
    try {
      await ApiService.resetPassword(
        email: _emailController.text.trim(),
        newPassword: _passwordController.text.trim(),
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Password Changed",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            "Password changed successfully.\nPlease login with your new password.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LoginScreen(prefilledEmail: _emailController.text),
                  ),
                      (_) => false,
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Password reset failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2A4A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Forgot Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            children: [
              const SizedBox(height: 40),

              _inputField(
                controller: _emailController,
                hint: 'Enter Registered Email',
                required: true,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (!_showEmailError) return null;
                  if (v == null || !v.contains('@')) {
                    return 'Incorrect format';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              _actionButton('Send OTP', _isEmailValid, _sendOtp),

              const SizedBox(height: 24),

              _inputField(
                controller: _otpController,
                hint: 'Enter OTP',
                required: true,
                keyboardType: TextInputType.number,
              ),

              _actionButton(
                'Verify OTP',
                _otpController.text.trim().length == 6,
                _verifyOtp,
              ),

              const SizedBox(height: 18),

              _inputField(
                controller: _passwordController,
                hint: 'Create New Password',
                required: true,
                obscureText: _obscurePassword,
                enabled: _otpVerified,
                validator: (v) {
                  if (!_showPasswordError) return null;
                  if (v == null || !_isPasswordValid(v)) {
                    return 'Password does not meet requirements';
                  }
                  return null;
                },
                suffixIcon: _eyeIcon(
                  _obscurePassword,
                      () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'at least 8 characters with mixed case and numbers',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ),

              _inputField(
                controller: _confirmController,
                hint: 'Confirm New Password',
                required: true,
                obscureText: _obscureConfirm,
                enabled: _otpVerified,
                focusNode: _confirmFocus,
                validator: (v) {
                  if (v != _passwordController.text) {
                    return 'Password does not match';
                  }
                  return null;
                },
                suffixIcon: _eyeIcon(
                  _obscureConfirm,
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: 300,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isFormValid ? const Color(0xFF3B5CCC) : Colors.grey,
                  ),
                  onPressed: _isFormValid ? _resetPassword : null,
                  child: const Text('Reset Password',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eyeIcon(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
      onPressed: onTap,
    );
  }

  Widget _actionButton(String text, bool enabled, VoidCallback onTap) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 32),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
            enabled ? const Color(0xFF3B5CCC) : Colors.grey,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: enabled ? onTap : null,
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool required = false,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade300,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (required)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Text('*',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              if (suffixIcon != null) suffixIcon,
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
