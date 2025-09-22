import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:tefa_parkir/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final authservice = AuthService();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  // Dropdown values
  String? _selectedGrade;
  String? _selectedMajor;
  String? _selectedClass;
  String? _selectedJurusan;

  // Dropdown options
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

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  void signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password don't match")),
      );
      return;
    }

    try {
      final response =
          await authservice.signUpWithEmailPassword(email, password);
      final user = response.user;
      if (user != null) {
        final fullName = _fullNameController.text.trim();
        final kelas = _selectedGrade != null &&
                _selectedMajor != null &&
                _selectedClass != null
            ? '$_selectedGrade $_selectedMajor $_selectedClass'
            : '';
        final jurusan = _selectedJurusan ?? '';

        if (fullName.isEmpty || kelas.isEmpty || jurusan.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please fill in all required fields")),
          );
          return;
        }

        await authservice.createProfile(user.id, email,
            full_name: fullName, kelas: kelas, jurusan: jurusan);
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    'Zona\$',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 100),

                  // Email
                  CustomInputField(
                    controller: _emailController,
                    hintText: 'Email',
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 15),

                  // Password
                  CustomInputField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    icon: Icons.lock,
                  ),
                  const SizedBox(height: 15),

                  // Confirm Password
                  CustomInputField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 15),

                  // Full Name
                  CustomInputField(
                    controller: _fullNameController,
                    hintText: 'Full Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 15),

                  // Row dropdown
                  Row(
                    children: [
                      Expanded(
                        child: buildDropdown(
                          value: _selectedGrade,
                          hint: "Grade",
                          items: grades,
                          onChanged: (v) => setState(() => _selectedGrade = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildDropdown(
                          value: _selectedMajor,
                          hint: "Major",
                          items: majors,
                          onChanged: (v) => setState(() => _selectedMajor = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildDropdown(
                          value: _selectedClass,
                          hint: "Class",
                          items: classes,
                          onChanged: (v) => setState(() => _selectedClass = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  buildDropdown(
                    value: _selectedJurusan,
                    hint: "Jurusan",
                    items: jurusans,
                    onChanged: (v) => setState(() => _selectedJurusan = v),
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      foregroundColor: Colors.blueGrey[900],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                    ),
                    onPressed: signUp,
                    child: const Text(
                      'Sign Up',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    "Already have an account?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Sign in here!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      items: items.map((String v) {
        return DropdownMenuItem<String>(
          value: v,
          child: Text(v),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.school, color: Colors.black54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7), // semi transparan
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData? icon;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.black54)
            : null, // ikon kecil di kiri
        hintText: hintText,
        filled: true,
        fillColor: Colors.white.withOpacity(0.7), // semi transparan
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.black45),
      ),
    );
  }
}
