import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:ui';
import 'qr_result_page.dart';
import 'gagal_scan_page.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage>
    with TickerProviderStateMixin {
  bool isProcessing = false;
  bool torchOn = false;
  bool showCircle = false;
  final supabase = Supabase.instance.client;
  final MobileScannerController cameraController = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _lineController;
  late Animation<double> _lineAnimation;

  late AnimationController _textController;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _lineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.linear),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _textAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _lineController.dispose();
    _textController.dispose();
    cameraController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBeep() async {
    if (kIsWeb) {
      await _audioPlayer.play(UrlSource("assets/sounds/beep.mp3"));
    } else {
      await _audioPlayer.play(AssetSource("sounds/beep.mp3"));
    }
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 300);
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
    try {
      if (!isValidUuid(userId)) {
        if (!mounted) return;
        setState(() => isProcessing = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DaftarGagalPage()),
        );
        return;
      }

      final response =
          await supabase.from('siswa').select().eq('id', userId).maybeSingle();

      if (response != null) {
        final success = await logScan(siswaId: userId, supabase: supabase);
        if (!mounted) return;
        setState(() => isProcessing = false);

        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ScanResultPage(userData: response),
            ),
          );
        }
      } else {
        if (!mounted) return;
        setState(() => isProcessing = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DaftarGagalPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    }
  }

  Future<bool> logScan({
    required String siswaId,
    required SupabaseClient supabase,
  }) async {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "⏳ Kamu sudah scan, coba lagi ${15 - diff.inHours} jam lagi",
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return false;
        }
      }

      final scannedBy =
          supabase.auth.currentUser?.email ?? supabase.auth.currentUser?.id;
      await supabase.from('parkir').insert({
        'siswa_id': siswaId,
        'scanned_by': scannedBy,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;
    final code = capture.barcodes.first.rawValue;
    if (code != null) {
      setState(() {
        isProcessing = true;
        showCircle = true;
      });

      await _playBeep();
      await _vibrate();

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => showCircle = false);
      });

      await _fetchUserAndNavigate(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3F37C9),
              Color(0xFF1D1879),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // 📷 Kamera Scanner
            Positioned.fill(
              child: MobileScanner(
                controller: cameraController,
                onDetect: _onDetect,
                fit: BoxFit.cover,
              ),
            ),

            // 🔦 Tombol Flash
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () {
                  cameraController.toggleTorch();
                  setState(() => torchOn = !torchOn);
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    torchOn ? Icons.flash_on : Icons.flash_off,
                    key: ValueKey(torchOn),
                    color: const Color(0xFFF8F8FF),
                    size: 30,
                  ),
                ),
              ),
            ),

            // 🟣 UI Overlay
            Column(
              children: [
                const Spacer(),
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _textAnimation.value,
                      child: const Text(
                        "ZON4",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF8F8FF),
                          shadows: [
                            Shadow(
                              blurRadius: 18,
                              color: Colors.white,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 🔳 Kotak Scan dengan efek blur & border glowing
                Center(
                  child: SizedBox(
                    height: 280,
                    width: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                border: Border.all(
                                  color: const Color(0xFFF8F8FF),
                                  width: 2.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _lineAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 280 * _lineAnimation.value,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFB0B5FF),
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                        if (showCircle)
                          AnimatedScale(
                            scale: showCircle ? 1.3 : 0,
                            duration: const Duration(milliseconds: 400),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF8F8FF),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                // 🔘 Tombol Kembali
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: const Color(0xFFF8F8FF),
                      elevation: 8,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "KEMBALI",
                      style: TextStyle(
                        color: Color(0xFF1D1879),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
