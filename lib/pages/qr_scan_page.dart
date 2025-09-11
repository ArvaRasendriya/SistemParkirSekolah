import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'qr_result_page.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool isProcessing = false;
  final supabase = Supabase.instance.client;

  Future<void> _fetchUserAndNavigate(String userId) async {
    try {
      final response =
          await supabase.from('siswa').select().eq('id', userId).maybeSingle();

      if (response != null) {
        // ✅ log scan to parkir table
        final success = await logScan(siswaId: userId, supabase: supabase); // 👈
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
        // waktu & tanggal are auto-filled by DB defaults
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
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
