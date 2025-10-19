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
      extendBody: false, // 🚫 tidak tembus ke bawah
      backgroundColor: const Color(0xFF1D1879), // warna dasar sama dg gradient
      body: Stack(
        children: [
          Positioned.fill(
            child: _pages[_selectedIndex], // ✅ full screen penuh
          ),
          if (_selectedIndex == 0) // Only show buttons on dashboard tab
            Positioned(
              top: 30,
              right: 20,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                    tooltip: 'Profile',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F8FF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color.fromARGB(254, 49, 54, 56),
          unselectedItemColor: const Color.fromARGB(254, 49, 54, 56),
          selectedLabelStyle: const TextStyle(fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard, size: 28),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list, size: 28),
              label: 'Satgas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card, size: 28),
              label: 'SIM',
            ),
          ],
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
    final simAccRes = await supabase.from('siswa').select('*');
    final simPendingRes = await supabase.from('pending_siswa').select('*');
    final satgasRes = await supabase.from('profiles').select('*').eq('role', 'satgas');
    final adminRes = await supabase.from('profiles').select('*').eq('role', 'admin');

    final aktivitasRes = await supabase
        .from('siswa')
        .select('nama, status')
        .order('created_at', ascending: false)
        .limit(3);

    final jumlahParkirRes = await supabase
        .from('parkir')
        .select('siswa_id')
        .eq('tanggal', DateTime.now().toIso8601String().split('T')[0]);

    if (!mounted) return; // ✅ Tambahkan ini!

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
    if (!mounted) return; // ✅ Pastikan juga di sini
    setState(() {
      loading = false;
    });
  }
}

@override
void dispose() {
  super.dispose();
  // Jika kamu pakai timer atau stream, pastikan cancel di sini:
  // _timer?.cancel();
  // _subscription?.cancel();
}

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 380;

    final total = simAcc + simPending + akunSatgas + akunAdmin;
    double _percent(int value) => total == 0 ? 0 : value / total;

    return Container(
      width: double.infinity,
      height: double.infinity, // ✅ isi penuh layar
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3F37C9), Color(0xFF1D1879)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const[
                      Text(
                        'Selamat',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0
                        ),
                      ),
                      Text(
                        'datang',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0
                        ),
                      ),
                    ],
                  ),

                  Text(
                    'ADMIN',
                      style: TextStyle(
                      fontSize: isSmall ? 36 : 48,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w700,
                )
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _bigStatCard(
                        jumlahParkir.toString(), "Jumlah yg sudah parkir"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _bigStatCard(
                        jumlahBlmP.toString(), "Jumlah yg belum parkir"),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _miniProgressCircle(
                      value: _percent(simAcc), label: "SIM Acc ($simAcc)"),
                  _miniProgressCircle(
                      value: _percent(simPending),
                      label: "SIM Pending ($simPending)"),
                  _miniProgressCircle(
                      value: _percent(akunSatgas),
                      label: "Satgas ($akunSatgas)"),
                  _miniProgressCircle(
                      value: _percent(akunAdmin), label: "Admin ($akunAdmin)"),
                ],
              ),
              const SizedBox(height: 28),

              const Text(
                "Aktivitas Terbaru",
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
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
            ],
          ),
        ),
      ),
    );
  }

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
          Text(value,
              style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

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
                      fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  static Widget _activityCard(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF4B19B5),
        borderRadius: BorderRadius.circular(14),
      ),
      child:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}
