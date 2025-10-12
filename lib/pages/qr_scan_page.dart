import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'qr_result_page.dart';

// ✅ UI untuk QR gagal
class DaftarGagalPage extends StatelessWidget {
  const DaftarGagalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B3EFF), // 🟣 warna utama tema
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, size: 100, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                "Identitas Tidak Valid",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B3EFF),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B3EFF),
                  foregroundColor: Colors.white,
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
        // 🎨 ubah ke tema biru-ungu
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3B3EFF), // ungu terang
              Color(0xFF2A2AFF), // biru-ungu
              Color(0xFF1E1E99), // biru gelap
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                icon: Icon(
                  torchOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Column(
              children: [
                const Spacer(),
                const Text(
                  "ZON4",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.white70,
                        offset: Offset(0, 0),
                      ),
                    ],
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
                                color: Colors.white.withOpacity(0.9), width: 3),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
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
                                    colors: [
                                      Color(0xFFB3A7FF),
                                      Colors.white,
                                    ],
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
                                color: Color(0xFFB3A7FF),
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
                      backgroundColor: const Color(0xFFB3A7FF),
                      foregroundColor: Colors.black87,
                      elevation: 6,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "KEMBALI",
                      style: TextStyle(
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
