import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _showEmailError = false;
  bool _showPasswordError = false;
  bool isSubmitting = false;

  bool get _isFormValid {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        _formKey.currentState?.validate() == true;
  }

  @override
  void initState() {
    super.initState();

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        setState(() => _showEmailError = true);
        _formKey.currentState?.validate();
      }
    });

    _confirmFocus.addListener(() {
      if (_confirmFocus.hasFocus) {
        setState(() => _showPasswordError = true);
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// ✅ REGISTER USING AuthService
  Future<void> _register() async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      bool success = await AuthService.registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => isSubmitting = false);

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text('Please login to continue'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
        );
      } else {
        _showError("Registration failed. Please try again.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);

      final err = e.toString().toLowerCase();

      String msg;

      if (err.contains("user already exists")) {
        msg =
        'This email is already registered.\nPlease login or use another email.';
      } else if (err.contains("network")) {
        msg =
        'Could not connect to the server.\nPlease check your internet or backend.';
      } else {
        msg = 'Server error. Please try again.';
      }

      _showError(msg);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registration Failed'),
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 40),

              _inputField(
                controller: _nameController,
                hint: 'Full Name',
              ),

              const SizedBox(height: 18),

              _inputField(
                controller: _emailController,
                hint: 'Email Address',
                required: true,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 18),

              _inputField(
                controller: _passwordController,
                hint: 'Create Password',
                required: true,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
              ),

              const SizedBox(height: 18),

              _inputField(
                controller: _confirmController,
                hint: 'Confirm Password',
                required: true,
                focusNode: _confirmFocus,
                obscureText: _obscureConfirm,
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: 300,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isFormValid ? const Color(0xFF3B5CCC) : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed:
                  (_isFormValid && !isSubmitting) ? _register : null,
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Register',
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

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool required = false,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          suffixText: required ? '*' : null,
          filled: true,
          fillColor: Colors.white,
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
