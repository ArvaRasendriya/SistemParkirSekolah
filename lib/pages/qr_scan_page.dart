import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/user_data.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  String? scannedData;
  bool isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (isProcessing) return; // biar ga spam detect
    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          isProcessing = true;
          scannedData = code;
        });

        // kasih delay sedikit sebelum bisa scan lagi
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            isProcessing = false;
          });
        });
      }
    }
  }

  Widget _buildUserInfo(String data) {
    try {
      final decoded = jsonDecode(data);
      final user = UserData.fromJson(decoded);

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Nama: ${user.nama}"),
          Text("Status SIM: ${user.statusSim}"),
          Text("Tanggal: ${user.tanggal}"),
          Text("Waktu: ${user.waktu}"),
          Text("Jenis: ${user.jenis}"),
          Text("No Kendaraan: ${user.noKendaraan}"),
          const SizedBox(height: 20),
          user.statusSim == "Punya SIM"
              ? const Text("✅ Punya SIM", style: TextStyle(color: Colors.green, fontSize: 18))
              : const Text("❌ Tidak punya SIM", style: TextStyle(color: Colors.red, fontSize: 18)),
        ],
      );
    } catch (e) {
      return const Text("QR Code tidak valid");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Kamera scanner
          Expanded(
            flex: 4,
            child: MobileScanner(
              onDetect: _onDetect,
            ),
          ),
          // Hasil scan
          Expanded(
            flex: 2,
            child: Center(
              child: scannedData != null
                  ? _buildUserInfo(scannedData!)
                  : const Text("Scan a QR Code"),
            ),
          ),
        ],
      ),
    );
  }
}
