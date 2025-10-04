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

  // ======= UI theme only (no feature change) =======
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _label = Color(0xFF5B5B6B);
  static const Color _hint = Color(0xFF9EA3AE);
  static const Color _stroke = Color(0xFFE7E7F0);
  static const Color _bg = Color(0xFFF8F8FF);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: .97, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ======= LOGIN (unchanged) =======
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Login sepertinya berhasil tapi user tidak ditemukan. Cek implementasi AuthService."),
          ),
        );
        return;
      }

      final uid = currentUser.id;

      final profile = await supabase
          .from('profiles')
          .select('role, status')
          .eq('id', uid)
          .maybeSingle();

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Profile tidak ditemukan di tabel profiles")),
        );
        return;
      }

      final role = (profile['role'] as String?)?.toLowerCase();
      final status = (profile['status'] as String?)?.toLowerCase();

      if (status != null && (status == 'pending' || status == 'inactive')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Akun Anda belum aktif (status: $status)")),
        );
        return;
      }

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

  // ======= InputDecoration (outlined, rapih) =======
  InputDecoration _outlinedDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hint, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _stroke, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    // biar nyaman saat keyboard muncul (tambah padding bawah sesuai viewInsets)
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;

    return GestureDetector(
      // tap luar untuk tutup keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    // IntrinsicHeight + Spacer => konten benar2 center secara vertikal
                    child: IntrinsicHeight(
                      child: Center(
                        child: Padding(
                          // maxWidth 420 biar proporsional di HP tablet
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              children: [
                                // ====== TOP ======
                                const SizedBox(height: 8),

                                const SizedBox(height: 8),

                                // Logo lebih proporsional (flexible)
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Column(
                                    children: [
                                      // logo responsif: lebar 24% layar, min 72, max 110
                                      Builder(builder: (context) {
                                        final w = MediaQuery.of(context).size.width;
                                        return Image.asset(
                                          'assets/images/logo2.png',
                                          width: isSmallScreen ? size.width * 0.8 : size.width * 0.7,
                                          height: isSmallScreen ? size.width * 0.8 : size.width * 0.7,
                                        );
                                      }),
                                    ],
                                  ),
                                ),

                                // ====== FORM (center block) ======
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Email',
                                        style: TextStyle(
                                          color: Color.fromARGB(255, 63, 55, 201),
                                          fontFamily: 'Lato',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        decoration: _outlinedDecoration(hint: 'hint@gmail.com').copyWith(
                                          hintStyle: const TextStyle(
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.w700,
                                            color: Color.fromARGB(255, 0,0,0),
                                          ).copyWith(
                                            color: Color.fromARGB(255, 0,0,0).withOpacity(0.3),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      const Text(
                                        'Password',
                                        style: TextStyle(
                                          color: Color.fromARGB(255, 63, 55, 201),
                                          fontFamily: 'Lato',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => login(),
                                        decoration: _outlinedDecoration(
                                          hint: '************',
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Color.fromARGB(255, 0,0,0).withOpacity(0.3),
                                            ),
                                            onPressed: () => setState(
                                                () => _obscurePassword = !_obscurePassword),
                                          ),
                                        ).copyWith(
                                          hintStyle: const TextStyle(
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.w700,
                                            color: Color.fromARGB(255, 0,0,0),
                                          ).copyWith(
                                            color: Color.fromARGB(255, 0,0,0).withOpacity(0.3),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                                        ),
                                      ),

                                      const SizedBox(height: 5,),

                                      // TextButton(
                                      //   style: TextButton.styleFrom(
                                      //     padding: EdgeInsets.zero,
                                      //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      //     minimumSize: Size.zero,
                                      //   ),
                                      //   onPressed: () {},
                                      //   child: const Text(
                                      //     'Lupa password?',
                                      //     style: TextStyle(
                                      //       color: Color.fromRGBO(0,0,0, 0.5),
                                      //       fontSize: 15,
                                      //       fontFamily: 'Lato',
                                      //       fontWeight: FontWeight.w700
                                      //       ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 50),

                                // Tombol
                                SizedBox(
                                  width: double.infinity,
                                  height: isSmallScreen ? 60 : 80,
                                  child: ElevatedButton(
                                    onPressed: login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                      textStyle: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: const Text('Login'),
                                  ),
                                ),

                                // ====== SPACER untuk vertical centering ======
                                const Spacer(),

                                // Footer
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      const Text(
                                        'Belum punya akun? ',
                                        style: TextStyle(
                                        color: Color.fromRGBO(0,0,0, 0.5),
                                        fontSize: 16,
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const RegisterPage(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Buat Akun',
                                          style: TextStyle(
                                          color: Color.fromRGBO(0,0,0, 1),
                                          fontSize: 16,
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer()
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}