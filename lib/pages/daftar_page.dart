import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // buat kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  final _namaController = TextEditingController();
  final _kelasController = TextEditingController();
  final _jurusanController = TextEditingController();

  XFile? _simImage;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> _pickSimImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _simImage = picked;
      });
    }
  }

  Future<void> _DaftarUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Buat unique id siswa
      final userId = const Uuid().v4();
      String? fotoUrl;
      String? qrUrl;

      // 2. Upload SIM ke Supabase Storage (support Web + Mobile)
      if (_simImage != null) {
        final fileName = "sim/$userId.png"; // 📂 masuk folder sim/

        if (kIsWeb) {
          // 📌 Web: uploadBinary
          final bytes = await _simImage!.readAsBytes();
          await supabase.storage.from('siswa').uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(contentType: 'image/png'),
              );
        } else {
          // 📌 Mobile: upload File
          await supabase.storage.from('siswa').upload(
                fileName,
                File(_simImage!.path),
                fileOptions: const FileOptions(contentType: 'image/png'),
              );
        }

        fotoUrl = supabase.storage.from('siswa').getPublicUrl(fileName);
      }

      // 3. Generate QR Code dari userId
      final qrPainter = QrPainter(
        data: userId,
        version: QrVersions.auto,
        gapless: true,
      );
      final picData = await qrPainter.toImageData(300);
      final bytes = picData!.buffer.asUint8List();

      // 4. Upload QR Code ke Supabase Storage
      final qrFileName = "qr_codes/$userId.png"; // 📂 masuk folder qr_codes/

      await supabase.storage.from('siswa').uploadBinary(
            qrFileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );

      qrUrl = supabase.storage.from('siswa').getPublicUrl(qrFileName);

      // 5. Insert data ke tabel siswa
      await supabase.from('siswa').insert({
        'id': userId,
        'nama': _namaController.text,
        'kelas': _kelasController.text,
        'jurusan': _jurusanController.text,
        'sim_url': fotoUrl,
        'qr_url': qrUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pendaftaran berhasil!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                  _buildTextField(_namaController, "Nama", Icons.person),
                  const SizedBox(height: 12),
                  _buildTextField(_kelasController, "Kelas", Icons.class_),
                  const SizedBox(height: 12),
                  _buildTextField(_jurusanController, "Jurusan", Icons.school),
                  const SizedBox(height: 12),

                  // tombol upload SIM
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
                            _simImage == null
                                ? "Upload Kartu SIM"
                                : "SIM dipilih",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _DaftarUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 32),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Selesai"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
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
