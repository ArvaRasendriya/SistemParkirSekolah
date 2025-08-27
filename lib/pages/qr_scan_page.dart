import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  Map<String, dynamic>? userData;
  bool isProcessing = false;

  final supabase = Supabase.instance.client;

  Future<void> _fetchUser(String userId) async {
    try {
      final response = await supabase
          .from('siswa')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          userData = response;
        });
      } else {
        setState(() {
          userData = {"error": "❌ Data tidak ditemukan"};
        });
      }
    } catch (e) {
      setState(() {
        userData = {"error": "⚠️ Error: $e"};
      });
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;
    final code = capture.barcodes.first.rawValue;
    if (code != null) {
      setState(() => isProcessing = true);

      await _fetchUser(code);

      Future.delayed(const Duration(seconds: 3), () {
        setState(() => isProcessing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: userData == null
                  ? const Text("📷 Arahkan kamera ke QR Code")
                  : userData!.containsKey("error")
                      ? Text(userData!["error"],
                          style: const TextStyle(color: Colors.red))
                      : Card(
                          margin: const EdgeInsets.all(16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person,
                                    size: 48, color: Colors.blueAccent),
                                const SizedBox(height: 10),
                                Text(userData!["nama"] ?? "-",
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Kelas:"),
                                    Text(userData!["kelas"] ?? "-"),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Jurusan:"),
                                    Text(userData!["jurusan"] ?? "-"),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Status SIM:"),
                                    Text(userData!["statusSim"] ?? "-"),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Tanggal:"),
                                    Text(userData!["tanggal"] ?? "-"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
