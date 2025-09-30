import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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
        backgroundColor: const Color(0xFF0F2027),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
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
                        "Edit Profil",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Ubah data profil Anda",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 28),

                      _buildTextField(nameController, "Nama Lengkap", Icons.person),
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
                      _buildTextField(jadwalController, "Jadwal Piket", Icons.schedule),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF203A43),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 40),
                          elevation: 5,
                        ),
                        child: Text(
                          "Simpan Perubahan",
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
