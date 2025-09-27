import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:tefa_parkir/pages/register_page.dart';
import 'package:tefa_parkir/pages/profile_page.dart';
import 'package:tefa_parkir/pages/admin_dashboard_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation =
        Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // === LOGIN DENGAN CEK ROLE (robust terhadap user.id null) ===
  void login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan password harus diisi")),
      );
      return;
    }

    try {
      await authService.signInWithEmailPassword(email, password);
      final supabase = Supabase.instance.client;
      final User? currentUser =
          supabase.auth.currentUser ?? supabase.auth.currentSession?.user;

      if (currentUser == null) {
        // Artinya sign-in mungkin gagal atau AuthService tidak meng-set session
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Login sepertinya berhasil tapi user tidak ditemukan. Cek implementasi AuthService."),
          ),
        );
        return;
      }

      final uid = currentUser.id;

      // 3) Ambil role (dan optional status) dari tabel profiles
      final profile = await supabase
          .from('profiles')
          .select('role, status')
          .eq('id', uid)
          .maybeSingle();

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile tidak ditemukan di tabel profiles")),
        );
        return;
      }

      final role = (profile['role'] as String?)?.toLowerCase();
      final status = (profile['status'] as String?)?.toLowerCase();

      // (Optional) contoh: blokir kalau status = 'pending' atau 'inactive'
      if (status != null && (status == 'pending' || status == 'inactive')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Akun Anda belum aktif (status: $status)")),
        );
        return;
      }

      // 4) Navigate sesuai role
      if (!mounted) return;
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else if (role == 'satgas') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Role tidak dikenali: $role")),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('not approved')) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Approval Required'),
                content: const Text('You are not approved by an admin yet.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      authService.signOut();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saat login: $e")),
          );
        }
      }
    }
  }

  InputDecoration _transparentDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),

                  // Animasi logo
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      'assets/logo.png',
                      width: 240,
                      height: 240,
                    ),
                  ),

                  const SizedBox(height: 40),

                  CustomInputField(
                    controller: _emailController,
                    hintText: 'Email',
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: _transparentDecoration('Kata Sandi').copyWith(
                      suffixIcon: IconButton(
                        splashRadius: 20,
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: const Color(0xFF2C5364),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: Colors.black45,
                      ),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    "Tidak punya akun?",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Daftar disini!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      ),
    );
  }
}
