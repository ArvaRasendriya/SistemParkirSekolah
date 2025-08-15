import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'riwayat_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();

  void logout() async {
    await authService.signOut();
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
        title: const Text(
          "",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          )
        ],
      ),
      body: Column(
        children: [
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
                    children: [
                      const Text(
                        "Nama: Aditya Braja Mustika",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Text(
                        "Kelas: XII RPL 3",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Text(
                        "Status: Anggota satgas",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "Jadwal Piket",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            "Senin 04-08-2025",
                            style:
                                TextStyle(color: Colors.white, fontSize: 12),
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
                Column(
                  children: List.generate(5, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person,
                                color: Colors.grey, size: 20),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Ardika Muhammad Lazuardi",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                                Text(
                                  "10 November, 06:25",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation
bottomNavigationBar: BottomNavigationBar(
  backgroundColor: Colors.white,
  selectedItemColor: Colors.blue[900],
  unselectedItemColor: Colors.grey,
  currentIndex: 0, // posisi default
  onTap: (index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RiwayatPage()),
      );
    }
    // index 1 = SCAN, index 2 = Tambah (belum diatur)
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
