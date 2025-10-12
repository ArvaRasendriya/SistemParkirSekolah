import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:tefa_parkir/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// UI theme constants to match login
const Color _primary = Color(0xFF4F46E5);
const Color _hint = Color(0xFF9EA3AE);
const Color _stroke = Color(0xFFE7E7F0);

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

  late TapGestureRecognizer _loginTapRecognizer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    _loginTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      };
  }

  @override
  void dispose() {
    _controller.dispose();
    _loginTapRecognizer.dispose();
    super.dispose();
  }

  void signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final kelas = _selectedGrade != null &&
            _selectedMajor != null &&
            _selectedClass != null
        ? '$_selectedGrade $_selectedMajor $_selectedClass'
        : '';
    final jurusan = _selectedJurusan ?? '';

    // Validate email format
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format email tidak valid.")),
      );
      return;
    }

    // Validate password length
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password harus setidaknya 6 karakter atau lebih.")),
      );
      return;
    }

    // Validate password match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password tidak cocok")),
      );
      return;
    }

    // Validate full name
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi nama lengkap")),
      );
      return;
    }

    // Validate kelas
    if (kelas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi kelas")),
      );
      return;
    }

    // Validate jurusan
    if (jurusan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi jurusan")),
      );
      return;
    }

    try {
      final response =
          await authservice.signUpWithEmailPassword(email, password);
      final user = response.user;
      if (user != null) {
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
            errorMessage = 'Format email tidak valid.';
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
        color: const Color(0xFF4B4BC9), // Purple background
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 160),
              // Title and subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'Gabung sekarang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: Text(
                  'parkir jadi lebih simpel!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // White rounded container for form
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email
                      const Text(
                        'Email',
                        style: TextStyle(
                          color: Color(0xFF4B4BC9),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomInputField(
                        controller: _emailController,
                        hintText: 'john_doe67@gmail.com',
                        icon: null,
                        obscureText: false,
                        suffixIcon: null,
                        textColor: Colors.black87,
                        hintColor: Colors.black38,
                        fillColor: Colors.white,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      const Text(
                        'Password',
                        style: TextStyle(
                          color: Color(0xFF4B4BC9),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomInputField(
                        controller: _passwordController,
                        hintText: '************',
                        obscureText: _obscurePassword,
                        icon: null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        textColor: Colors.black87,
                        hintColor: Colors.black38,
                        fillColor: Colors.white,
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      const Text(
                        'Konfirmasi Password',
                        style: TextStyle(
                          color: Color(0xFF4B4BC9),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomInputField(
                        controller: _confirmPasswordController,
                        hintText: '************',
                        obscureText: _obscureConfirmPassword,
                        icon: null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        textColor: Colors.black87,
                        hintColor: Colors.black38,
                        fillColor: Colors.white,
                      ),
                      const SizedBox(height: 16),

                      // Nama
                      const Text(
                        'Nama',
                        style: TextStyle(
                          color: Color(0xFF4B4BC9),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomInputField(
                        controller: _fullNameController,
                        hintText: 'John Doe',
                        icon: null,
                        obscureText: false,
                        suffixIcon: null,
                        textColor: Colors.black87,
                        hintColor: Colors.black38,
                        fillColor: Colors.white,
                      ),
                      const SizedBox(height: 16),

                      // Row for Kelas, Jurusan, Rombel labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Kelas',
                            style: TextStyle(
                              color: Color(0xFF4B4BC9),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Jurusan',
                            style: TextStyle(
                              color: Color(0xFF4B4BC9),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Rombel',
                            style: TextStyle(
                              color: Color(0xFF4B4BC9),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Row for dropdowns
                      
                      Row(
                        children: [
                          Expanded(
                          child: buildDropdown(
                            value: _selectedGrade,
                            hint: "X",
                            items: grades,
                            onChanged: (v) => setState(() => _selectedGrade = v),
                            hasIcon: false,
                            textColor: Colors.black87,
                            hintColor: Colors.black54,
                            fillColor: Colors.white,
                            dropdownColor: Colors.white,
                          ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                          child: buildDropdown(
                            value: _selectedMajor,
                            hint: "RPL",
                            items: majors,
                            onChanged: (v) {
                              setState(() {
                                _selectedMajor = v;
                                if (v != null) {
                                  int index = majors.indexOf(v);
                                  if (index != -1) {
                                    _selectedJurusan = jurusans[index];
                                  }
                                } else {
                                  _selectedJurusan = null;
                                }
                              });
                            },
                            hasIcon: false,
                            textColor: Colors.black87,
                            hintColor: Colors.black54,
                            fillColor: Colors.white,
                            dropdownColor: Colors.white,
                          ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                          child: buildDropdown(
                            value: _selectedClass,
                            hint: "3",
                            items: classes,
                            onChanged: (v) => setState(() => _selectedClass = v),
                            hasIcon: false,
                            textColor: Colors.black87,
                            hintColor: Colors.black54,
                            fillColor: Colors.white,
                            dropdownColor: Colors.white,
                          ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      const Spacer(),

                      // Register button
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
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B4BC9),
                            borderRadius: BorderRadius.circular(12),
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
                              'Register',
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

                      // Bottom text
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Sudah punya akun? ',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                recognizer: _loginTapRecognizer,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              )
              ],
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
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: textColor ?? Colors.black),
      cursorColor: textColor ?? Colors.black,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: (textColor ?? Colors.black).withOpacity(0.7)) : null,
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(
          color: _hint,
          fontSize: 14,
          fontFamily: 'Lato',
          fontWeight: FontWeight.w700,
        ).copyWith(color: Colors.black.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white,
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
