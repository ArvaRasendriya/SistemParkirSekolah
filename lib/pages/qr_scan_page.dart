import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    super.dispose();
  }

  Future<void> _fetchUserAndNavigate(String userId) async {
    try {
      final response =
          await supabase.from('siswa').select().eq('id', userId).maybeSingle();

      if (response != null) {
        final success = await logScan(siswaId: userId, supabase: supabase);
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ Gagal mencatat riwayat parkir")),
            );
          }
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultPage(userData: response),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Data tidak ditemukan")),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
      setState(() => isProcessing = true);
      await _fetchUserAndNavigate(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Kamera scanner
            MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
            ),

            // Tombol flashlight dengan animasi
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
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

            // Overlay kotak scan + teks ZON4
            Column(
              children: [
                const Spacer(),

                // Teks ZON4 dengan animasi pulse
                SizedBox(
                  width: 250, // sama dengan lebar kotak QR
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
                                color: Colors.blueAccent,
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

                // Kotak QR
                SizedBox(
                  height: 300,
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white.withOpacity(0.9), width: 3),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _lineAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 40 + (180 * _lineAnimation.value),
                            left: MediaQuery.of(context).size.width / 2 - 125,
                            child: Container(
                              width: 250,
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.cyan, Colors.white],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Tombol kembali
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.white,
                      shadowColor: Colors.black45,
                      elevation: 5,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // kembali ke halaman sebelumnya
                    },
                    child: const Text(
                      "KEMBALI",
                      style: TextStyle(
                        color: Colors.black,
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
