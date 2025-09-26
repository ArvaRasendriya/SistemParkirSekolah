import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_approval_page.dart';
import 'satgas_list_page.dart';
import 'admin_sim_page.dart';
import 'login_page.dart'; // pastikan ada file login_page.dart

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  // Halaman yang ditampilkan sesuai tab
  final List<Widget> _pages = [
    const DashboardContent(),
    SatgasListPage(),
    const AdminSimPage(), // ⬅️ diganti dari ProfilePage()
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
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
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
            icon: Icon(Icons.list),
            label: "Satgas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card), // ⬅️ tab kanan jadi SIM
            label: "SIM",
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

/// ====== DETAIL PAGES YANG DIPERTAHANKAN ======

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
        future: supabase.from('profiles').select('email'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)),
            );
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Text("Tidak ada data",
                  style: TextStyle(color: Colors.white)),
            );
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              return ListTile(
                title: Text(
                  data[i]['email'],
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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
        future: supabase.from('siswa').select('nama, qr_url'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)),
            );
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Text("Tidak ada data",
                  style: TextStyle(color: Colors.white)),
            );
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              return Card(
                color: const Color(0xFF1B2A38),
                child: ListTile(
                  leading: data[i]['qr_url'] != null &&
                          data[i]['qr_url'].toString().isNotEmpty
                      ? Image.network(data[i]['qr_url'], width: 50)
                      : const Icon(Icons.qr_code, color: Colors.white),
                  title: Text(
                    data[i]['nama'],
                    style: const TextStyle(color: Colors.white),
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

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final supabase = Supabase.instance.client;

  int akunSatgas = 0;
  int akunSiswa = 0;
  int sudahAbsen = 0;
  int belumAbsen = 0;

  int changeAkunSatgas = 0;
  int changeAkunSiswa = 0;
  int changeSudahAbsen = 0;
  int changeBelumAbsen = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final now = DateTime.now().toUtc();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      final todayDate = today.toIso8601String().substring(0, 10); // YYYY-MM-DD
      final yesterdayDate = yesterday.toIso8601String().substring(0, 10);
      final tomorrowDate = tomorrow.toIso8601String().substring(0, 10);
      final todayStart = today.toIso8601String();

      // 1. Ambil jumlah akun satgas
      final satgasRes = await supabase.from('profiles').select().eq('role', 'satgas');
      akunSatgas = satgasRes.length;
      final prevSatgasRes = await supabase.from('profiles').select().eq('role', 'satgas').lt('created_at', todayStart);
      final prevAkunSatgas = prevSatgasRes.length;
      changeAkunSatgas = akunSatgas - prevAkunSatgas;

      // 2. Ambil jumlah akun siswa
      final siswaRes = await supabase.from('siswa').select();
      akunSiswa = siswaRes.length;
      final prevSiswaRes = await supabase.from('siswa').select().lt('created_at', todayStart);
      final prevAkunSiswa = prevSiswaRes.length;
      changeAkunSiswa = akunSiswa - prevAkunSiswa;

      // 3. Ambil jumlah siswa yg sudah absen hari ini (jumlah record di tabel parkir hari ini)
      final parkirTodayRes = await supabase.from('parkir').select().gte('tanggal', todayDate).lt('tanggal', tomorrowDate);
      sudahAbsen = parkirTodayRes.length;

      final parkirYesterdayRes = await supabase.from('parkir').select().gte('tanggal', yesterdayDate).lt('tanggal', todayDate);
      final prevSudahAbsen = parkirYesterdayRes.length;
      changeSudahAbsen = sudahAbsen - prevSudahAbsen;

      // 4. Hitung siswa yg belum absen
      belumAbsen = akunSiswa - sudahAbsen;
      changeBelumAbsen = changeAkunSiswa - changeSudahAbsen;

      setState(() {
        loading = false;
      });
    } catch (e) {
      print("Error load stats: $e");
      setState(() {
        loading = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Container(
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
    child: Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Selamat Datang ke Admin Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // 🔽 Expanded supaya area tengah fleksibel
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Center( // ini yang bikin konten persis di tengah layar
                  child: GridView.count(
                    shrinkWrap: true, // penting biar tidak memenuhi layar
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    padding: const EdgeInsets.all(12),
                    children: [
                      StatCard(
                        title: "Akun Satgas",
                        value: "$akunSatgas",
                        change: changeAkunSatgas >= 0
                            ? "+$changeAkunSatgas"
                            : "$changeAkunSatgas",
                        icon: Icons.shield,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SatgasAccountsPage()),
                          );
                        },
                      ),
                      StatCard(
                        title: "Siswa Terdaftar",
                        value: "$akunSiswa",
                        change: changeAkunSiswa >= 0
                            ? "+$changeAkunSiswa"
                            : "$changeAkunSiswa",
                        icon: Icons.school,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SiswaAccountsPage()),
                          );
                        },
                      ),
                      StatCard(
                        title: "Sudah Absen Hari Ini",
                        value: "$sudahAbsen",
                        change: "",
                        icon: Icons.check_circle,
                        color: Colors.teal,
                      ),
                      StatCard(
                        title: "Belum Absen Hari Ini",
                        value: "$belumAbsen",
                        change: "",
                        icon: Icons.cancel,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
}

}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: const Color(0xFF1B2A38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 24),
                radius: 20,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              if (change.isNotEmpty)
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    color: change.contains("+") ? Colors.green : Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
