import 'package:flutter/material.dart';

class QrResultPage extends StatelessWidget {
  final String nama;
  final String kelas;
  final String jurusan;
  final String qrUrl;

  const QrResultPage({
    super.key,
    required this.nama,
    required this.kelas,
    required this.jurusan,
    required this.qrUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code Anda"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0083B0),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Pendaftaran Berhasil 🎉",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data siswa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text("Nama: $nama",
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.class_, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text("Kelas: $kelas",
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text("Jurusan: $jurusan",
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // QR Code dari Supabase
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.network(
                      qrUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, color: Colors.red, size: 100),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Simpan QR Code ini untuk keperluan absensi / validasi.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // balik ke daftar/login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0083B0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Kembali"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
