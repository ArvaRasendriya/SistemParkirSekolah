import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'daftar_berhasil_page.dart';
import 'daftar_gagal_page.dart';

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  final supabase = Supabase.instance.client;

  final namaC = TextEditingController();
  final kelasC = TextEditingController();
  final jurusanC = TextEditingController();
  final emailC = TextEditingController();

  Uint8List? _simImageBytes;
  bool _isLoading = false;

  // Ambil foto SIM
  Future<void> _pickSimImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _simImageBytes = bytes;
      });
    }
  }

  Future<void> _daftarUser() async {
    try {
      if (_simImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih foto SIM dulu")),
        );
        return;
      }

      setState(() => _isLoading = true);

      final id = const Uuid().v4();

      // 1. Upload SIM
      final simFileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final simPath = "sim/$simFileName";
      await supabase.storage.from("siswa").uploadBinary(
        simPath,
        _simImageBytes!,
        fileOptions: const FileOptions(contentType: "image/jpeg"),
      );
      final simUrl = supabase.storage.from("siswa").getPublicUrl(simPath);

      // 2. Insert siswa
      await supabase.from("siswa").insert({
        "id": id,
        "nama": namaC.text,
        "kelas": kelasC.text,
        "jurusan": jurusanC.text,
        "email": emailC.text,
        "sim_url": simUrl,
      });

      // 3. Generate QR with white background and padding
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const qrSize = 300.0;
      const padding = 10.0;
      const totalSize = qrSize + 2 * padding;

      // Draw white background
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, totalSize, totalSize), paint);

      // Draw QR code with padding
      canvas.save();
      canvas.translate(padding, padding);
      final qrPainter = QrPainter(
        data: id,
        version: QrVersions.auto,
        gapless: true,
      );
      qrPainter.paint(canvas, Size(qrSize, qrSize));
      canvas.restore();

      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(totalSize.toInt(), totalSize.toInt());
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List qrBytes = byteData!.buffer.asUint8List();

      // 4. Upload QR
      final qrFileName = "${id}_qr.png";
      final qrPath = "qr_codes/$qrFileName";
      await supabase.storage.from("siswa").uploadBinary(
        qrPath,
        qrBytes,
        fileOptions: const FileOptions(contentType: "image/png"),
      );
      final qrUrl = supabase.storage.from("siswa").getPublicUrl(qrPath);

      // 5. Update siswa dengan qr_url
      await supabase.from("siswa").update({
        "qr_url": qrUrl,
      }).eq("id", id);

      // 6. Kirim email lewat Edge Function
      final response = await supabase.functions.invoke(
        "sendEmailQr",
        body: {
          "email": emailC.text,
          "nama": namaC.text,
          "kelas": kelasC.text,
          "jurusan": jurusanC.text,
          "qr_url": qrUrl,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DaftarBerhasilPage()),
          );
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DaftarGagalPage()),
          );
        }
      }
    } catch (e) {
      debugPrint("Error daftar: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DaftarGagalPage()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Daftar Akun Siswa",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(namaC, "Nama", Icons.person),
                  const SizedBox(height: 12),
                  _buildTextField(kelasC, "Kelas", Icons.class_),
                  const SizedBox(height: 12),
                  _buildTextField(jurusanC, "Jurusan", Icons.school),
                  const SizedBox(height: 12),
                  _buildTextField(emailC, "Email", Icons.email,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),

                  // Tombol upload SIM
                  GestureDetector(
                    onTap: _pickSimImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.credit_card, color: Colors.grey),
                          const SizedBox(width: 10),
                          Text(
                            _simImageBytes == null
                                ? "Upload Kartu SIM"
                                : "SIM dipilih",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tombol submit
                  ElevatedButton(
                    onPressed: _isLoading ? null : _daftarUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 32,
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Selesai"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
