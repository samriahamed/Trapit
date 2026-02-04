import 'package:flutter/material.dart';
import '../dashboard/trap_registration_screen.dart';

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

  // ✅ OTP VALID FLAG
  bool _isOtpValid = false;

  // 🔴 DEMO OTP (replace with backend later)
  final String _demoOtp = '123456';

  /// EMAIL VALID CHECK
  bool get _isEmailValid {
    return _emailController.text.isNotEmpty &&
        _emailController.text.contains('@');
  }

  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
        _otpController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        _isOtpValid &&
        _formKey.currentState?.validate() == true;
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

  /// ✅ CHECK OTP
  void _validateOtp(String value) {
    setState(() {
      _isOtpValid = value == _demoOtp;
    });
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
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            children: [
              const SizedBox(height: 40),

              /// EMAIL
              _inputField(
                controller: _emailController,
                hint: 'Enter Registered Email',
                required: true,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  _emailController.value = TextEditingValue(
                    text: value.toLowerCase(),
                    selection:
                    TextSelection.collapsed(offset: value.length),
                  );
                },
                validator: (value) {
                  if (!_showEmailError) return null;
                  if (value == null || !value.contains('@')) {
                    return 'Incorrect format';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              /// SEND OTP
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEmailValid
                          ? const Color(0xFF3B5CCC)
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isEmailValid
                        ? () {
                      setState(() => _showEmailError = true);
                      _formKey.currentState?.validate();

                      // 🔴 DEMO: Show OTP in console
                      debugPrint('Demo OTP is: $_demoOtp');
                    }
                        : null,
                    child: const Text(
                      'Send OTP',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// OTP
              _inputField(
                controller: _otpController,
                hint: 'Enter OTP',
                required: true,
                keyboardType: TextInputType.number,
                onChanged: _validateOtp,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'OTP required';
                  }
                  if (!_isOtpValid) {
                    return 'Invalid OTP';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              /// NEW PASSWORD (DISABLED UNTIL OTP VALID)
              _inputField(
                controller: _passwordController,
                hint: 'Create New Password',
                required: true,
                obscureText: _obscurePassword,
                enabled: _isOtpValid,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (!_showPasswordError) return null;
                  if (!RegExp(
                      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$')
                      .hasMatch(value ?? '')) {
                    return 'Password does not meet requirements';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 6),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 36),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'at least 8 characters with mixed case and numbers',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              /// CONFIRM PASSWORD (DISABLED UNTIL OTP VALID)
              _inputField(
                controller: _confirmController,
                hint: 'Confirm New Password',
                required: true,
                focusNode: _confirmFocus,
                obscureText: _obscureConfirm,
                enabled: _isOtpValid,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm password required';
                  }
                  if (value != _passwordController.text) {
                    return 'Password does not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 50),

              /// LOGIN BUTTON
              SizedBox(
                width: 300,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? const Color(0xFF3B5CCC)
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isFormValid
                      ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrapRegistrationScreen(),
                      ),
                    );
                  }
                      : null,
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// INPUT FIELD
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool required = false,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    Function(String)? onChanged,
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
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          suffixText: required ? '*' : null,
          suffixStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade300,
          suffixIcon: suffixIcon,
          errorStyle: const TextStyle(color: Colors.red),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
