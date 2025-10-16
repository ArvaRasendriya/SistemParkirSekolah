import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'daftar_berhasil_page.dart';
import 'daftar_gagal_page.dart';
import 'profile_page.dart';
import 'sim_scanner.dart';

// UI theme constants to match register_page
const Color _primary = Color(0xFF4F46E5);
const Color _hint = Color(0xFF9EA3AE);
const Color _stroke = Color(0xFFE7E7F0);

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

  static const Color mainBlue = Color(0xFF3F37C9);
  static const Color gradientStart = Color(0xFF3F37C9);
  static const Color gradientEnd = Color(0xFF1D1879);
  static const Color whiteColor = Color(0xFFF8F8FF);
  static const Color blackColor = Color(0xFF313638);

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

      final simFileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final simPath = "sim/$simFileName";
      await supabase.storage.from("siswa").uploadBinary(
        simPath,
        _simBytes!,
        fileOptions: const FileOptions(contentType: "image/jpeg"),
      );

      final response = await supabase.from("pending_siswa").insert({
        "id": id,
        "nama": namaC.text,
        "kelas": kelasC.text,
        "jurusan": jurusanC.text,
        "email": emailC.text,
        "sim_url": simPath,
        "created_at": DateTime.now().toIso8601String(),
      }).select();

      debugPrint("Insert response: $response");

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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainBlue,
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
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradientStart,
              gradientEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Daftarkan Data Siswa",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w900,
                    fontSize: 26,                    color: whiteColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Silahkan isi data dengan benar",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: whiteColor.withOpacity(0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Nama"),
                      _buildTextField(namaC, "John Doe", Icons.person),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Kelas", fontSize: 14),
                                const SizedBox(height: 6),
                                _buildDropdown(
                                  _selectedGrade,
                                  grades,
                                  "X",
                                  (String? newValue) {
                                    setState(() {
                                      _selectedGrade = newValue;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Jurusan", fontSize: 14),
                                const SizedBox(height: 6),
                                _buildDropdown(
                                  _selectedMajor,
                                  majors,
                                  "RPL",
                                  (String? newValue) {
                                    setState(() {
                                      _selectedMajor = newValue;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Rombel", fontSize: 14),
                                const SizedBox(height: 6),
                                _buildDropdown(
                                  _selectedClass,
                                  classes,
                                  "3",
                                  (String? newValue) {
                                    setState(() {
                                      _selectedClass = newValue;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildLabel("Jurusan"),
                      _buildDropdown(
                        _selectedJurusan,
                        jurusans,
                        "Pilih Jurusan",
                        (String? newValue) {
                          setState(() {
                            _selectedJurusan = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildLabel("Email"),
                      _buildTextField(emailC, "john_doe67@gmail.com", Icons.email,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),

                      _buildLabel("Foto Sim"),
                      GestureDetector(
                        onTap: _pickSimImage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: whiteColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: whiteColor.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                color: _simBytes == null ? Colors.grey : Colors.greenAccent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _simBytes == null ? "Pilih Foto Sim" : "SIM berhasil dipilih",
                                  style: GoogleFonts.poppins(
                                    color: blackColor.withOpacity(0.7),
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
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 60 : 80,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _daftarUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: whiteColor,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {double fontSize = 15}) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Lato',
        fontWeight: FontWeight.w900,
        color: _primary,
      ).copyWith(fontSize: fontSize),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData? icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return CustomInputField(
      controller: controller,
      hintText: hint,
      icon: icon,
      keyboardType: keyboardType,
      textStyle: const TextStyle(
        fontSize: 15,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w700,
        color: Color(0xFF313638)
      ),
      hintStyle: const TextStyle(
        fontSize: 15,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w700,
        color: Color(0xFF313638)
      ),
      textColor: Colors.black87,
      hintColor: Colors.black38,
      fillColor: Colors.white,
    );
  }

  Widget _buildDropdown(String? value, List<String> items, String? hint,
      ValueChanged<String?> onChanged) {
    return buildDropdown(
      value: value,
      hint: hint ?? items.first,
      items: items,
      onChanged: onChanged,
      hasIcon: false,
      textColor: Colors.black87,
      hintColor: Colors.black54,
      fillColor: Colors.white,
      dropdownColor: Colors.white,
    );
  }
}

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData? icon;
  final Widget? suffixIcon;
  final Color? textColor;
  final Color? hintColor;
  final Color? fillColor;
  final TextInputType keyboardType;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.icon,
    this.suffixIcon,
    this.textColor,
    this.hintColor,
    this.fillColor,
    this.keyboardType = TextInputType.text,
    this.textStyle,
    this.hintStyle
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: textColor ?? Colors.black),
      cursorColor: textColor ?? Colors.black,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: (textColor ?? Colors.black).withOpacity(0.7)) : null,
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(
          color: hintColor ?? Colors.black.withOpacity(0.3),
          fontSize: 14,
          fontFamily: 'Lato',
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: fillColor ?? Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _stroke, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.6),
        ),
      ),
    );
  }
}

Widget buildDropdown({
  required String? value,
  required String hint,
  required List<String> items,
  required ValueChanged<String?> onChanged,
  bool hasIcon = true,
  Color? textColor,
  Color? hintColor,
  Color? fillColor,
  Color? dropdownColor,
}) {
  return DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    hint: Container(
      alignment: Alignment.center,
      child: Text(
        hint,
        style: TextStyle(color: hintColor ?? Colors.white, fontSize: 14),
      ),
    ),
    dropdownColor: dropdownColor ?? const Color(0xFF203A43),
    style: TextStyle(color: textColor ?? Colors.white, fontSize: 14),
    items: items.map((String v) {
      return DropdownMenuItem<String>(
        value: v,
        child: Text(
          v,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor ?? Colors.white, fontSize: 14),
        ),
      );
    }).toList(),
    onChanged: onChanged,
    decoration: InputDecoration(
      prefixIcon: hasIcon
          ? Icon(
              Icons.school,
              color: (textColor ?? Colors.white).withValues(alpha: 0.7),
            )
          : null,
      filled: true,
      fillColor: fillColor ?? Colors.black.withValues(alpha: 0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
