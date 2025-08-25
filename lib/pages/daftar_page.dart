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
    if (_namaController.text.isEmpty ||
        _kelasController.text.isEmpty ||
        _jurusanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field wajib diisi")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = const Uuid().v4();
      String? fotoUrl;
      String? qrUrl;

      // Upload SIM
      if (_simImage != null) {
        final fileName = "sim/$userId.png";
        if (kIsWeb) {
          final bytes = await _simImage!.readAsBytes();
          await supabase.storage.from('siswa').uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(contentType: 'image/png'),
              );
        } else {
          await supabase.storage.from('siswa').upload(
                fileName,
                File(_simImage!.path),
                fileOptions: const FileOptions(contentType: 'image/png'),
              );
        }
        fotoUrl = supabase.storage.from('siswa').getPublicUrl(fileName);
      }

      // Generate QR
      final qrPainter = QrPainter(
        data: userId,
        version: QrVersions.auto,
        gapless: true,
      );
      final picData = await qrPainter.toImageData(300);
      final bytes = picData!.buffer.asUint8List();

      final qrFileName = "qr_codes/$userId.png";
      await supabase.storage.from('siswa').uploadBinary(
            qrFileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );
      qrUrl = supabase.storage.from('siswa').getPublicUrl(qrFileName);

      // Insert DB
      await supabase.from('siswa').insert({
        'id': userId,
        'nama': _namaController.text,
        'kelas': _kelasController.text,
        'jurusan': _jurusanController.text,
        'sim_url': fotoUrl,
        'qr_url': qrUrl,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessPage(),
          ),
        );
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

                  // Upload SIM
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
                          Expanded(
                            child: Text(
                              _simImage == null
                                  ? "Upload Kartu SIM"
                                  : "SIM dipilih: ${_simImage!.name}",
                              style: const TextStyle(color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_simImage != null) ...[
                    const SizedBox(height: 10),
                    kIsWeb
                        ? Image.network(_simImage!.path, height: 120)
                        : Image.file(File(_simImage!.path), height: 120),
                  ],

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

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

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
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    size: 80, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  "Daftar Akun Berhasil",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 32),
                  ),
                  child: const Text("Kembali"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
