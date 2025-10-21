import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../theme/app_theme.dart';
import './qr_scan_overlay.dart';
import './qr_scan_dialogs.dart';
import './qr_scan_utils.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> with TickerProviderStateMixin {
  bool isProcessing = false;
  bool torchOn = false;
  bool qrInArea = false;

  // Tracking untuk prevent spam
  String? lastScannedCode;
  DateTime? lastScanTime;
  bool hasScannedSuccessfully = false;

  final supabase = Supabase.instance.client;
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, // Prevent spam
  );
  final AudioPlayer _audioPlayer = AudioPlayer();

  late QrScanAnimations animations;

  @override
  void initState() {
    super.initState();
    animations = QrScanAnimations(this);
  }

  @override
  void dispose() {
    animations.dispose();
    cameraController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (hasScannedSuccessfully) return;
    if (isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue;
    if (code == null || code.isEmpty) return;

    // Anti-spam: prevent same code within 2 seconds
    if (lastScannedCode == code && lastScanTime != null) {
      final diff = DateTime.now().difference(lastScanTime!);
      if (diff.inSeconds < 2) return;
    }

    setState(() => isProcessing = true);
    lastScannedCode = code;
    lastScanTime = DateTime.now();

    // Stop camera detection sementara
    await cameraController.stop();

    // Feedback haptic & audio
    await Future.wait([
      playBeep(_audioPlayer),
      vibrate(),
    ]);

    try {
      // Fetch user dan langsung navigasi ke ScanResultPage
      await fetchUserAndNavigate(
        context: context,
        supabase: supabase,
        userId: code,
      );

      hasScannedSuccessfully = true;
    } catch (e) {
      // Jika error network / invalid QR
      setState(() => isProcessing = false);
      showErrorDialog(context, e.toString());

      // Restart camera untuk scan lagi
      await cameraController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: QrScanOverlay(
        isProcessing: isProcessing,
        torchOn: torchOn,
        showSuccess: false, // Tidak ada animasi success
        qrInArea: qrInArea,
        animations: animations,
        cameraController: cameraController,
        onBack: () => Navigator.pop(context),
        onToggleTorch: () {
          cameraController.toggleTorch();
          setState(() => torchOn = !torchOn);
        },
        onDetect: _onDetect,
      ),
    );
  }
}
