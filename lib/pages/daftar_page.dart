import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'daftar_berhasil_page.dart';
import 'daftar_gagal_page.dart';
import 'profile_page.dart'; // ✅ Tambah import ProfilePage

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

  // Ambil foto SIM
  Future<void> _pickSimImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

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
          const SnackBar(content: Text("Pilih foto SIM dulu")),
        );
        return;
      }

      setState(() => _isLoading = true);

      final id = const Uuid().v4();

      // 1. Upload SIM
      final simFileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final simPath = "sim/$simFileName";
      await supabase.storage.from("siswa").upload(simPath, _simImage!);
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

      // 3. Generate QR
      final qrPainter = QrPainter(
        data: id,
        version: QrVersions.auto,
        gapless: true,
      );

      final uiImage = await qrPainter.toImage(300);
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
      // ✅ AppBar tetap ada
      appBar: AppBar(
        backgroundColor: const Color(0xFF2193b0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
        title: const Text(
          "",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      // ✅ REVISI BAGIAN INI (layout)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 150),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ✅ Judul lebih besar + subtitle
                        const Text(
                          "Daftar Akun Siswa",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2193b0),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Silakan isi data diri dengan benar",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 28),

                        _buildTextField(namaC, "Nama", Icons.person),
                        const SizedBox(height: 16),
                        _buildTextField(kelasC, "Kelas", Icons.class_),
                        const SizedBox(height: 16),
                        _buildTextField(jurusanC, "Jurusan", Icons.school),
                        const SizedBox(height: 16),
                        _buildTextField(emailC, "Email", Icons.email,
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 20),

                        // ✅ Tombol upload SIM lebih jelas
                        GestureDetector(
                          onTap: _pickSimImage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _simImage == null
                                  ? Colors.grey[200]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _simImage == null
                                    ? Colors.grey.shade400
                                    : Colors.green,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      color: _simImage == null
                                          ? Colors.grey
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _simImage == null
                                          ? "Upload Kartu SIM (jpg/png)"
                                          : "SIM berhasil dipilih",
                                      style: TextStyle(
                                        color: _simImage == null
                                            ? Colors.black54
                                            : Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  color: _simImage == null
                                      ? Colors.grey
                                      : Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _daftarUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2193b0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 32,
                            ),
                            elevation: 6,
                            shadowColor: Colors.black.withOpacity(0.2),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Selesai",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(icon, color: const Color(0xFF2193b0), size: 22),
        ),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
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
