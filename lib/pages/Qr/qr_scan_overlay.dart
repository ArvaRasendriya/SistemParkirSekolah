import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import './corner_painter.dart';
import 'qr_scan_dialogs.dart';
import 'qr_scan_utils.dart';

class QrScanOverlay extends StatelessWidget {
  final bool isProcessing;
  final bool torchOn;
  final bool showSuccess;
  final bool qrInArea;
  final QrScanAnimations animations;
  final MobileScannerController cameraController;
  final VoidCallback onBack;
  final VoidCallback onToggleTorch;
  final Function(BarcodeCapture) onDetect;

  const QrScanOverlay({
    super.key,
    required this.isProcessing,
    required this.torchOn,
    required this.showSuccess,
    required this.qrInArea,
    required this.animations,
    required this.cameraController,
    required this.onBack,
    required this.onToggleTorch,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Camera Preview - Full Screen
        Positioned.fill(
          child: MobileScanner(
            controller: cameraController,
            onDetect: onDetect,
            fit: BoxFit.cover,
          ),
        ),

        // Scanning line - Full Width (seperti laser scanner)
        AnimatedBuilder(
          animation: animations.scanLineAnimation,
          builder: (context, child) {
            return Positioned(
              top: size.height * animations.scanLineAnimation.value,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.primary.withOpacity(0.3),
                      AppTheme.primary,
                      AppTheme.primaryLight,
                      AppTheme.primary,
                      AppTheme.primary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.8),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Top & Bottom UI
        _buildTopBar(context),
        _buildBottomInstruction(),

        // Loading overlay
        if (isProcessing) buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIconButton(
                  icon: Icons.arrow_back,
                  onPressed: onBack,
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
                  onPressed: onToggleTorch,
                  isActive: torchOn,
                ),
              ],
            ),
          ),
        ),
      );

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

  Widget _buildBottomInstruction() => Positioned(
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
                    'Arahkan kamera ke QR Code',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  Text(
                    'QR code akan terdeteksi secara otomatis',
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
      );
}