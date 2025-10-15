import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final authservice = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();

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
    'Teknik Otomasi Industri',
    'Teknik Audio Video',
    'Teknik Komputer Jaringan'
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final kelas = _selectedGrade != null &&
            _selectedMajor != null &&
            _selectedClass != null
        ? '$_selectedGrade $_selectedMajor $_selectedClass'
        : '';
    final jurusan = _selectedJurusan ?? '';

    if (kelas.isEmpty) {
      _showSnackBar('Harap pilih kelas lengkap', isError: true);
      return;
    }

    if (jurusan.isEmpty) {
      _showSnackBar('Harap pilih jurusan', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await authservice.signUpWithEmailPassword(email, password);
      final user = response.user;
      
      if (user != null) {
        await authservice.createProfile(
          user.id,
          email,
          full_name: fullName,
          kelas: kelas,
          jurusan: jurusan,
        );
      }

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success),
                const SizedBox(width: AppTheme.spaceS),
                Text('Sukses', style: AppTheme.h3),
              ],
            ),
            content: Text(
              'Registrasi berhasil! Silakan cek email untuk verifikasi.',
              style: AppTheme.bodyMedium,
            ),
            actions: [
              AppButton(
                text: 'OK',
                onPressed: () => Navigator.of(context).pop(),
                height: 44,
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
        String errorMessage = 'Terjadi kesalahan';
        if (e is AuthException) {
          errorMessage = e.message;
          if (errorMessage.contains('already registered')) {
            errorMessage = 'Email sudah terdaftar';
          } else if (errorMessage.contains('Invalid email')) {
            errorMessage = 'Format email tidak valid';
          }
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gabung sekarang',
                          style: AppTheme.h1.copyWith(
                            color: AppTheme.textOnPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceS),
                        Text(
                          'Parkir jadi lebih simpel!',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.textOnPrimary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppTheme.radiusXXL),
                          topRight: Radius.circular(AppTheme.radiusXXL),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spaceL),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: AppTheme.spaceM),

                                  // Email
                                  AppTextField(
                                    controller: _emailController,
                                    labelText: 'Email',
                                    hintText: 'john_doe67@gmail.com',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Email wajib diisi';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Format email tidak valid';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: AppTheme.spaceL),

                                  // Password
                                  AppTextField(
                                    controller: _passwordController,
                                    labelText: 'Password',
                                    hintText: '••••••••••••',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password wajib diisi';
                                      }
                                      if (value.length < 6) {
                                        return 'Password minimal 6 karakter';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: AppTheme.spaceL),

                                  // Confirm Password
                                  AppTextField(
                                    controller: _confirmPasswordController,
                                    labelText: 'Konfirmasi Password',
                                    hintText: '••••••••••••',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscureConfirmPassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value != _passwordController.text) {
                                        return 'Password tidak cocok';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: AppTheme.spaceL),

                                  // Full Name
                                  AppTextField(
                                    controller: _fullNameController,
                                    labelText: 'Nama Lengkap',
                                    hintText: 'John Doe',
                                    prefixIcon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nama wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: AppTheme.spaceL),

                                  // Kelas Section
                                  Text(
                                    'Kelas',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceS),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDropdown(
                                          value: _selectedGrade,
                                          hint: 'X',
                                          items: grades,
                                          onChanged: (v) => setState(() => _selectedGrade = v),
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spaceM),
                                      Expanded(
                                        child: _buildDropdown(
                                          value: _selectedMajor,
                                          hint: 'RPL',
                                          items: majors,
                                          onChanged: (v) {
                                            setState(() {
                                              _selectedMajor = v;
                                              if (v != null) {
                                                int index = majors.indexOf(v);
                                                _selectedJurusan = jurusans[index];
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spaceM),
                                      Expanded(
                                        child: _buildDropdown(
                                          value: _selectedClass,
                                          hint: '1',
                                          items: classes,
                                          onChanged: (v) => setState(() => _selectedClass = v),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: AppTheme.spaceXL),

                                  // Register Button
                                  AppButton(
                                    text: 'Register',
                                    onPressed: _signUp,
                                    isLoading: _isLoading,
                                    height: 56,
                                  ),

                                  const SizedBox(height: AppTheme.spaceL),

                                  // Login Link
                                  Center(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Sudah punya akun? ',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Login',
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const LoginPage(),
                                                  ),
                                                );
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: AppTheme.spaceL),
                                ],
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      hint: Text(hint, style: AppTheme.bodyMedium),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceM,
          vertical: AppTheme.spaceM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: Color(0xFFE7E7F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: Color(0xFFE7E7F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: AppTheme.bodyMedium),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}