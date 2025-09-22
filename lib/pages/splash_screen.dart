import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi fade-in teks
    _textController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation =
        CurvedAnimation(parent: _textController, curve: Curves.easeIn);

    // Mulai animasi teks sedikit setelah splash muncul
    Future.delayed(const Duration(milliseconds: 1200), () {
      _textController.forward();
    });

    // Setelah 3 detik, pindah ke LoginPage
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ));
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasi Logo Lottie
            Lottie.asset(
              'assets/sounds/zon4.json',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            // Fade-in Teks
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                "ZONA4 PARKING",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
