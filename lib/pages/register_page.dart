import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:tefa_parkir/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final authservice = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

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

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false; 
  bool _obscurePassword = true; 
  bool _obscureConfirmPassword = true; 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  void signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password tidak cocok")),
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
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sukses'),
            content: const Text(
                'Registerasi berhasil! Mohon cek email mu untuk verifikasi ya!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e is AuthException) {
          errorMessage = e.message;
          if (errorMessage.contains('already registered') ||
              errorMessage.contains('User already registered')) {
            errorMessage = 'Email telah terdaftar, tolong coba email lain.';
          } else if (errorMessage.contains('Invalid email')) {
            errorMessage = 'Format email invalid.';
          } else if (errorMessage.contains('Password should be at least')) {
            errorMessage = 'Password harus setidaknya 6 karakter atau lebih.';
          }
        } else {
          errorMessage = 'An error occurred: $e';
        }
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 28),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Logo animasi
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 200,
                    height: 200,
                  ),
                ),

                const SizedBox(height: 32),

                CustomInputField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.email,
                ),
                const SizedBox(height: 16),

                CustomInputField(
                  controller: _passwordController,
                  hintText: 'Kata Sandi',
                  obscureText: _obscurePassword,
                  icon: Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                CustomInputField(
                  controller: _confirmPasswordController,
                  hintText: 'Konfirmasi Kata Sandi',
                  obscureText: _obscureConfirmPassword,
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                CustomInputField(
                  controller: _fullNameController,
                  hintText: 'Nama Lengkap',
                  icon: Icons.person,
                ),
                const SizedBox(height: 20),

                // Row dropdown
                Row(
                  children: [
                    Expanded(
                      child: buildDropdown(
                        value: _selectedGrade,
                        hint: "Kelas",
                        items: grades,
                        onChanged: (v) => setState(() => _selectedGrade = v),
                        hasIcon: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildDropdown(
                        value: _selectedMajor,
                        hint: "Jurusan",
                        items: majors,
                        onChanged: (v) => setState(() => _selectedMajor = v),
                        hasIcon: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildDropdown(
                        value: _selectedClass,
                        hint: "Rombel",
                        items: classes,
                        onChanged: (v) => setState(() => _selectedClass = v),
                        hasIcon: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                buildDropdown(
                  value: _selectedJurusan,
                  hint: "Jurusan",
                  items: jurusans,
                  onChanged: (v) => setState(() => _selectedJurusan = v),
                  hasIcon: false,
                ),
                const SizedBox(height: 28),

                // Tombol Daftar dengan animasi warna
                GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) {
                    setState(() => _isPressed = false);
                    signUp();
                  },
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: _isPressed
                            ? [const Color(0xFF2C5364), const Color(0xFF203A43)]
                            : [const Color(0xFF203A43), const Color(0xFF2C5364)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Daftar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Sudah punya akun?",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    "Masuk disini!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
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
    bool hasIcon = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      hint: Container(
        alignment: Alignment.center,
        child: Text(hint,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      dropdownColor: const Color(0xFF203A43),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      items: items.map((String v) {
        return DropdownMenuItem<String>(
          value: v,
          child: Text(v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: hasIcon ? const Icon(Icons.school, color: Colors.white70) : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
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
  final Widget? suffixIcon;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.icon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
