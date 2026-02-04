import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../session/user_session.dart';
import '../services/api_service.dart';

class TrapRegistrationScreen extends StatefulWidget {
  const TrapRegistrationScreen({super.key});

  @override
  State<TrapRegistrationScreen> createState() =>
      _TrapRegistrationScreenState();
}

class _TrapRegistrationScreenState extends State<TrapRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _trapIdController = TextEditingController();
  final _trapNameController = TextEditingController();

  bool isSubmitting = false;

  bool get _isFormValid {
    return _trapIdController.text.trim().isNotEmpty &&
        _formKey.currentState?.validate() == true;
  }

  @override
  void dispose() {
    _trapIdController.dispose();
    _trapNameController.dispose();
    super.dispose();
  }

  /// 🌐 REGISTER TRAP VIA BACKEND
  Future<void> _registerTrap() async {
    final trapId = _trapIdController.text.trim();
    final trapName = _trapNameController.text.trim().isEmpty
        ? 'Backyard Trap'
        : _trapNameController.text.trim();

    setState(() => isSubmitting = true);

    try {
      await ApiService.addTrap(
        email: UserSession.email,
        trapId: trapId,
        trapName: trapName,
      );

      setState(() => isSubmitting = false);

      // ✅ SUCCESS POPUP (UNCHANGED UI)
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Registered Successfully',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 120,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5CCC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardScreen(),
                        ),
                            (route) => false,
                      );
                    },
                    child: const Text(
                      'OK',
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
        ),
      );
    } catch (e) {
      setState(() => isSubmitting = false);

      // 🔴 BACKEND DUPLICATE ERROR
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Trap ID Error'),
          content: const Text(
            'This Trap ID already exists. Please use a different Trap ID.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
          'Trap Registration',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
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

              /// AVATAR
              const CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 52,
                  color: Color(0xFF0B2A4A),
                ),
              ),

              const SizedBox(height: 40),

              /// TRAP ID
              _inputField(
                controller: _trapIdController,
                hint: 'Assign Trap ID',
                required: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Trap ID is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// TRAP NAME
              _inputField(
                controller: _trapNameController,
                hint: 'Trap Name',
              ),

              const SizedBox(height: 50),

              /// REGISTER BUTTON
              SizedBox(
                width: 180,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? const Color(0xFF3B5CCC)
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onPressed:
                  (_isFormValid && !isSubmitting) ? _registerTrap : null,
                  child: isSubmitting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Register Trap',
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

  /// INPUT FIELD WIDGET (UNCHANGED)
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: TextFormField(
        controller: controller,
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
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorStyle: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
