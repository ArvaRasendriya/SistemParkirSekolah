import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tefa_parkir/auth/auth_gate.dart';
import 'package:tefa_parkir/pages/daftar_page.dart';
import 'package:tefa_parkir/pages/login_page.dart';
import 'package:tefa_parkir/pages/profile_page.dart';
import 'package:tefa_parkir/pages/admin_dashboard_page.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://rfpsfzbmhhxksisxciwx.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmcHNmemJtaGh4a3Npc3hjaXd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxMzM2MzMsImV4cCI6MjA3MDcwOTYzM30.OdBMWNBjgls2iw08JPqId9osfDTVE0W00H6zGHvOe_U",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // animasi splash dulu ➝ baru AuthGate
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const ProfilePage(),
        '/admin': (context) => const AdminDashboardPage(),
        '/daftar': (context) => const DaftarPage(),
      },
    );
  }
}

/// Splash screen animasi (Lottie)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Lottie.asset(
          'assets/sounds/zon4.json', // animasi logo kamu
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
