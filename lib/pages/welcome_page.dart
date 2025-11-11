import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

 @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = size.height - padding.top - padding.bottom;
    
    // Improved screen size detection
    final bool isSmallScreen = availableHeight < 650;
    final bool isMediumScreen = availableHeight >= 650 && availableHeight < 800;
    final bool isLargeScreen = availableHeight >= 800;

    // Dynamic sizing based on screen
    double logoContainerHeight = isSmallScreen ? availableHeight * 0.25 : 
                                 isMediumScreen ? availableHeight * 0.28 : 
                                 availableHeight * 0.30;
    
    double logoSize = isSmallScreen ? size.width * 0.35 : 
                      isMediumScreen ? size.width * 0.40 : 
                      size.width * 0.45;

    double illustrationHeight = isSmallScreen ? availableHeight * 0.15 : 
                                isMediumScreen ? availableHeight * 0.18 : 
                                availableHeight * 0.20;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top blue container with logo - Fixed height
            Container(
              height: logoContainerHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                  bottomRight: Radius.circular(80),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Flexible content area
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? AppTheme.spaceM : AppTheme.spaceL,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Illustration
                    Flexible(
                      flex: 2,
                      child: Center(
                        child: Image.asset(
                          'assets/images/scooter_illustration.png',
                          fit: BoxFit.contain,
                          height: illustrationHeight,
                        ),
                      ),
                    ),

                    // Text section
                    Flexible(
                      flex: isSmallScreen ? 2 : 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Selamat datang di Zon4',
                              style: AppTheme.h2.copyWith(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                                fontSize: isSmallScreen ? 24 : isMediumScreen ? 28 : 32,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceS),
                            child: Text(
                              'Solusi mudah untuk mengelola parkir khusus pengemudi berlisensi',
                              style: AppTheme.bodyMedium.copyWith(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textPrimary,
                                fontSize: isSmallScreen ? 13 : isMediumScreen ? 15 : 16,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Button
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? AppTheme.spaceS : AppTheme.spaceM,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 50 : isMediumScreen ? 56 : 60,
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
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  'Mulai',
                                  style: AppTheme.button.copyWith(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textOnPrimary,
                                    fontSize: isSmallScreen ? 16 : 18,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: AppTheme.textOnPrimary,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}