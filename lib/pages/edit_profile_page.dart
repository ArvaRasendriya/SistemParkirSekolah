import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// UI theme constants to match register_page
const Color _primary = Color(0xFF4F46E5);
const Color _hint = Color(0xFF9EA3AE);
const Color _stroke = Color(0xFFE7E7F0);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color mainBlue = Color(0xFF3F37C9);
  static const Color gradientStart = Color(0xFF3F37C9);
  static const Color gradientEnd = Color(0xFF1D1879);
  static const Color whiteColor = Color(0xFFF8F8FF);
  static const Color blackColor = Color(0xFF313638);
  final supabase = Supabase.instance.client;
  final nameController = TextEditingController();
  final kelasController = TextEditingController();
  final jadwalController = TextEditingController();

  String? _selectedGrade;
  String? _selectedMajor;
  String? _selectedClass;

  static const List<String> grades = ['X', 'XI', 'XII'];
  static const List<String> majors = ['RPL', 'DKV', 'TOI', 'TAV', 'TKJ'];
  static const List<String> classes = ['1', '2', '3', '4', '5', '6'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data != null) {
      nameController.text = data['full_name'] ?? '';
      final kelas = data['kelas'] ?? '';
      kelasController.text = kelas;
      jadwalController.text = data['jadwal_piket'] ?? '';

      // Parse kelas to set dropdowns
      final parts = kelas.split(' ');
      if (parts.length >= 3) {
        _selectedGrade = parts[0];
        _selectedMajor = parts[1];
        _selectedClass = parts[2];
      }
    }
  }

  Future<void> _updateProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (_selectedGrade == null || _selectedMajor == null || _selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih kelas lengkap")),
      );
      return;
    }

    kelasController.text = '$_selectedGrade $_selectedMajor $_selectedClass';

    await supabase.from('profiles').update({
      'full_name': nameController.text,
      'kelas': kelasController.text,
      'jadwal_piket': jadwalController.text,
    }).eq('id', user.id);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Data berhasil disimpan")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(color: Colors.white),
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
            const SizedBox(height: 60),
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
                      _buildLabel("Edit Profil", fontSize: 26),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Text(
                          "Ubah data profil Anda",
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: whiteColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      _buildLabel("Nama"),
                      _buildTextField(nameController, "John Doe", Icons.person),
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

                      _buildLabel("Jadwal Piket"),
                      _buildTextField(jadwalController, "Senin", Icons.schedule),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            "Simpan Perubahan",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: whiteColor,
                            ),
                          ),
                        ),
                      ),
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
        color: blackColor,
      ),
      hintStyle: const TextStyle(
        fontSize: 15,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w700,
        color: blackColor,
      ).copyWith(color: Colors.black.withOpacity(0.3)),
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

class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final TextInputType keyboardType;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final Color textColor;
  final Color hintColor;
  final Color fillColor;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.icon,
    this.keyboardType = TextInputType.text,
    required this.textStyle,
    required this.hintStyle,
    required this.textColor,
    required this.hintColor,
    required this.fillColor,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      style: widget.textStyle.copyWith(color: widget.textColor),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: widget.hintStyle.copyWith(color: widget.hintColor),
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, color: _focusNode.hasFocus ? _primary : _hint, size: 22)
            : null,
        filled: true,
        fillColor: widget.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}

Widget buildDropdown({
  required String? value,
  required String? hint,
  required List<String> items,
  required ValueChanged<String?> onChanged,
  bool hasIcon = false,
  Color textColor = Colors.black87,
  Color hintColor = Colors.black54,
  Color fillColor = Colors.white,
  Color dropdownColor = Colors.white,
}) {
  return DropdownButtonFormField<String>(
    value: value,
    hint: Text(
      hint ?? items.first,
      style: TextStyle(
        fontFamily: 'Lato',
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: hintColor,
      ),
    ),
    items: items.map<DropdownMenuItem<String>>((String item) {
      return DropdownMenuItem<String>(
        value: item,
        child: Text(
          item,
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: textColor,
          ),
        ),
      );
    }).toList(),
    onChanged: onChanged,
    decoration: InputDecoration(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
    ),
    dropdownColor: dropdownColor,
    style: TextStyle(
      fontFamily: 'Lato',
      fontWeight: FontWeight.w700,
      fontSize: 15,
      color: textColor,
    ),
    isDense: true,
  );
}
