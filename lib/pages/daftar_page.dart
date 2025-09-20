import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' show Platform; // 👈 untuk cek Android/iOS
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
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

  // Dropdown values for kelas
  String? _selectedGrade;
  String? _selectedMajor;
  String? _selectedClass;
  String? _selectedJurusan;

  // Dropdown options
  static const List<String> grades = ['X', 'XI', 'XII'];
  static const List<String> majors = ['RPL', 'DKV', 'TOI', 'TAV', 'TKJ'];
  static const List<String> classes = ['1', '2', '3', '4', '5', '6'];
  static const List<String> jurusans = ['Rekayasa Perangkat Lunak', 'Desain Komunikasi Visual', 'Teknik Otomotif Industri', 'Teknik Audio Video', 'Teknik Komputer Jaringan'];

  Uint8List? _simBytes;
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

  /// 🔑 Hybrid function ambil foto SIM
  Future<void> _pickSimImage() async {
    try {
      Uint8List? bytes;

      if (kIsWeb) {
        // 👉 Mode Web pakai camera
        final cameras = await availableCameras();
        final controller = CameraController(
          cameras.first,
          ResolutionPreset.medium,
        );
        await controller.initialize();

        final picture = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _CameraCapturePage(controller: controller),
          ),
        );

        controller.dispose();
        if (picture != null) {
          bytes = await picture.readAsBytes();
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 👉 Mode Mobile pakai image_picker
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: 85,
        );
        if (picked != null) {
          bytes = await picked.readAsBytes();
        }
      }

      if (bytes != null) {
        setState(() => _simBytes = bytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal ambil foto SIM")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error ambil foto SIM: $e")),
      );
    }
  }

  /// 🔑 Proses daftar user (punya kamu tetap sama)
  Future<void> _daftarUser() async {
    try {
      if (_simBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto SIM dulu sebelum daftar")),
        );
        return;
      }

      // Set kelas from dropdowns
      if (_selectedGrade != null && _selectedMajor != null && _selectedClass != null) {
        kelasC.text = '$_selectedGrade $_selectedMajor $_selectedClass';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih kelas lengkap")),
        );
        return;
      }

      // Set jurusan from dropdown
      if (_selectedJurusan != null) {
        jurusanC.text = _selectedJurusan!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih jurusan")),
        );
        return;
      }

      setState(() => _isLoading = true);

      final id = const Uuid().v4();

      final simFileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final simPath = "sim/$simFileName";
      await supabase.storage.from("siswa").uploadBinary(
        simPath,
        _simBytes!,
        fileOptions: const FileOptions(contentType: "image/jpeg"),
      );
      final simUrl = supabase.storage.from("siswa").getPublicUrl(simPath);

      await supabase.from("siswa").insert({
        "id": id,
        "nama": namaC.text,
        "kelas": kelasC.text,
        "jurusan": jurusanC.text,
        "email": emailC.text,
        "sim_url": simUrl,
      });

      final qrPainter = QrPainter(
        data: id,
        version: QrVersions.auto,
        gapless: true,
      );

      final uiImage = await qrPainter.toImage(300);
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
                            _simBytes == null
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

/// 👇 Halaman kamera khusus Web
class _CameraCapturePage extends StatelessWidget {
  final CameraController controller;
  const _CameraCapturePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ambil Foto SIM")),
      body: CameraPreview(controller),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera_alt),
        onPressed: () async {
          final picture = await controller.takePicture();
          Navigator.pop(context, picture);
        },
      ),
    );
  }
}
