import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScanResultPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ScanResultPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedTime = DateFormat("HH:mm").format(now);
    final formattedDate = DateFormat("dd-MM-yyyy").format(now);

    return Scaffold(
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
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto dengan tombol zoom
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          minHeight: 160,
                          maxHeight: 220,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: userData["sim_url"] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: Image.network(
                                    userData["sim_url"],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : const Icon(Icons.credit_card,
                                size: 60, color: Colors.grey),
                      ),
                      // Tombol zoom
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              if (userData["sim_url"] != null) {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.black,
                                    insetPadding: const EdgeInsets.all(10),
                                    child: InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 0.8,
                                      maxScale: 4,
                                      child: Image.network(
                                        userData["sim_url"],
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Status
                Row(
                  children: const [
                    Text(
                      "Status:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
                const SizedBox(height: 12),

                // Info siswa
                _infoRow("Nama", userData["nama"] ?? "-"),
                _infoRow("Kelas", userData["kelas"] ?? "-"),
                _infoRow("Jurusan", userData["jurusan"] ?? "-"),
                const SizedBox(height: 8),

                // Waktu & Tanggal
                _infoRow("Waktu", formattedTime),
                _infoRow("Tanggal", formattedDate),
                const SizedBox(height: 20),

                // Tombol selesai
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      elevation: 6,
                      shadowColor: Colors.black45,
                    ),
                    child: const Text(
                      "Selesai",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  // Helper widget row info
  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            "$label:",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
