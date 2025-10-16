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
  String? lastScannedCode;
  DateTime? lastScanTime;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

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

  bool _isInScanArea(Barcode barcode, Size screenSize) {
    final scanAreaSize = screenSize.width * 0.70;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    final scanAreaLeft = centerX - (scanAreaSize / 2);
    final scanAreaRight = centerX + (scanAreaSize / 2);
    final scanAreaTop = centerY - (scanAreaSize / 2);
    final scanAreaBottom = centerY + (scanAreaSize / 2);

    final corners = barcode.corners;
    if (corners.isEmpty) return false;

    // Check if QR code center is within scan area
    double sumX = 0;
    double sumY = 0;
    for (var corner in corners) {
      sumX += corner.dx;
      sumY += corner.dy;
    }
    final centerQrX = sumX / corners.length;
    final centerQrY = sumY / corners.length;

    return centerQrX >= scanAreaLeft &&
        centerQrX <= scanAreaRight &&
        centerQrY >= scanAreaTop &&
        centerQrY <= scanAreaBottom;
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
            Icon(Icons.error_outline, color: AppTheme.error, size: 28),
            const SizedBox(width: AppTheme.spaceS),
            Expanded(
              child: Text(
                'Gagal',
                style: AppTheme.h3.copyWith(color: AppTheme.error),
              ),
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
    if (isProcessing || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue;
    
    if (code == null) return;

    // Prevent duplicate scans within 3 seconds
    if (lastScannedCode == code && lastScanTime != null) {
      final diff = DateTime.now().difference(lastScanTime!);
      if (diff.inSeconds < 3) return;
    }

    // Check if QR is in scan area
    final size = MediaQuery.of(context).size;
    if (!_isInScanArea(barcode, size)) {
      return;
    }

    lastScannedCode = code;
    lastScanTime = DateTime.now();
    
    setState(() => isProcessing = true);

    await _playBeep();
    await _vibrate();

    await _fetchUserAndNavigate(code);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.70;

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

          // Dark Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ScanAreaPainter(
                scanAreaSize: scanAreaSize,
                screenSize: size,
              ),
            ),
          ),

          // Scan Frame
          Center(
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: Stack(
                children: [
                  // Border
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),

                  // Animated corners
                  ..._buildCorners(scanAreaSize),

                  // Scanning line
                  AnimatedBuilder(
                    animation: _scanLineAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: scanAreaSize * _scanLineAnimation.value,
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
                    _buildIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceL,
                        vertical: AppTheme.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'SCAN QR',
                        style: AppTheme.h3.copyWith(
                          color: Colors.white,
                          letterSpacing: 2,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _buildIconButton(
                      icon: torchOn ? Icons.flash_on : Icons.flash_off,
                      onPressed: () {
                        cameraController.toggleTorch();
                        setState(() => torchOn = !torchOn);
                      },
                      isActive: torchOn,
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
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: AppTheme.primary,
                        size: 40,
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Text(
                        'Letakkan QR Code di dalam kotak',
                        style: AppTheme.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      Text(
                        'Pastikan QR code berada di tengah area scan',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (isProcessing && !showSuccess)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spaceXL),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    boxShadow: AppTheme.shadowLarge(),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: AppTheme.spaceL),
                      Text(
                        'Memproses QR Code...',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
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

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primary.withOpacity(0.9)
            : Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? AppTheme.primary
              : Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  List<Widget> _buildCorners(double scanAreaSize) {
    final cornerSize = scanAreaSize * 0.12;
    
    return [
      Positioned(
        top: 0,
        left: 0,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(cornerSize, cornerSize),
              painter: CornerPainter(
                color: AppTheme.primary,
                position: CornerPosition.topLeft,
                thickness: 5 * _pulseAnimation.value,
              ),
            );
          },
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(cornerSize, cornerSize),
              painter: CornerPainter(
                color: AppTheme.primary,
                position: CornerPosition.topRight,
                thickness: 5 * _pulseAnimation.value,
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(cornerSize, cornerSize),
              painter: CornerPainter(
                color: AppTheme.primary,
                position: CornerPosition.bottomLeft,
                thickness: 5 * _pulseAnimation.value,
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(cornerSize, cornerSize),
              painter: CornerPainter(
                color: AppTheme.primary,
                position: CornerPosition.bottomRight,
                thickness: 5 * _pulseAnimation.value,
              ),
            );
          },
        ),
      ),
    ];
  }
}

class ScanAreaPainter extends CustomPainter {
  final double scanAreaSize;
  final Size screenSize;

  ScanAreaPainter({
    required this.scanAreaSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, screenSize.width, screenSize.height));

    final scanAreaRect = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    final scanAreaPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanAreaRect,
          const Radius.circular(20),
        ),
      );

    final finalPath = Path.combine(
      PathOperation.difference,
      path,
      scanAreaPath,
    );

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(ScanAreaPainter oldDelegate) => false;
}

enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class CornerPainter extends CustomPainter {
  final Color color;
  final CornerPosition position;
  final double thickness;

  CornerPainter({
    required this.color,
    required this.position,
    this.thickness = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final cornerLength = size.width * 0.5;

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