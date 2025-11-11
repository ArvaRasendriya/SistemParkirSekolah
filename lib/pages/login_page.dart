import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:tefa_parkir/pages/register_page.dart';
import 'package:tefa_parkir/pages/profile_page.dart';
import 'package:tefa_parkir/pages/admin_dashboard_page.dart';
import 'dart:async';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
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
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false, IconData? icon, int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: duration),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      debugPrint('🔄 Attempting login for: $email');

      // ✅ Sign in dengan custom auth (tidak pakai Supabase Auth)
      final user = await authService.signInWithEmailPassword(email, password);

      debugPrint('✅ Login successful');
      debugPrint('User role: ${user['role']}');
      debugPrint('User status: ${user['status']}');

      if (!mounted) return;

      // Get role dan status dari result (sudah ada dari AuthService)
      final role = (user['role'] as String?)?.toLowerCase() ?? '';
      final status = (user['status'] as String?)?.toLowerCase() ?? '';

      // Status sudah dicek di AuthService, tapi kita cek lagi untuk safety
      if (status != 'approved') {
        throw Exception('Akun Anda belum disetujui admin');
      }

      // Navigate berdasarkan role
      if (role == 'admin') {
        debugPrint('📍 Navigating to Admin Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else if (role == 'satgas') {
        debugPrint('📍 Navigating to Profile Page');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      } else {
        throw Exception('Role tidak dikenali: $role');
      }

      // Success message
      _showSnackBar(
        'Login berhasil! Selamat datang',
        isError: false,
        icon: Icons.check_circle_outline,
        duration: 2,
      );

    } catch (e) {
      debugPrint('❌ Login error: $e');
      
      if (mounted) {
        String errorMessage = 'Login gagal';
        IconData errorIcon = Icons.error_outline;
        
        final errorStr = e.toString().toLowerCase();

        // Handle specific errors
        if (errorStr.contains('email tidak terdaftar') ||
            errorStr.contains('email atau password salah')) {
          errorMessage = 'Email atau password salah';
          errorIcon = Icons.lock_outline;
        } else if (errorStr.contains('password salah')) {
          errorMessage = 'Password yang Anda masukkan salah';
          errorIcon = Icons.lock_outline;
        } else if (errorStr.contains('belum disetujui') ||
                   errorStr.contains('pending')) {
          errorMessage = 'Akun Anda masih menunggu persetujuan admin';
          errorIcon = Icons.hourglass_empty;
        } else if (errorStr.contains('ditolak') ||
                   errorStr.contains('rejected')) {
          errorMessage = 'Akun Anda ditolak oleh admin. Hubungi admin untuk info lebih lanjut.';
          errorIcon = Icons.block;
        } else if (errorStr.contains('profile tidak ditemukan')) {
          errorMessage = 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
          errorIcon = Icons.person_off_outlined;
        } else if (errorStr.contains('network') || 
                   errorStr.contains('connection')) {
          errorMessage = 'Gagal terhubung ke server. Cek koneksi internet Anda.';
          errorIcon = Icons.wifi_off;
        } else {
          // Generic error - tampilkan pesan asli tapi bersihkan
          errorMessage = e.toString()
              .replaceAll('Exception: ', '')
              .replaceAll('exception: ', '');
        }

        _showSnackBar(errorMessage, isError: true, icon: errorIcon, duration: 4);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: Stack(
            children: [
              LoadingOverlay(
                isLoading: _isLoading,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: size.height - 24),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceL,
                          vertical: AppTheme.spaceM,
                        ),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Column(
                              children: [
                                const Spacer(flex: 1),
                                
                                // Logo
                                Hero(
                                  tag: 'app_logo',
                                  child: Image.asset(
                                    'assets/images/logo2.png',
                                    width: size.width * 0.5,
                                    height: size.width * 0.5,
                                  ),
                                ),
                                
                                const SizedBox(height: AppTheme.spaceXL),
                                
                                // Form
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppTextField(
                                        controller: _emailController,
                                        labelText: 'Email',
                                        hintText: 'hint@gmail.com',
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
                                            color: AppTheme.textSecondary,
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
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: AppTheme.spaceXXL),
                                
                                // Login Button
                                AppButton(
                                  text: 'Login',
                                  onPressed: _isLoading ? null : _login,
                                  isLoading: _isLoading,
                                  height: 56,
                                ),
                                
                                const Spacer(flex: 2),
                                
                                // Register Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Belum punya akun? ',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _isLoading ? null : () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const RegisterPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Buat Akun',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: _isLoading 
                                              ? AppTheme.textSecondary 
                                              : AppTheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}