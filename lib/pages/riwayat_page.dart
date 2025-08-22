import 'package:flutter/material.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3), // warna biru
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        title: const Text("Riwayat", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Icon(Icons.info_outline, color: Colors.white),
          SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Filter tombol
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                  label: const Text("Tanggal", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text("Kelas >", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // List Riwayat
            Expanded(
              child: ListView(
                children: [
                  buildSectionTitle("Hari ini, 10 November 2025"),
                  buildRiwayatTile("Ardika Muhammad Lazuardi", "10 November, 06:25"),
                  buildRiwayatTile("Nanda Saskia Ramadhani", "10 November, 06:22"),
                  buildRiwayatTile("Cicaa Cacciii", "10 November, 06:20"),
                  buildSectionTitle("Kemarin, 9 November 2025"),
                  buildRiwayatTile("Kurt Cobain", "9 November, 06:07"),
                  buildRiwayatTile("Maman Firdaus", "9 November, 06:09"),
                  buildSectionTitle("8 November 2025"),
                  buildRiwayatTile("Thom Yorke", "8 November, 06:20"),
                  buildRiwayatTile("Abdul Mamang Kasep", "8 November, 06:23"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildRiwayatTile(String name, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[400],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.white),
        ],
      ),
    );
  }
}