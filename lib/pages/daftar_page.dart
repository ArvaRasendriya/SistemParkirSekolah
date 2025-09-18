import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'daftar_berhasil_page.dart';
import 'daftar_gagal_page.dart';
import 'profile_page.dart';

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  final namaC = TextEditingController();
  final kelasC = TextEditingController();
  final jurusanC = TextEditingController();
  final emailC = TextEditingController();

  File? _simImage;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickSimImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

    if (picked != null) {
      setState(() {
        _simImage = File(picked.path);
      });
    }
  }

  Future<void> _daftarUser() async {
    try {
      if (_simImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto SIM dulu sebelum daftar")),
        );
        return;
      }

      setState(() => _isLoading = true);

      final id = const Uuid().v4();

      final simFileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final simPath = "sim/$simFileName";
      await supabase.storage.from("siswa").upload(simPath, _simImage!);
      final simUrl = supabase.storage.from("siswa").getPublicUrl(simPath);

      await supabase.from("siswa").insert({
        "id": id,
        "nama": namaC.text,
        "kelas": kelasC.text,
        "jurusan": jurusanC.text,
        "email": emailC.text,
        "sim_url": simUrl,
      });

      // 3. Generate QR
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

      final qrFileName = "${id}_qr.png";
      final qrPath = "qr_codes/$qrFileName";
      await supabase.storage.from("siswa").uploadBinary(
        qrPath,
        qrBytes,
        fileOptions: const FileOptions(contentType: "image/png"),
      );
      final qrUrl = supabase.storage.from("siswa").getPublicUrl(qrPath);

      await supabase.from("siswa").update({
        "qr_url": qrUrl,
      }).eq("id", id);

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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2027),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          "Daftar Akun Siswa",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Silakan isi data diri dengan benar",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Text Fields
                        _buildTextField(namaC, "Nama", Icons.person),
                        const SizedBox(height: 16),
                        _buildTextField(kelasC, "Kelas", Icons.class_),
                        const SizedBox(height: 16),
                        _buildTextField(jurusanC, "Jurusan", Icons.school),
                        const SizedBox(height: 16),
                        _buildTextField(
                          emailC,
                          "Email",
                          Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

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
                            _simImage == null
                                ? "Upload Kartu SIM"
                                : "SIM dipilih",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),

                        const SizedBox(height: 32),

                        // Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _daftarUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF203A43),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 40),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Selesai",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70, size: 22),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}
