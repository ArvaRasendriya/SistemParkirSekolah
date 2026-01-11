import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';
import 'daftar_berhasil_page.dart';
import 'daftar_gagal_page.dart';
import 'profile_page.dart';
import 'crop_page.dart';

// UI theme constants to match register_page
const Color _primary = Color(0xFF4F46E5);
const Color _hint = Color(0xFF9EA3AE);
const Color _stroke = Color(0xFFE7E7F0);

class DaftarPageGuru extends StatefulWidget {
  const DaftarPageGuru({super.key});

  @override
  State<DaftarPageGuru> createState() => _DaftarPageGuruState();
}

class _DaftarPageGuruState extends State<DaftarPageGuru>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final mapelC = TextEditingController();
  final namaC = TextEditingController();
  final emailC = TextEditingController();


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
    mapelC.dispose();
    emailC.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Pilih Sumber Foto',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: mainBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Camera option
              _buildImageSourceOption(
                icon: Icons.camera_alt,
                title: 'Ambil Foto',
                subtitle: 'Gunakan kamera perangkat',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              
              const SizedBox(height: 12),
              
              // Gallery option
              _buildImageSourceOption(
                icon: Icons.photo_library,
                title: 'Pilih dari Galeri',
                subtitle: 'Pilih foto yang sudah ada',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            border: Border.all(color: _stroke),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mainBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: mainBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        // Navigate to crop page
        final croppedFile = await Navigator.push<File?>(
          context,
          MaterialPageRoute(
            builder: (_) => CropPage(imageFile: File(image.path)),
          ),
        );

        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          setState(() {
            _simBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengambil foto: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
  void _showLoadingDialog(String name) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Expanded(child: Text("Memproses $name...")),
        ],
      ),
    ),
  );
}

void _showSuccessDialog(String name) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Berhasil"),
      content: Text("$name berhasil disetujui"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        )
      ],
    ),
  );
}

void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Error"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        )
      ],
    ),
  );
}


Future<void> approveGuru(Map<String, dynamic> data) async {
  final guruName = data['nama'] ?? 'Guru';

  _showLoadingDialog(guruName);

  try {
    final id = data["id"];

    final qrValidationResult = QrValidator.validate(
      data: id,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.Q,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception("QR Code tidak valid");
    }

    final painter = QrPainter.withQr(
      qr: qrValidationResult.qrCode!,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );

    final uiImage = await painter.toImage(300);
    final byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final qrBytes = byteData!.buffer.asUint8List();

    final simFileName = "${DateTime.now().millisecondsSinceEpoch}.png";
    final qrPath = "qr/$simFileName";

    await supabase.storage.from("siswa").uploadBinary(
          qrPath,
          qrBytes,
          fileOptions: const FileOptions(contentType: "image/png"),
        );
      
    final simPath = "sim/$simFileName";
      await supabase.storage.from("siswa").uploadBinary(
        simPath,
        _simBytes!,
        fileOptions: const FileOptions(contentType: "image/jpeg"),
      );

    await supabase.from("guru").insert({
      "id": id,
      "nama": data["nama"],
      "mapel": data["mapel"],
      "email": data["email"],
      "sim_url": simPath,
      "qr_url": qrPath,
      "created_at": DateTime.now().toIso8601String(),
    });

    Future.microtask(() async {
      try {
        final qrUrl =
            supabase.storage.from("siswa").getPublicUrl(qrPath);

        await supabase.functions.invoke(
          "sendEmailQr",
          body: {
            "email": data["email"],
            "nama": data["nama"],
            "mapel": data["mapel"],
            "qr_url": qrUrl,
          },
        );
      } catch (e) {
        debugPrint("Email error: $e");
      }
    });

    Navigator.pop(context);
    _showSuccessDialog(guruName);
  } catch (e) {
    Navigator.pop(context);
    if (mounted) {
      _showErrorDialog(e.toString());
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;
    final simFileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";

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
                  "Daftarkan Data Guru",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: whiteColor,
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
                  "Silahkan isi data dengan benar!",
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

                      _buildLabel("Mata Pelajaran"),
                      _buildTextField(mapelC, "Contoh: Matematika", Icons.book),
                      const SizedBox(height: 16),


                      _buildLabel("Email"),
                      _buildTextField(emailC, "john_doe67@gmail.com", Icons.email,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),

                      _buildLabel("Foto SIM"),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _simBytes == null 
                                ? Colors.white 
                                : const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _simBytes == null 
                                  ? _stroke 
                                  : const Color(0xFF4CAF50),
                              width: 2,
                            ),
                          ),
                          child: _simBytes == null
                              ? Column(
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Ambil atau Pilih Foto SIM",
                                      style: GoogleFonts.poppins(
                                        color: blackColor.withOpacity(0.6),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Tap untuk memilih",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        _simBytes!,
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF4CAF50),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Foto berhasil dipilih",
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF4CAF50),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Tap untuk mengganti foto",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 60 : 70,
                        child: ElevatedButton(
                          onPressed: _isLoading
                                    ? null
                                    : () {
                                        approveGuru({
                                          "id": const Uuid().v4(),
                                          "nama": namaC.text,
                                          "mapel": mapelC.text,
                                          "email": emailC.text,
                                          "sim_url": "sim/$simFileName",
                                        });
                                      },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
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
    value: value,
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
              color: (textColor ?? Colors.white).withOpacity(0.7),
            )
          : null,
      filled: true,
      fillColor: fillColor ?? Colors.black.withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
  );
}