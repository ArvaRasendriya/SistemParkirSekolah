import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_approval_page.dart';
import 'satgas_list_page.dart';
import 'admin_sim_page.dart';
import 'login_page.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { pie, bar }

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardContent(),
    const SatgasAccountsPage(),
    const SiswaAccountsPage(),
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
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2A38),
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B2A38),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: "Akun Satgas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "Akun Siswa",
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}

/// DASHBOARD
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final supabase = Supabase.instance.client;
  int sudahParkir = 0;
  int belumParkir = 0;
  int totalSiswa = 0;
  int totalSatgas = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final parkir = await supabase.from('parkir').select();
    final siswa = await supabase.from('siswa').select();
    final satgas =
        await supabase.from('profiles').select().eq('role', 'satgas');

    setState(() {
      sudahParkir = parkir.length;
      totalSiswa = siswa.length;
      totalSatgas = satgas.length;
      belumParkir = totalSiswa - sudahParkir;
      if (belumParkir < 0) belumParkir = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3F37C9), Color(0xFF1D1879)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                const Text(
                  "ADMIN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Selamat datang di admin dashboard",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statusCard(
                      icon: Icons.check_circle,
                      color: Colors.greenAccent,
                      title: "Sudah Parkir",
                      value: sudahParkir.toString(),
                    ),
                    _statusCard(
                      icon: Icons.cancel,
                      color: Colors.redAccent,
                      title: "Belum Parkir",
                      value: belumParkir.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _circleStat("Akun Satgas", "$totalSatgas"),
                    _circleStat("Akun Siswa", "$totalSiswa"),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1FDF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 50),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleStat(String title, String value) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                value: 1,
                color: Colors.white,
                backgroundColor: Colors.white24,
                strokeWidth: 6,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// ====================
/// HALAMAN AKUN SATGAS
/// ====================
class SatgasAccountsPage extends StatelessWidget {
  const SatgasAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Akun Satgas"),
        backgroundColor: const Color(0xFF1B2A38),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: supabase
            .from('profiles')
            .select('full_name, email, role, status')
            .eq('role', 'satgas'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Text(
                "Tidak ada akun Satgas",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              final satgas = data[i];
              return Card(
                color: const Color(0xFF1B2A38),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.security, color: Colors.blueAccent),
                  title: Text(
                    satgas['full_name'] ?? 'Tanpa Nama',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "${satgas['email'] ?? ''}\nStatus: ${satgas['status'] ?? 'pending'}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ====================
/// HALAMAN AKUN SISWA
/// ====================
class SiswaAccountsPage extends StatelessWidget {
  const SiswaAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Akun Siswa"),
        backgroundColor: const Color(0xFF1B2A38),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: supabase.from('siswa').select('nama, kelas, jurusan, qr_url'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Text(
                "Tidak ada akun siswa",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              final siswa = data[i];
              return Card(
                color: const Color(0xFF1B2A38),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: siswa['qr_url'] != null &&
                          siswa['qr_url'].toString().isNotEmpty
                      ? Image.network(siswa['qr_url'], width: 50)
                      : const Icon(Icons.qr_code, color: Colors.white),
                  title: Text(
                    siswa['nama'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "${siswa['kelas']} • ${siswa['jurusan']}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}