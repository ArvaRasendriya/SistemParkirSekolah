import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
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
  final supabase = Supabase.instance.client;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();

  String? _selectedGrade;
  String? _selectedMajor;
  String? _selectedClass;
  String? _selectedJurusan;

  static const List<String> grades = ['X', 'XI', 'XII'];
  static const List<String> majors = ['RPL', 'DKV', 'TOI', 'TAV', 'TKJ', 'TITL'];
  static const List<String> classes = ['1', '2', '3', '4', '5', '6'];
  static const List<String> jurusans = [
    'Rekayasa Perangkat Lunak',
    'Desain Komunikasi Visual',
    'Teknik Otomasi Industri',
    'Teknik Audio Video',
    'Teknik Komputer Jaringan',
    'Teknik Instalasi Tenaga Listrik'
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Email validation states
  bool _isCheckingEmail = false;
  bool? _isEmailAvailable;
  String? _emailErrorMessage;
  Timer? _debounceTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _emailController.addListener(_onEmailChanged);
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
    _debounceTimer?.cancel();
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _debounceTimer?.cancel();

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _isCheckingEmail = false;
        _isEmailAvailable = null;
        _emailErrorMessage = null;
      });
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      setState(() {
        _isCheckingEmail = false;
        _isEmailAvailable = false;
        _emailErrorMessage = "Format email tidak valid";
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _isEmailAvailable = null;
      _emailErrorMessage = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _checkEmailAvailability(_emailController.text.trim());
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _checkEmailAvailability(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      // ✅ Hanya cek di tabel profiles (karena tidak pakai auth.users lagi)
      final profileResponse = await supabase
          .from('profiles')
          .select('email')
          .eq('email', normalizedEmail)
          .maybeSingle();

      if (mounted) {
        if (profileResponse != null) {
          setState(() {
            _isCheckingEmail = false;
            _isEmailAvailable = false;
            _emailErrorMessage = "Email sudah terdaftar";
          });
        } else {
          setState(() {
            _isCheckingEmail = false;
            _isEmailAvailable = true;
            _emailErrorMessage = null;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error checking email: $e");
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _isEmailAvailable = null;
          _emailErrorMessage = "Gagal memeriksa email";
        });
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate email availability
    if (_isEmailAvailable != true) {
      _showSnackBar(_emailErrorMessage ?? 'Email tidak tersedia', isError: true);
      return;
    }

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
      // ✅ Sign up dengan custom auth (tidak pakai Supabase Auth)
      debugPrint('🔄 Starting sign up...');
      
      final result = await authservice.signUpWithEmailPassword(
        email,
        password,
        fullName: fullName,
        kelas: kelas,
        jurusan: jurusan,
      );

      debugPrint('✅ Sign up successful: ${result['email']}');

      if (mounted) {
        // Tampilkan dialog sukses
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 28),
                const SizedBox(width: AppTheme.spaceS),
                Expanded(
                  child: Text('Pendaftaran Berhasil', style: AppTheme.h3),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akun Anda berhasil didaftarkan!',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: AppTheme.warning,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spaceS),
                      Expanded(
                        child: Text(
                          'Akun Anda sedang menunggu persetujuan admin.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                Text(
                  'Anda akan dapat login setelah admin menyetujui akun Anda.',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              AppButton(
                text: 'Mengerti',
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                height: 44,
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan saat mendaftar';
        
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('email sudah terdaftar') || 
            errorStr.contains('duplicate') ||
            errorStr.contains('already')) {
          errorMessage = 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
        } else if (errorStr.contains('invalid email')) {
          errorMessage = 'Format email tidak valid';
        } else if (errorStr.contains('password')) {
          errorMessage = 'Password terlalu lemah. Minimal 6 karakter.';
        } else if (errorStr.contains('network') || errorStr.contains('connection')) {
          errorMessage = 'Gagal terhubung ke server. Cek koneksi internet Anda.';
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
        duration: const Duration(seconds: 4),
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

                                  // Email with validation
                                  _buildEmailField(),

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

                                  const SizedBox(height: AppTheme.spaceL),
                                  Text(
                                    'Jurusan',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceS),
                                  _buildDropdown(
                                    value: _selectedJurusan,
                                    hint: 'Pilih Jurusan',
                                    items: jurusans,
                                    onChanged: (v) => setState(() => _selectedJurusan = v),
                                  ),

                                  const SizedBox(height: AppTheme.spaceXL),

                                  // Register Button
                                  AppButton(
                                    text: 'Daftar',
                                    onPressed: (_isEmailAvailable != true || _isLoading) 
                                        ? null 
                                        : _signUp,
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
                                                if (!_isLoading) {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => const LoginPage(),
                                                    ),
                                                  );
                                                }
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

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'john_doe67@gmail.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          suffixIcon: _isCheckingEmail
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              : _isEmailAvailable != null
                  ? Icon(
                      _isEmailAvailable! 
                          ? Icons.check_circle 
                          : Icons.cancel,
                      color: _isEmailAvailable! 
                          ? AppTheme.success
                          : AppTheme.error,
                      size: 24,
                    )
                  : null,
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
        if (_emailErrorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _emailErrorMessage!,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ] else if (_isEmailAvailable == true) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: AppTheme.success,
              ),
              const SizedBox(width: 6),
              Text(
                "Email tersedia",
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
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