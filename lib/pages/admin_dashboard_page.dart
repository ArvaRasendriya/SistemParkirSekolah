import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'satgas_list_page.dart';
import 'admin_sim_page.dart';
import 'login_page.dart';
import 'profile_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardContent(),
    const SatgasListPage(),
    const AdminSimPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      backgroundColor: const Color(0xFF1D1879),
      body: Stack(
        children: [
          Positioned.fill(
              child: _pages[_selectedIndex],
            ),
            if (_selectedIndex == 0)
              Positioned(
                top: 40,
                right: 16,
                child: SafeArea(
                  child: Row(
                    children: [
                      _buildTopIconButton(
                        icon: Icons.person_outline,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfilePage()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildTopIconButton(
                        icon: Icons.logout,
                        onPressed: _logout,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF3F37C9),
              unselectedItemColor: const Color(0xFF9E9E9E),
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined, size: 26),
                  activeIcon: Icon(Icons.dashboard, size: 26),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.security_outlined, size: 26),
                  activeIcon: Icon(Icons.security, size: 26),
                  label: 'Satgas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.credit_card_outlined, size: 26),
                  activeIcon: Icon(Icons.credit_card, size: 26),
                  label: 'SIM',
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isDestructive ? Colors.red.shade200 : Colors.white,
          size: 22,
        ),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  bool _hasError = false;
  String? _errorMessage;

  int simAcc = 0;
  int simPending = 0;
  int akunSatgas = 0;
  int akunAdmin = 0;
  int jumlahParkir = 0;
  List<dynamic> aktivitas = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      loading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        supabase.from('siswa').select('*'),
        supabase.from('pending_siswa').select('*'),
        supabase.from('profiles').select('*').eq('role', 'satgas'),
        supabase.from('profiles').select('*').eq('role', 'admin'),
        supabase.from('siswa').select('nama, status').order('created_at', ascending: false).limit(5),
        supabase.from('parkir').select('siswa_id').eq('tanggal', DateTime.now().toIso8601String().split('T')[0]),
      ]);

      if (!mounted) return;

      setState(() {
        simAcc = (results[0] as List).length;
        simPending = (results[1] as List).length;
        akunSatgas = (results[2] as List).length;
        akunAdmin = (results[3] as List).length;
        aktivitas = results[4] as List;
        jumlahParkir = (results[5] as List).length;
        loading = false;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      
      String errorMsg;
      if (e.toString().contains('connection') ||
          e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMsg = 'Tidak ada koneksi internet';
      } else if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMsg = 'Akses ditolak';
      } else if (e.toString().contains('timeout')) {
        errorMsg = 'Waktu permintaan habis';
      } else {
        errorMsg = 'Gagal memuat statistik dashboard';
      }

      if (!mounted) return;
      setState(() {
        loading = false;
        _hasError = true;
        _errorMessage = errorMsg;
      });
    }
  }

  Widget _buildErrorState() {
    IconData errorIcon;
    String title;
    String subtitle;
    
    if (_errorMessage?.contains('koneksi internet') ?? false) {
      errorIcon = Icons.wifi_off_rounded;
      title = 'Tidak Ada Koneksi';
      subtitle = 'Pastikan Anda terhubung ke internet dan coba lagi.';
    } else if (_errorMessage?.contains('Akses ditolak') ?? false) {
      errorIcon = Icons.lock_outline_rounded;
      title = 'Akses Ditolak';
      subtitle = 'Anda tidak memiliki izin untuk melihat data ini.';
    } else if (_errorMessage?.contains('timeout') ?? false) {
      errorIcon = Icons.access_time_rounded;
      title = 'Waktu Habis';
      subtitle = 'Server membutuhkan waktu terlalu lama. Coba lagi.';
    } else {
      errorIcon = Icons.error_outline_rounded;
      title = 'Terjadi Kesalahan';
      subtitle = 'Gagal memuat statistik dashboard. Silakan coba lagi.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorIcon,
                size: 64,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3F37C9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      );
    }

    if (_hasError) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F37C9), Color(0xFF1D1879)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _buildErrorState(),
        ),
      );
    }

    final total = simAcc + simPending + akunSatgas + akunAdmin;
    double _percent(int value) => total == 0 ? 0 : value / total;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3F37C9), Color(0xFF1D1879)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Selamat',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          'Datang',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 42,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: _bigStatCard(
                        jumlahParkir.toString(),
                        "Sudah Parkir",
                        Icons.check_circle_outline,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _bigStatCard(
                        (simAcc - jumlahParkir).toString(),
                        "Belum Parkir",
                        Icons.pending_outlined,
                        const Color(0xFFFFA726),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Statistik Akun",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _miniProgressCircle(
                            value: _percent(simAcc),
                            label: "SIM",
                            count: simAcc,
                            color: const Color(0xFF2196F3),
                          ),
                          _miniProgressCircle(
                            value: _percent(simPending),
                            label: "Pending",
                            count: simPending,
                            color: const Color(0xFFFFA726),
                          ),
                          _miniProgressCircle(
                            value: _percent(akunSatgas),
                            label: "Satgas",
                            count: akunSatgas,
                            color: const Color(0xFF9C27B0),
                          ),
                          _miniProgressCircle(
                            value: _percent(akunAdmin),
                            label: "Admin",
                            count: akunAdmin,
                            color: const Color(0xFF4CAF50),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Aktivitas Terbaru",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (aktivitas.isEmpty)
                  _emptyActivityCard()
                else
                  ...aktivitas.map((data) => _activityCard(
                        data['nama'] ?? 'Unknown',
                        data['status'] ?? 'Unknown',
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniProgressCircle({
    required double value,
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                backgroundColor: Colors.white.withOpacity(0.2),
                color: color,
              ),
              Center(
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _activityCard(String nama, String status) {
    IconData icon;
    Color iconColor;

    if (status.toLowerCase().contains('approved')) {
      icon = Icons.check_circle;
      iconColor = const Color(0xFF4CAF50);
    } else if (status.toLowerCase().contains('pending')) {
      icon = Icons.schedule;
      iconColor = const Color(0xFFFFA726);
    } else {
      icon = Icons.info;
      iconColor = const Color(0xFF2196F3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyActivityCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              "Belum ada aktivitas",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}