import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'riwayat_page.dart';
import 'package:google_fonts/google_fonts.dart';
import './Qr/qr_scan_page.dart';
import 'daftar_page.dart';
import 'admin_dashboard_page.dart';
import 'login_page.dart';
import 'daftar_page_guru.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> todayHistory = [];
  RealtimeChannel? channel;
  Map<String, dynamic>? profileData;
  bool isUpdating = false;
  
  // Connectivity
  bool _isOffline = false;
  bool _showBanner = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    fetchTodayHistory();
    setupRealtimeSubscription();
    _loadProfile();
    _initConnectivity();
    _setupConnectivityListener();
  }

  // ✅ Cek login status dulu
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await authService.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final isOffline = results.every((r) => r == ConnectivityResult.none);
      setState(() {
        _isOffline = isOffline;
        _showBanner = false;
      });
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }
  
  void _showTambahPilihan() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1879),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Text(
              "Tambah Data",
              style: TextStyle(
                color: Color(0xFFF8F8FF),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 👉 Daftar Siswa
            _buildTambahItem(
              icon: Icons.school,
              title: "Daftar Siswa",
              subtitle: "Tambah data siswa baru",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DaftarPage()),
                );
              },
            ),

            const SizedBox(height: 12),

            // 👉 Daftar Guru
            _buildTambahItem(
              icon: Icons.person,
              title: "Daftar Guru",
              subtitle: "Tambah data guru baru",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DaftarPageGuru()),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isOfflineNow = results.every((result) => result == ConnectivityResult.none);

    if (isOfflineNow != _isOffline) {
      setState(() {
        _isOffline = isOfflineNow;
        _showBanner = false;
      });

      if (!isOfflineNow) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_isOffline) {
            setState(() => _showBanner = false);
          }
        });
      }
    }
  }

  // ✅ Load profile menggunakan custom auth
  Future<void> _loadProfile() async {
    try {
      debugPrint('🔄 Loading profile...');
      
      // Get profile dari AuthService (menggunakan session lokal)
      final profile = await authService.getUserProfile();
      
      if (profile == null) {
        debugPrint('❌ Profile not found, redirecting to login...');
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
        return;
      }

      debugPrint('✅ Profile loaded: ${profile['email']}');
      
      if (mounted) {
        setState(() {
          profileData = profile;
        });
      }
    } catch (e) {
      debugPrint("❌ Gagal memuat profil: $e");
      
      // Jika error karena tidak login, redirect ke login
      if (e.toString().contains('not found') || 
          e.toString().contains('unauthorized')) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // ✅ Logout menggunakan custom auth
  void logout() async {
    try {
      debugPrint('🔄 Logging out...');
      await authService.signOut();
      debugPrint('✅ Logged out successfully');

      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    }
  }

  Future<void> fetchTodayHistory() async {
    try {
      if (mounted) setState(() => isUpdating = true);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final response = await supabase
          .from('parkir')
          .select('id, created_at, siswa(nama, kelas)')
          .eq('tanggal', today)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          todayHistory = (response as List).cast<Map<String, dynamic>>();
          isUpdating = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching today history: $e");
      if (mounted) setState(() => isUpdating = false);
    }
  }

  void setupRealtimeSubscription() {
    channel = supabase.channel('public:parkir')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'parkir',
        callback: (payload) async {
          await fetchTodayHistory();
        },
      )
      ..subscribe();
  }

  Future<void> _refresh() async {
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Tidak dapat refresh. Anda sedang offline')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Future.wait([
      _loadProfile(),
      fetchTodayHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3F37C9), Color(0xFF1D1879)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: const Color(0xFFF8F8FF),
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              color: Color(0xFFF8F8FF),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              // ✅ Admin button dengan FutureBuilder
                              FutureBuilder<String?>(
                                future: authService.getUserRole(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data == 'admin') {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F8FF).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => const AdminDashboardPage()),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.admin_panel_settings,
                                          color: Color(0xFFF8F8FF),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F8FF).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: logout,
                                  icon: const Icon(Icons.logout, color: Color(0xFFF8F8FF)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Profile Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFF8F8FF).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: profileData == null
                          ? const Center(
                              child: CircularProgressIndicator(color: Color(0xFFF8F8FF)),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name and Role
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profileData!['full_name'] ?? '-',
                                            style: const TextStyle(
                                              fontFamily: 'Montserrat',
                                              color: Color(0xFFF8F8FF),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          // ✅ Role badge dari profileData langsung
                                          Builder(
                                            builder: (context) {
                                              final role = profileData!['role'] as String?;
                                              String roleText = "Anggota Satgas";
                                              Color roleColor = const Color(0xFF60A5FA);
                                              IconData roleIcon = Icons.shield;
                                              
                                              if (role == 'admin') {
                                                roleText = "Admin";
                                                roleColor = const Color(0xFFFBBF24);
                                                roleIcon = Icons.admin_panel_settings;
                                              } else if (role == 'satgas') {
                                                roleText = "Anggota Satgas";
                                                roleColor = const Color(0xFF60A5FA);
                                                roleIcon = Icons.shield;
                                              }
                                              
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: roleColor.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: roleColor.withOpacity(0.5),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(roleIcon, size: 16, color: roleColor),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      roleText,
                                                      style: GoogleFonts.lato(
                                                        color: roleColor,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                Divider(color: const Color(0xFFF8F8FF).withOpacity(0.2)),
                                const SizedBox(height: 16),

                                // Info Grid
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.school,
                                        label: 'Kelas',
                                        value: profileData!['kelas'] ?? '-',
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // ✅ Status dari profileData langsung
                                Builder(
                                  builder: (context) {
                                    final status = profileData!['status'] as String?;
                                    String statusText = "Unknown";
                                    Color statusColor = const Color(0xFFF8F8FF);
                                    IconData statusIcon = Icons.help_outline;
                                    
                                    if (status == 'approved') {
                                      statusText = "Approved";
                                      statusColor = const Color(0xFF34D399);
                                      statusIcon = Icons.check_circle;
                                    } else if (status == 'pending') {
                                      statusText = "Pending";
                                      statusColor = const Color(0xFFFBBF24);
                                      statusIcon = Icons.pending;
                                    } else if (status == 'rejected') {
                                      statusText = "Rejected";
                                      statusColor = const Color(0xFFEF4444);
                                      statusIcon = Icons.cancel;
                                    }
                                    
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(statusIcon, color: statusColor, size: 20),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Status Akun: ',
                                            style: GoogleFonts.lato(
                                              color: const Color(0xFFF8F8FF).withOpacity(0.8),
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            statusText,
                                            style: GoogleFonts.lato(
                                              color: statusColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                    ),

                    // Absensi Hari Ini
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8FF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFF8F8FF).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F8FF).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.history,
                                    color: Color(0xFFF8F8FF),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Riwayat Absensi Hari Ini",
                                  style: TextStyle(
                                    color: Color(0xFFF8F8FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                if (isUpdating)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFF8F8FF),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F8FF).withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${todayHistory.length}',
                                      style: const TextStyle(
                                        color: Color(0xFFF8F8FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: todayHistory.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.inbox,
                                            size: 48,
                                            color: const Color(0xFFF8F8FF).withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            "Belum ada absensi hari ini",
                                            style: TextStyle(
                                              color: const Color(0xFFF8F8FF).withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: todayHistory.length,
                                      itemBuilder: (context, index) {
                                        final item = todayHistory[index];
                                        final siswa = item['siswa'];
                                        final nama = siswa['nama'];
                                        final kelas = siswa['kelas'];
                                        final createdAtStr = item['created_at'];
                                        final jam = createdAtStr != null
                                            ? (() {
                                                final createdAt =
                                                    DateTime.parse(createdAtStr);
                                                return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
                                              })()
                                            : '--:--';

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F8FF).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: const Color(0xFFF8F8FF).withOpacity(0.15),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8F8FF).withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.person,
                                                  color: Color(0xFFF8F8FF),
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      nama,
                                                      style: const TextStyle(
                                                        color: Color(0xFFF8F8FF),
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      kelas,
                                                      style: TextStyle(
                                                        color: const Color(0xFFF8F8FF)
                                                            .withOpacity(0.7),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8F8FF).withOpacity(0.25),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  jam,
                                                  style: const TextStyle(
                                                    color: Color(0xFFF8F8FF),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Connectivity Banner
          if (_showBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isOffline ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        Icon(
                          _isOffline ? Icons.wifi_off : Icons.wifi,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isOffline ? 'Anda sedang offline' : 'Anda online',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!_isOffline)
                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // Bottom nav dengan 3 tombol
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF3F37C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3F37C9).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Tombol Riwayat
                _buildNavButton(
                  icon: Icons.history_rounded,
                  label: 'Riwayat',
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RiwayatPage()),
                    );
                  },
                ),
                
                // Tombol QR (Tengah)
                _buildQRButton(),
                
                // Tombol Tambah
                _buildNavButton(
                  icon: Icons.person_add_rounded,
                  label: 'Tambah',
                  isActive: false,
                  onTap: _showTambahPilihan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isActive 
                ? const Color(0xFFF8F8FF).withOpacity(0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: const Color(0xFFF8F8FF),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFFF8F8FF),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTambahItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FF).withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF8F8FF).withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FF).withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFF8F8FF)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF8F8FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: const Color(0xFFF8F8FF).withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFFF8F8FF),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildQRButton() {
    return GestureDetector(
      onTap: () {
        if (_isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Tidak dapat scan QR. Anda sedang offline')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrScanPage()),
        );
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFF8F8FF), Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF8F8FF).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Color(0xFF3F37C9),
          size: 36,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFFF8F8FF).withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFFF8F8FF).withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.lato(
              color: const Color(0xFFF8F8FF),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}