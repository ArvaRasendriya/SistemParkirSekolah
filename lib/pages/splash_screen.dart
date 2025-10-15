import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToWelcome();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _navigateToWelcome() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.35;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              AppTheme.primaryDark.withOpacity(0.8),
              AppTheme.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Logo with animations
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 50,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: logoSize,
                          height: logoSize,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppTheme.spaceXL),

              // App name
              AnimatedBuilder(
                animation: _logoOpacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Column(
                      children: [
                        Text(
                          'ZON4',
                          style: AppTheme.h1.copyWith(
                            color: AppTheme.textOnPrimary,
                            fontSize: size.width < 360 ? 36 : 48,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceS),
                        Text(
                          'Smart Parking System',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textOnPrimary.withOpacity(0.7),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),

              // Progress bar
              AnimatedBuilder(
                animation: _progress,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXXL),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          child: SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              value: _progress.value,
                              backgroundColor: AppTheme.textOnPrimary.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.textOnPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                        Text(
                          'Loading...',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textOnPrimary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: AppTheme.spaceXXL),
            ],
          ),
        ),
      ),
    );
  }
}
