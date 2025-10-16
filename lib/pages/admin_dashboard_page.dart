import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'satgas_list_page.dart';
import 'admin_sim_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
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
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            tooltip: 'Switch to Satgas',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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

  int akunSatgas = 0;
  int akunSiswa = 0;

  bool loading = true;
  ChartType selectedChart = ChartType.pie;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final satgasRes = await supabase.from('profiles').select();
      akunSatgas = satgasRes.length;

      final siswaRes = await supabase.from('siswa').select();
      akunSiswa = siswaRes.length;

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
    final double maxY = (akunSatgas > akunSiswa ? akunSatgas : akunSiswa).toDouble() + 5.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3B0A80),
            Color(0xFF5E17EB),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Welcome to Admin Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              // Tidak bisa dipencet (onTap dihilangkan)
                              StatCard(
                                title: "Akun Satgas",
                                value: "$akunSatgas",
                                change: "+0",
                                icon: Icons.shield,
                                color: Colors.pinkAccent.shade100,
                                onTap: null,
                              ),
                              StatCard(
                                title: "Akun Siswa",
                                value: "$akunSiswa",
                                change: "+0",
                                icon: Icons.school,
                                color: Colors.blueAccent.shade100,
                                onTap: null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Pilih Chart: ",
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(width: 10),
                              DropdownButton<ChartType>(
                                dropdownColor: const Color(0xFF3B0A80),
                                value: selectedChart,
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(
                                    value: ChartType.pie,
                                    child: Text("Pie Chart"),
                                  ),
                                  DropdownMenuItem(
                                    value: ChartType.bar,
                                    child: Text("Bar Chart"),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedChart = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 240,
                            child: selectedChart == ChartType.pie
                                ? PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 40,
                                      sections: [
                                        PieChartSectionData(
                                          value: akunSatgas.toDouble(),
                                          title: 'Satgas\n$akunSatgas',
                                          color: Colors.pinkAccent.shade100,
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        PieChartSectionData(
                                          value: akunSiswa.toDouble(),
                                          title: 'Siswa\n$akunSiswa',
                                          color: Colors.blueAccent.shade100,
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )
                                : BarChart(
                                    BarChartData(
                                      maxY: maxY,
                                      barGroups: [
                                        BarChartGroupData(x: 0, barRods: [
                                          BarChartRodData(
                                              toY: akunSatgas.toDouble(),
                                              color: Colors.pinkAccent.shade100,
                                              width: 18)
                                        ]),
                                        BarChartGroupData(x: 1, barRods: [
                                          BarChartRodData(
                                              toY: akunSiswa.toDouble(),
                                              color: Colors.blueAccent.shade100,
                                              width: 18)
                                        ]),
                                      ],
                                      titlesData: FlTitlesData(
                                        show: true,
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              if (value.toInt() == 0) {
                                                return const Text('Satgas', style: TextStyle(color: Colors.white));
                                              } else {
                                                return const Text('Siswa', style: TextStyle(color: Colors.white));
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      gridData: FlGridData(show: false),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
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
      onTap: onTap, // tetap ada tapi null, jadi tidak bisa dipencet
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.transparent, // hilangkan efek klik
      highlightColor: Colors.transparent,
      child: Card(
        color: const Color(0xFF3B0A80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: color.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.15),
                radius: 26,
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                change,
                style: TextStyle(fontSize: 14, color: change.contains("+") ? Colors.green : Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
