import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'daftar_berhasil_page.dart';
import 'daftar_gagal_page.dart';
import 'profile_page.dart';
import 'sim_scanner.dart';

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

  String? _selectedGrade;
  String? _selectedMajor;
  String? _selectedClass;
  String? _selectedJurusan;

  static const List<String> grades = ['X', 'XI', 'XII'];
  static const List<String> majors = ['RPL', 'DKV', 'TOI', 'TAV', 'TKJ'];
  static const List<String> classes = ['1', '2', '3', '4', '5', '6'];
  static const List<String> jurusans = [
    'Rekayasa Perangkat Lunak',
    'Desain Komunikasi Visual',
    'Teknik Otomotif Industri',
    'Teknik Audio Video',
    'Teknik Komputer Jaringan'
  ];

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
    namaC.dispose();
    kelasC.dispose();
    jurusanC.dispose();
    emailC.dispose();
    super.dispose();
  }

  Future<void> _pickSimImage() async {
    try {
      final result = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => const SimScannerPage(),
        ),
      );

      if (result != null) {
        final bytes = await result.readAsBytes();

        setState(() {
          _simBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuka kamera: $e")),
      );
    }
  }

  Future<void> _daftarUser() async {
    try {
      if (_simBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih foto SIM dulu")),
        );
        return;
      }

      if (_selectedGrade == null || _selectedMajor == null || _selectedClass == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih kelas lengkap")),
        );
        return;
      }

      if (_selectedJurusan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih jurusan dulu")),
        );
        return;
      }

      kelasC.text = '$_selectedGrade $_selectedMajor $_selectedClass';
      jurusanC.text = _selectedJurusan!;

      setState(() => _isLoading = true);

      final id = const Uuid().v4();

      // 🚀 Pastikan pakai BUCKET STORAGE yang benar (contoh: "siswa")
      final simFileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final simPath = "sim/$simFileName";
      await supabase.storage.from("siswa").uploadBinary(
        simPath,
        _simBytes!,
        fileOptions: const FileOptions(contentType: "image/jpeg"),
      );
      final simUrl = supabase.storage.from("siswa").getPublicUrl(simPath);

      // 🚀 Insert ke tabel pending_siswa
      final response = await supabase.from("pending_siswa").insert({
        "id": id,
        "nama": namaC.text,
        "kelas": kelasC.text,
        "jurusan": jurusanC.text,
        "email": emailC.text,
        "sim_url": simUrl,
        "created_at": DateTime.now().toIso8601String(),
      }).select();

      debugPrint("Insert response: $response");

      // 🚀 Kalau sukses → ke berhasil page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DaftarBerhasilPage()),
        );
      }
    } catch (e) {
      debugPrint("❌ Error daftar: $e");
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

                        _buildTextField(namaC, "Nama", Icons.person),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                  _selectedGrade, grades, 'Kelas', (String? newValue) {
                                setState(() {
                                  _selectedGrade = newValue;
                                });
                              }),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDropdown(
                                  _selectedMajor, majors, 'Jurusan', (String? newValue) {
                                setState(() {
                                  _selectedMajor = newValue;
                                });
                              }),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDropdown(
                                  _selectedClass, classes, 'Rombel', (String? newValue) {
                                setState(() {
                                  _selectedClass = newValue;
                                });
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            _selectedJurusan, jurusans, 'Jurusan', (String? newValue) {
                          setState(() {
                            _selectedJurusan = newValue;
                          });
                        }),

                        const SizedBox(height: 16),
                        _buildTextField(emailC, "Email", Icons.email,
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: _pickSimImage,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.camera_alt_rounded,
                                    color: _simBytes == null
                                        ? Colors.white70
                                        : Colors.greenAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _simBytes == null
                                        ? "Pilih Foto SIM"
                                        : "SIM berhasil dipilih",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (_simBytes != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _simBytes!,
                                      width: 60,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

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

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
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

  Widget _buildDropdown<T>(T? value, List<T> items, String hint,
      void Function(T?) onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint, style: GoogleFonts.poppins(color: Colors.white)),
      items: items.map<DropdownMenuItem<T>>((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString(),
              style: GoogleFonts.poppins(color: Colors.white)),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      dropdownColor: const Color(0xFF2C5364),
      style: GoogleFonts.poppins(color: Colors.white),
      isDense: true,
    );
  }
}
