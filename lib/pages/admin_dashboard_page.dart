import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_approval_page.dart';
import 'satgas_list_page.dart';
import 'admin_sim_page.dart';
import 'login_page.dart'; // pastikan ada file login_page.dart
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
      backgroundColor: const Color(0xFF0F2027),
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
            icon: Icon(Icons.credit_card),
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
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
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
            const SizedBox(height: 10),
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
                          // Grid of two cards (kept as before but shrink-wrapped)
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              StatCard(
                                title: "Akun Satgas",
                                value: "$akunSatgas",
                                change: "+0",
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
                                title: "Akun Siswa",
                                value: "$akunSiswa",
                                change: "+0",
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
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Dropdown to choose chart type
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Pilih Chart: ",
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(width: 10),
                              DropdownButton<ChartType>(
                                dropdownColor: Colors.black87,
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

                          // Chart area
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
                                          title: 'Satgas\n${akunSatgas}',
                                          color: Colors.blue,
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        PieChartSectionData(
                                          value: akunSiswa.toDouble(),
                                          title: 'Siswa\n${akunSiswa}',
                                          color: Colors.green,
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
                                          BarChartRodData(toY: akunSatgas.toDouble(), color: Colors.blue, width: 18)
                                        ], showingTooltipIndicators: const [0]),
                                        BarChartGroupData(x: 1, barRods: [
                                          BarChartRodData(toY: akunSiswa.toDouble(), color: Colors.green, width: 18)
                                        ], showingTooltipIndicators: const [0]),
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
                          const SizedBox(height: 30),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: const Color(0xFF1B2A38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 28),
                radius: 24,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 14,
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
