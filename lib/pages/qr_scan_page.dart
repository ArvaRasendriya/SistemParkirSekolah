import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import 'qr_result_page.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage>
    with TickerProviderStateMixin {
  bool isProcessing = false;
  bool torchOn = false;
  final supabase = Supabase.instance.client;
  final MobileScannerController cameraController = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  late AnimationController _successController;
  late Animation<double> _successAnimation;
  
  bool showSuccess = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Scan line animation
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scanLineController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulse animation for corners
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Success animation
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    cameraController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBeep() async {
    try {
      if (kIsWeb) {
        await _audioPlayer.play(UrlSource("assets/sounds/beep.mp3"));
      } else {
        await _audioPlayer.play(AssetSource("sounds/beep.mp3"));
      }
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      debugPrint("Vibration error: $e");
    }
  }

  bool isValidUuid(String input) {
    try {
      Uuid.parse(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _fetchUserAndNavigate(String userId) async {
    if (!isValidUuid(userId)) {
      if (mounted) {
        setState(() => isProcessing = false);
        _showErrorDialog('QR Code tidak valid');
      }
      return;
    }

    try {
      final response = await supabase
          .from('siswa')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final success = await _logScan(siswaId: userId);
        
        if (!mounted) return;
        
        if (success) {
          // Show success animation
          setState(() => showSuccess = true);
          _successController.forward();
          
          await Future.delayed(const Duration(milliseconds: 800));
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ScanResultPage(userData: response),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => isProcessing = false);
          _showErrorDialog('Siswa tidak ditemukan');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isProcessing = false);
        _showErrorDialog('Error: ${e.toString()}');
      }
    }
  }

  Future<bool> _logScan({required String siswaId}) async {
    try {
      final lastScan = await supabase
          .from('parkir')
          .select('created_at')
          .eq('siswa_id', siswaId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (lastScan != null) {
        final lastTime = DateTime.parse(lastScan['created_at']).toLocal();
        final diff = DateTime.now().difference(lastTime);

        if (diff.inHours < 15) {
          if (mounted) {
            _showErrorDialog(
              'Sudah scan hari ini\nCoba lagi ${15 - diff.inHours} jam lagi',
            );
          }
          return false;
        }
      }

      final scannedBy = supabase.auth.currentUser?.email ??
          supabase.auth.currentUser?.id;
          
      await supabase.from('parkir').insert({
        'siswa_id': siswaId,
        'scanned_by': scannedBy,
      });

      return true;
    } catch (e) {
      debugPrint('Failed to log scan: $e');
      return false;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error),
            const SizedBox(width: AppTheme.spaceS),
            Text(
              'Gagal',
              style: AppTheme.h3.copyWith(color: AppTheme.error),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
        ),
        actions: [
          AppButton(
            text: 'OK',
            onPressed: () => Navigator.pop(context),
            height: 44,
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;
    
    final code = capture.barcodes.first.rawValue;
    if (code != null) {
      setState(() => isProcessing = true);

      await _playBeep();
      await _vibrate();

      await _fetchUserAndNavigate(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
              fit: BoxFit.cover,
            ),
          ),

          // Overlay dengan frame scan
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Center(
                child: SizedBox(
                  width: size.width * 0.75,
                  height: size.width * 0.75,
                  child: Stack(
                    children: [
                      // Transparent center (scanning area)
                      Center(
                        child: Container(
                          width: size.width * 0.75,
                          height: size.width * 0.75,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      // Animated corners
                      ..._buildCorners(),

                      // Scanning line
                      AnimatedBuilder(
                        animation: _scanLineAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: (size.width * 0.75) * _scanLineAnimation.value,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.primary,
                                    AppTheme.primaryLight,
                                    AppTheme.primary,
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Success checkmark
                      if (showSuccess)
                        ScaleTransition(
                          scale: _successAnimation,
                          child: Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                                boxShadow: AppTheme.shadowLarge(),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(AppTheme.spaceS),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // App logo/title
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceL,
                        vertical: AppTheme.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                      child: Text(
                        'ZON4',
                        style: AppTheme.h3.copyWith(
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    // Torch button
                    IconButton(
                      onPressed: () {
                        cameraController.toggleTorch();
                        setState(() => torchOn = !torchOn);
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          key: ValueKey(torchOn),
                          padding: const EdgeInsets.all(AppTheme.spaceS),
                          decoration: BoxDecoration(
                            color: torchOn
                                ? AppTheme.primary.withOpacity(0.8)
                                : Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            torchOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom instruction
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceL,
                        vertical: AppTheme.spaceM,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                          const SizedBox(height: AppTheme.spaceS),
                          Text(
                            'Arahkan QR Code ke area scan',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spaceXS),
                          Text(
                            'Scan otomatis ketika QR terdeteksi',
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (isProcessing && !showSuccess)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spaceXL),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Text(
                        'Memproses...',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(40, 40),
              painter: CornerPainter(
                color: AppTheme.primary,
                position: CornerPosition.topLeft,
                thickness: 4 * _pulseAnimation.value,
              ),
            );
          },
        ),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(40, 40),
              painter: CornerPainter(
                color: AppTheme.primary,
                position: CornerPosition.topRight,
                thickness: 4 * _pulseAnimation.value,
              ),
            );
          },
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(40, 40),
              painter: CornerPainter(
                color: AppTheme.primary,
                position: CornerPosition.bottomLeft,
                thickness: 4 * _pulseAnimation.value,
              ),
            );
          },
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(40, 40),
              painter: CornerPainter(
                color: AppTheme.primary,
                position: CornerPosition.bottomRight,
                thickness: 4 * _pulseAnimation.value,
              ),
            );
          },
        ),
      ),
    ];
  }
}

enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class CornerPainter extends CustomPainter {
  final Color color;
  final CornerPosition position;
  final double thickness;

  CornerPainter({
    required this.color,
    required this.position,
    this.thickness = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final cornerLength = size.width * 0.6;

    switch (position) {
      case CornerPosition.topLeft:
        path.moveTo(cornerLength, 0);
        path.lineTo(0, 0);
        path.lineTo(0, cornerLength);
        break;
      case CornerPosition.topRight:
        path.moveTo(size.width - cornerLength, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, cornerLength);
        break;
      case CornerPosition.bottomLeft:
        path.moveTo(0, size.height - cornerLength);
        path.lineTo(0, size.height);
        path.lineTo(cornerLength, size.height);
        break;
      case CornerPosition.bottomRight:
        path.moveTo(size.width, size.height - cornerLength);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width - cornerLength, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CornerPainter oldDelegate) =>
      oldDelegate.thickness != thickness;
}