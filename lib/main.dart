import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tefa_parkir/auth/auth_gate.dart';
import 'pages/daftar_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/welcome_page.dart'; // Added import for WelcomePage

// Import splash screen
import 'package:tefa_parkir/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://rfpsfzbmhhxksisxciwx.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmcHNmemJtaGh4a3Npc3hjaXd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxMzM2MzMsImV4cCI6MjA3MDcwOTYzM30.OdBMWNBjgls2iw08JPqId9osfDTVE0W00H6zGHvOe_U",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Pertama kali masuk ke SplashScreen
      home: const SafeArea(child: SplashScreen()),
      routes: {
        '/login': (context) => const SafeArea(child: LoginPage()),
        '/profile': (context) => const SafeArea(child: ProfilePage()),
        '/admin': (context) => const SafeArea(child: AdminDashboardPage()),
        '/daftar': (context) => const SafeArea(child: DaftarPage()),
        '/auth': (context) => const SafeArea(child: AuthGate()),
        '/welcome': (context) => const SafeArea(child: WelcomePage()),
      },
    );
  }
}
