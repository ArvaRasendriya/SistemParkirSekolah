import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top blue container with logo
            Container(
              height: size.height * 0.4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF3F37C9),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                  bottomRight: Radius.circular(80),
                ),
              ),
              child: Stack(
                children: [
                  // Logo positioned properly
                  Positioned(
                    top: isSmallScreen ? size.height * 0.11 : size.height * 0.10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: isSmallScreen ? size.width * 0.8 : size.width * 0.7,
                        height: isSmallScreen ? size.width * 0.8 : size.width * 0.7,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // Illustration image with responsive sizing
            Expanded(
              flex: isSmallScreen ? 2 : 3,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: isSmallScreen ? 10 : 20,
                ),
                child: Image.asset(
                  'assets/images/scooter_illustration.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),

            const SizedBox(height: 30,),

            // Text section with responsive sizing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'Selamat datang di Zon4',
                    style: TextStyle(
                      color: const Color(0xFF3F37C9),
                      fontFamily: 'Montserrat',
                      fontSize: isSmallScreen ? 18 : 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Solusi mudah untuk mengelola parkir khusus pengemudi berlisensi',
                    style: TextStyle(
                      color: Color(0xFF313638),
                      fontSize: isSmallScreen ? 16 : 20,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Spacer
            const SizedBox(height: 30),

            // Button with responsive sizing
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: isSmallScreen ? 10 : 0,
              ),
              child: SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 60 : 80,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F37C9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/auth');
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          'Mulai',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: const Color(0xFFF8F8FF),
                            fontSize: isSmallScreen ? 16 : 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        child: Icon(
                          Icons.arrow_forward,
                          color: const Color(0xFFF8F8FF),
                          size: isSmallScreen ? 28 : 34
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom spacing
            SizedBox(height: isSmallScreen ? 16 : 24),
          ],
        ),
      ),
    );
  }
}