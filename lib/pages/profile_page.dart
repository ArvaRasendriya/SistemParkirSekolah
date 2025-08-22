// import 'package:flutter/material.dart';
// import 'package:tefa_parkir/auth/auth_service.dart';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {

//   final authService = AuthService();
//   void logout() async{
//     await authService.signOut();
//   }

//   @override
//   Widget build(BuildContext context) {

//     final currentEmail = authService.getCurrentUserEmail();

//     return Scaffold(
//       appBar: AppBar(
//         actions: [
//           IconButton(
//             onPressed: logout, 
//             icon: Icon(Icons.logout),
//           )
//         ],
//       ),

//       body: Center(child: Text(currentEmail.toString()),),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'riwayat_page.dart';
import 'profile_edit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authservice = AuthService();
  final supabase = Supabase.instance.client;

  String? fullName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        fullName = response?['full_name'] ?? "No name set";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        fullName = "Error loading name";
        _isLoading = false;
      });
    }
  }

  void logout() async {
    await authservice.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Column(
          children: [
            // Card Profile (klik untuk ke ProfileEdit)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompleteProfilePage(),
                    ),
                  ).then((_) {
                    // refresh after coming back from edit page
                    _loadProfile();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.black12,
                        child: Icon(Icons.person, size: 32),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: AutoSizeText(
                          "Selamat berjaga, $fullName!",
                          style: GoogleFonts.poppins(
                            color: Color(0xFF121212),
                            fontWeight: FontWeight.bold,
                            fontSize: 20, // set max/base size
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          minFontSize: 10,
                          maxFontSize: 30,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Container Riwayat
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul Riwayat
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Riwayat Absensi hari ini",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    // List Riwayat
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.black12,
                                  child: Icon(Icons.person),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Ardika Muhammad Lazuardi",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "10 November, 06:25",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
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

      // Bottom Navigation
      bottomNavigationBar: BottomAppBar(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tombol Riwayat (navigasi ke RiwayatPage)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RiwayatPage()),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history),
                  Text("Riwayat", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 33, 150, 243),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white),
            ),
            GestureDetector(
              onTap: logout,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, color: Colors.red),
                  Text("Logout", style: TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
