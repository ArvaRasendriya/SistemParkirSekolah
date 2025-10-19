import 'package:flutter/material.dart';

class DaftarGagalPage extends StatelessWidget {
  const DaftarGagalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Menggunakan gradasi warna latar belakang
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3F37C9), // Warna pertama
              Color(0xFF1D1879), // Warna kedua
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white, // Warna kotak putih
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cancel,
                    size: 100, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  "Identitas Tidak Valid",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(242, 0, 0, 0), // Teks hitam
                  ),
                ),
                const Text(
                  "Silahkan periksa identitas Anda dan coba lagi",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(242, 0, 0, 0), // Teks hitam
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // kembali ke halaman sebelumnya
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F37C9),
                    foregroundColor: const Color(0xFF1D1879),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Kembali",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Colors.white
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
