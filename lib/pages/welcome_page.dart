import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = size.height - padding.top - padding.bottom;
    final bool isSmallScreen = availableHeight < 700;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top blue container with logo
                      Container(
                        height: constraints.maxHeight * (isSmallScreen ? 0.28 : 0.32),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(80),
                            bottomRight: Radius.circular(80),
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? AppTheme.spaceS : AppTheme.spaceM,
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: size.width * (isSmallScreen ? 0.40 : 0.38),
                              height: size.width * (isSmallScreen ? 0.40 : 0.38),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? AppTheme.spaceM : AppTheme.spaceL),

                      // Illustration image with responsive sizing
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
                        child: Image.asset(
                          'assets/images/scooter_illustration.png',
                          fit: BoxFit.contain,
                          width: size.width * (isSmallScreen ? 0.65 : 0.70),
                          height: constraints.maxHeight * (isSmallScreen ? 0.16 : 0.20),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? AppTheme.spaceM : AppTheme.spaceL),

                      // Text section with responsive sizing
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
                        child: Column(
                          children: [
                            Text(
                              'Selamat datang di Zon4',
                              style: (isSmallScreen ? AppTheme.h3 : AppTheme.h2).copyWith(
                                color: AppTheme.primary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? AppTheme.spaceS : AppTheme.spaceM),
                            Text(
                              'Solusi mudah untuk mengelola parkir khusus pengemudi berlisensi',
                              style: (isSmallScreen ? AppTheme.bodyMedium : AppTheme.bodyLarge).copyWith(
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Spacer
                      const Spacer(),

                      // Button with responsive sizing
                      Padding(
                        padding: EdgeInsets.all(
                          isSmallScreen ? AppTheme.spaceM : AppTheme.spaceL,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 52 : 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/auth');
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Mulai',
                                  style: AppTheme.button.copyWith(
                                    color: AppTheme.textOnPrimary,
                                    fontSize: isSmallScreen ? 16 : 18,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceM),
                                Icon(
                                  Icons.arrow_forward,
                                  color: AppTheme.textOnPrimary,
                                  size: isSmallScreen ? 22 : 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}