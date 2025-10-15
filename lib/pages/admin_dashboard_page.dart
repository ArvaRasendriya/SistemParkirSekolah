import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'satgas_list_page.dart';
import 'admin_sim_page.dart';
import 'login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardContent(),
    SatgasListPage(),
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
      backgroundColor: const Color(0xFF2A0A5E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B0A80),
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF3B0A80),
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
            icon: Icon(Icons.credit_card),
            label: "SIM",
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amberAccent,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
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

  int simAcc = 0;
  int simPending = 0;
  int akunSatgas = 0;
  int akunAdmin = 0;
  int jumlahParkir = 0;
  int jumlahBlmP = 0;
  List<dynamic> aktivitas = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

 Future<void> _loadStats() async {
  try {
    // ✅ 1. Jumlah data dari tabel siswa
    final simAccRes = await supabase.from('siswa').select('*');

    // ✅ 2. Jumlah data dari tabel pending_siswa
    final simPendingRes = await supabase.from('pending_siswa').select('*');

    // ✅ 3. Jumlah akun satgas dari tabel profiles
    final satgasRes = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'satgas');

    // ✅ 4. Jumlah akun admin dari tabel profiles
    final adminRes = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'admin');

    // ✅ Aktivitas diambil dari siswa (opsional, tetap sama)
    final aktivitasRes = await supabase
        .from('siswa')
        .select('nama, status')
        .order('created_at', ascending: false)
        .limit(3);

    // ✅ 5. Jumlah siswa yang parkir hari ini
    final jumlahParkirRes = await supabase
        .from('parkir')
        .select('siswa_id')
        .eq('tanggal', DateTime.now().toIso8601String().split('T')[0]); // Mengambil parkir hari ini

    // ✅ 6. Jumlah siswa yang belum parkir hari ini
    final jumlahBlmP = simAccRes.length - (jumlahParkirRes as List).length;

    setState(() {
      simAcc = (simAccRes as List).length;
      simPending = (simPendingRes as List).length;
      akunSatgas = (satgasRes as List).length;
      akunAdmin = (adminRes as List).length;
      aktivitas = aktivitasRes as List;
      jumlahParkir = (jumlahParkirRes as List).length;
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
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final total = simAcc + simPending + akunSatgas + akunAdmin;
    double _percent(int value) => total == 0 ? 0 : value / total;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3F37C9),
            Color(0xFF1D1879),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ADMIN DASBOARD",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                "ADMIN",
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Selamat datang di admin dasboard",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // === Dua Card Besar ===
              Row(
                children: [
                  Expanded(
                    child: _bigStatCard(jumlahParkir.toString(), "Jumlah yg sudah parkir"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _bigStatCard(jumlahBlmP.toString(), "Jumlah yg belum parkir"),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // === Empat Circle Progress Mini ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _miniProgressCircle(
                    value: _percent(simAcc),
                    label: "SIM Acc ($simAcc)",
                  ),
                  _miniProgressCircle(
                    value: _percent(simPending),
                    label: "SIM Pending ($simPending)",
                  ),
                  _miniProgressCircle(
                    value: _percent(akunSatgas),
                    label: "Satgas ($akunSatgas)",
                  ),
                  _miniProgressCircle(
                    value: _percent(akunAdmin),
                    label: "Admin ($akunAdmin)",
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // === Aktivitas Terbaru ===
              const Text(
                "Aktivitas Terbaru",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Column(
                children: aktivitas.isNotEmpty
                    ? aktivitas
                        .map((data) => _activityCard(
                            'Siswa "${data['nama']}" → ${data['status']}'))
                        .toList()
                    : [
                        _activityCard("Belum ada aktivitas terbaru"),
                      ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Card besar jumlah parkir
  static Widget _bigStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B0A70),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 48,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Circle progress kecil
  static Widget _miniProgressCircle({
    required double value,
    required String label,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: Colors.white12,
                color: Colors.white,
              ),
              Center(
                child: Text(
                  "${(value * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // Card aktivitas
  static Widget _activityCard(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF4B19B5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}