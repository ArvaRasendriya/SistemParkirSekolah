
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // ✅ untuk kIsWeb
import 'package:vibration/vibration.dart'; // ✅ vibration
import 'package:uuid/uuid.dart'; // ✅ cek UUID valid
import 'dart:async';
import 'qr_result_page.dart';
import 'gagal_scan_page.dart';

// ✅ UI untuk QR gagal
class DaftarGagalPage extends StatelessWidget {
  const DaftarGagalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade400,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, size: 100, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "Identitas Tidak Valid",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Kembali"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Halaman QR Scan
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

    // animasi garis scanner
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _lineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.linear),
    );

    // animasi teks pulse
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _textAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
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

  // ✅ fungsi cek apakah input valid UUID
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
      debugPrint("📌 Scanned code: $userId");

      // ✅ cek dulu UUID valid
      if (!isValidUuid(userId)) {
        if (!mounted) return;
        setState(() => isProcessing = false);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DaftarGagalPage()),
        );
        return;
      }

      // kalau valid UUID → baru query Supabase
      final response =
          await supabase.from('siswa').select().eq('id', userId).maybeSingle();

      if (response != null) {
        final success = await logScan(siswaId: userId, supabase: supabase);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Gagal mencatat riwayat parkir")),
          );
        }

        if (!mounted) return;
        setState(() => isProcessing = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultPage(userData: response),
          ),
        );
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
      debugPrint('Failed to log scan: $e');
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

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => showCircle = false);
        }
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
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: cameraController,
                onDetect: _onDetect,
                fit: BoxFit.cover,
              ),
            ),
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
                    color: Colors.cyanAccent,
                    size: 30,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const Spacer(),
                SizedBox(
                  width: 250,
                  child: AnimatedBuilder(
                    animation: _textAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _textAnimation.value,
                        child: const Text(
                          "ZON4",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 12,
                                color: Colors.cyanAccent,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    height: 300,
                    width: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.cyanAccent.withOpacity(0.9),
                                width: 3),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.5),
                                blurRadius: 25,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _lineAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 300 * _lineAnimation.value,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.cyanAccent, Colors.white],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          },
                        ),
                        if (showCircle)
                          AnimatedScale(
                            scale: showCircle ? 1.5 : 0,
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.cyanAccent,
                      shadowColor: Colors.black45,
                      elevation: 6,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "KEMBALI",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

