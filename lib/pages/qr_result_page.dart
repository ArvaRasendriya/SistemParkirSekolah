import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScanResultPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ScanResultPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Ambil waktu sekarang
    final now = DateTime.now();
    final formattedTime = DateFormat("HH:mm").format(now);
    final formattedDate = DateFormat("dd-MM-yyyy").format(now);

    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SIM
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: userData["sim_url"] != null
                    ? Image.network(userData["sim_url"], fit: BoxFit.contain)
                    : const Icon(Icons.credit_card, size: 60),
              ),
              const SizedBox(height: 20),

              // Info Status
              Row(
                children: const [
                  Text(
                    "Status:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
              const SizedBox(height: 8),

              // Nama
              Row(
                children: [
                  const Text(
                    "Nama:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(userData["nama"] ?? "-"),
                ],
              ),

              // Kelas
              Row(
                children: [
                  const Text(
                    "Kelas:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(userData["kelas"] ?? "-"),
                ],
              ),

              // Jurusan
              Row(
                children: [
                  const Text(
                    "Jurusan:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(userData["jurusan"] ?? "-"),
                ],
              ),
              const SizedBox(height: 8),

              // Waktu
              Row(
                children: [
                  const Text(
                    "Waktu:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(formattedTime),
                ],
              ),

              // Tanggal
              Row(
                children: [
                  const Text(
                    "Tanggal:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(formattedDate),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text("Selesai"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
