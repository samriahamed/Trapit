import 'package:flutter/material.dart';
import 'auth/welcome_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'session/user_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load saved session (NO return value)
  await UserSession.loadSession();

  runApp(const TrapITApp());
}

class TrapITApp extends StatelessWidget {
  const TrapITApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrapIT',

      // ✅ Auto-login decision (SAFE)
      home: UserSession.isLoggedIn
          ? const DashboardScreen()
          : const WelcomeScreen(),
    );
  }
}
