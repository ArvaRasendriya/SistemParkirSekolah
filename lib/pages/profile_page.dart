import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'riwayat_page.dart';
import 'qr_scan_page.dart';
import 'daftar_page.dart';

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

  @override
  void initState() {
    super.initState();
    fetchTodayHistory();
    setupRealtimeSubscription();
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    super.dispose();
  }

  void logout() async {
    await authService.signOut();
  }

  Future<void> fetchTodayHistory() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final response = await supabase
          .from('parkir')
          .select('id, waktu, siswa(nama, kelas)')
          .eq('tanggal', today)
          .order('waktu', ascending: false);

      setState(() {
        todayHistory = (response as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint("Error fetching today history: $e");
    }
  }

  void setupRealtimeSubscription() {
    channel = supabase.channel('parkir_changes')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'parkir',
        callback: (payload) {
          fetchTodayHistory();
        },
      )
      ..subscribe();
  }

  Future<void> _refresh() async {
    await fetchTodayHistory();
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
      backgroundColor: Colors.lightBlue[300],
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[300],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text("",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Text(currentEmail.toString()),

              // Kartu profil
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Nama: Aditya Braja Mustika",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            "Kelas: XII RPL 3",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            "Status: Anggota satgas",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Jadwal Piket",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                "Senin 04-08-2025",
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // Riwayat Absensi
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Riwayat Absensi hari ini",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    // Replace dummy list with real history
                    todayHistory.isEmpty
                        ? const Text("Belum ada absensi hari ini",
                            style: TextStyle(color: Colors.white70))
                        : Column(
                            children: todayHistory.map((item) {
                              final siswa = item['siswa'];
                              final nama = siswa['nama'];
                              final waktu = item['waktu']; // "HH:MM:SS"
                              final jam = waktu.toString().substring(0, 5); // HH:MM

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.person,
                                          color: Colors.grey, size: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nama,
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 14),
                                          ),
                                          Text(
                                            jam,
                                            style: const TextStyle(
                                                color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RiwayatPage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QrScanPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DaftarPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'SCAN',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Tambah',
          ),
        ],
      ),
    );
  }
}
