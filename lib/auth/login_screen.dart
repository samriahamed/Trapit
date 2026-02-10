import 'package:flutter/material.dart';

import 'welcome_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../services/api_service.dart';
import '../session/user_session.dart';

class LoginScreen extends StatefulWidget {

  // ✅ NEW (for forgot password redirect)
  final String prefilledEmail;

  const LoginScreen({
    super.key,
    this.prefilledEmail = '',
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _showEmailError = false;
  bool isLoading = false;

  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _formKey.currentState?.validate() == true;
  }

  @override
  void initState() {
    super.initState();

    // ✅ AUTO-FILL EMAIL IF PROVIDED
    if (widget.prefilledEmail.isNotEmpty) {
      _emailController.text = widget.prefilledEmail.toLowerCase();
    }

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        setState(() => _showEmailError = true);
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// 🌐 LOGIN VIA BACKEND
  void _login() async {
    setState(() => isLoading = true);

    try {
      await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Invalid email or password');
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const WelcomeScreen(),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Login to continue managing your traps',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),

              _inputField(
                controller: _emailController,
                hint: 'Email Address',
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
                    return 'Incorrect mail format';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              _inputField(
                controller: _passwordController,
                hint: 'Password',
                required: true,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
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
                  if (value == null || value.isEmpty) {
                    return 'Password required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Forgot Password ?',
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 40),

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
                  onPressed:
                  (_isFormValid && !isLoading) ? _login : null,
                  child: isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      ' Click here to Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
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
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          suffixText: required ? '*' : null,
          suffixStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
          filled: true,
          fillColor: Colors.white,
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
