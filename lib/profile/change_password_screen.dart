import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/forgot_password_screen.dart';
import '../services/api_service.dart';
import '../session/user_session.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;

  bool _showNewPasswordError = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  bool _isNewPasswordValid(String value) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$')
        .hasMatch(value);
  }

  void _saveNewPassword() async {
    setState(() {
      _showNewPasswordError = true;
    });

    if (!_isNewPasswordValid(_newController.text)) {
      return;
    }

    try {
      await ApiService.changePassword(
        email: UserSession.email,
        currentPassword: _currentController.text.trim(),
        newPassword: _newController.text.trim(),
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (_) => const AlertDialog(
          title: Text(
            'Success',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Password successfully changed'),
        ),
      );

      Timer(const Duration(seconds: 2), () {
        Navigator.pop(context); // close dialog
        Navigator.pop(context); // go back
      });

    } catch (e) {
      _showError(
        e.toString().replaceAll('Exception: ', ''),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2A4A),

      /// APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            /// CURRENT PASSWORD
            _passwordField(
              controller: _currentController,
              hint: 'Enter current password',
              obscure: _obscureCurrent,
              onToggle: () {
                setState(() {
                  _obscureCurrent = !_obscureCurrent;
                });
              },
            ),

            const SizedBox(height: 24),

            /// NEW PASSWORD
            _passwordField(
              controller: _newController,
              hint: 'Enter New Password',
              obscure: _obscureNew,
              enabled: _currentController.text.isNotEmpty,
              onToggle: () {
                setState(() {
                  _obscureNew = !_obscureNew;
                });
              },
              onChanged: (_) {
                if (_showNewPasswordError) {
                  setState(() {});
                }
              },
            ),

            const SizedBox(height: 6),

            /// PASSWORD RULE TEXT
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

            /// ERROR TEXT
            if (_showNewPasswordError &&
                !_isNewPasswordValid(_newController.text))
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password does not meet requirements',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            /// FORGOT PASSWORD
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
                style: TextStyle(
                  color: Colors.white70,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: 40),

            /// SAVE CHANGES
            SizedBox(
              width: 280,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5CCC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _saveNewPassword,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PASSWORD FIELD WIDGET
  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    bool enabled = true,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade300,
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: onToggle,
          ),
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
