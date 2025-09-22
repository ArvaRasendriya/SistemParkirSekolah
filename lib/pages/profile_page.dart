import 'dart:async'; // ⬅️ penting untuk Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'riwayat_page.dart';
import 'qr_scan_page.dart';
import 'daftar_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? profileData;
  List<Map<String, dynamic>> todayHistory = [];
  RealtimeChannel? channel;

  late Timer timer;
  String currentTime = DateFormat.Hms().format(DateTime.now()); // hh:mm:ss

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchTodayHistory();
    setupRealtimeSubscription();

    // Timer untuk update jam realtime tiap detik
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        currentTime = DateFormat.Hms().format(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    timer.cancel();
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

  Future<void> fetchProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('profiles')
          .select('full_name, kelas, status, jadwal_piket, jurusan')
          .eq('id', user.id)
          .single();

      setState(() {
        profileData = response;
      });
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> fetchTodayHistory() async {
    try {
      final today = DateTime.now();
      final startOfDay =
          DateTime(today.year, today.month, today.day).toIso8601String();

      final response = await supabase
          .from('parkir')
          .select('id, created_at, siswa(nama, kelas)')
          .gte('created_at', startOfDay)
          .order('created_at', ascending: false);

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
        callback: (payload) => fetchTodayHistory(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'parkir',
        callback: (payload) => fetchTodayHistory(),
      )
      ..subscribe();
  }

  String formatWaktu(dynamic waktu) {
    try {
      final parsed = DateTime.parse(waktu.toString()).toLocal();
      return DateFormat.Hm().format(parsed); // contoh: 14:32
    } catch (_) {
      return waktu.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
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
          child: RefreshIndicator(
            onRefresh: () async {
              await fetchProfile();
              await fetchTodayHistory();
            },
            child: CustomScrollView(
              slivers: [
                // HEADER
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  pinned: false,
                  automaticallyImplyLeading: false,
                  title: Column(
                    children: [
                      const Text(
                        "Profil",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        currentTime,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      )
                    ],
                  ),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    // 🔄 Tombol reload manual
                    IconButton(
                      onPressed: () async {
                        await fetchProfile();
                        await fetchTodayHistory();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                    )
                  ],
                ),

                // KARTU PROFIL
                SliverToBoxAdapter(
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child:
                              Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: profileData == null
                              ? const Text(
                                  "Loading...",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profileData!['full_name'],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${profileData!['kelas']} | ${profileData!['status']}",
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Jadwal Piket",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12),
                                        ),
                                        Text(
                                          "${profileData!['jadwal_piket'] ?? '-'}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                        )
                      ],
                    ),
                  ),
                ),

                // RIWAYAT ABSENSI
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Riwayat Absensi Hari Ini",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        todayHistory.isEmpty
                            ? const Text("Belum ada absensi hari ini",
                                style: TextStyle(color: Colors.white70))
                            : Column(
                                children: todayHistory.map((item) {
                                  final siswa = item['siswa'];
                                  final nama = siswa['nama'];
                                  final createdAt = item['created_at'];
                                  final jam = formatWaktu(createdAt);

                                  return Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
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
                                          child: Text(
                                            nama,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14),
                                          ),
                                        ),
                                        Text(
                                          jam,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),

                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),

        // Bottom Navigation
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF203A43),
            selectedItemColor: Colors.tealAccent,
            unselectedItemColor: Colors.grey[400],
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
