import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'riwayat_page.dart';
import 'qr_scan_page.dart';
import 'daftar_page.dart';
import 'admin_dashboard_page.dart';
import 'login_page.dart'; // pastikan ada file login_page.dart
import 'edit_profile_page.dart';

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

  @override
  void initState() {
    super.initState();
    fetchTodayHistory();
    setupRealtimeSubscription();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          profileData = data;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat profil: $e");
    }
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    super.dispose();
  }

  void logout() async {
    await authService.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
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
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FutureBuilder<String?>(
                        future: authService.getUserRole(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data == 'admin') {
                            return IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
                                );
                              },
                              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                              tooltip: 'Admin Dashboard',
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      IconButton(
                        onPressed: logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Card Profile
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 40, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: profileData == null
                                ? const Text("Memuat...",
                                    style: TextStyle(color: Colors.white))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profileData!['full_name'] ?? '-',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        profileData!['kelas'] ?? '-',
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      FutureBuilder<String?>(
                                        future: authService.getUserRole(),
                                        builder: (context, snapshot) {
                                          String roleText = "Anggota Satgas";
                                          if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData && snapshot.data != null) {
                                              final role = snapshot.data!;
                                              if (role == 'admin') {
                                                roleText = "Admin";
                                              } else if (role == 'satgas') {
                                                roleText = "Anggota Satgas";
                                              } else {
                                                roleText = role;
                                              }
                                            } else {
                                              roleText = "Unknown";
                                            }
                                          }
                                          return Text(roleText,
                                              style: const TextStyle(
                                                  color: Colors.white70, fontSize: 13));
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Jadwal Piket",
                                              style: TextStyle(
                                                  color: Colors.white54, fontSize: 12)),
                                          Text(
                                            profileData!['jadwal_piket'] ?? '-',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<String?>(
                                        future: authService.getUserStatus(),
                                        builder: (context, snapshot) {
                                          String statusText = "";
                                          Color statusColor = Colors.white;
                                          if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData && snapshot.data != null) {
                                              final status = snapshot.data!;
                                              if (status == 'approved') {
                                                statusText = "Account: Approved";
                                                statusColor = Colors.green;
                                              } else if (status == 'pending') {
                                                statusText = "Account: Pending Approval";
                                                statusColor = Colors.orange;
                                              } else if (status == 'rejected') {
                                                statusText = "Account: Rejected";
                                                statusColor = Colors.red;
                                              }
                                            }
                                          }
                                          return Text(
                                            statusText,
                                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                          )
                        ],
                      ),

                      // Tombol Edit
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const EditProfilePage()),
                            ).then((_) {
                              _loadProfile(); // ⬅️ refresh profil setelah edit
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Riwayat Absensi
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Riwayat Absensi Hari Ini",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 12),

                        todayHistory.isEmpty
                            ? const Text("Belum ada absensi hari ini",
                                style: TextStyle(color: Colors.white60))
                            : Expanded(
                                child: ListView.builder(
                                  itemCount: todayHistory.length,
                                  itemBuilder: (context, index) {
                                    final item = todayHistory[index];
                                    final siswa = item['siswa'];
                                    final nama = siswa['nama'];
                                    final waktu = item['waktu'];
                                    final jam = waktu.toString().substring(0, 5);

                                    return Container(
                                      margin:
                                          const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 18,
                                            backgroundColor: Colors.white,
                                            child: Icon(Icons.person,
                                                color: Colors.grey, size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(nama,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500)),
                                                Text(jam,
                                                    style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          )
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

      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.tealAccent,
            unselectedItemColor: Colors.grey[500],
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
        ),
      ),
    );
  }
}