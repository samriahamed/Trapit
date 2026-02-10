import 'package:flutter/material.dart';
import 'auth/welcome_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'session/user_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load saved session BEFORE app starts
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

      // ✅ Cleaner navigation structure
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },

      // ✅ Decide start screen safely
      initialRoute:
      UserSession.isLoggedIn ? '/dashboard' : '/welcome',
    );
  }
}

