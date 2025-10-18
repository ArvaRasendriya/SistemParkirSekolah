import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanResultPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ScanResultPage({super.key, required this.userData});

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  // 🧠 Simpan QR yang sudah pernah discan di memory (static biar persist antar halaman)
  static final Set<String> _scannedQrIds = {};

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedTime = DateFormat("HH:mm").format(now);
    final formattedDate = DateFormat("dd-MM-yyyy").format(now);

    // Ambil status dari backend (jika ada)
    final rawStatus =
        (widget.userData["status"] ?? "").toString().toLowerCase().trim();

    // Identitas unik QR (bisa dari ID, nama, atau kombinasi lainnya)
    final qrId = (widget.userData["id"] ??
            widget.userData["nama"] ??
            widget.userData["qr_code"] ??
            "")
        .toString();

    // ✅ Logika status lokal + backend
    bool isApproved = false;

    // Jika QR sudah pernah discan di app → langsung tolak
    if (_scannedQrIds.contains(qrId)) {
      isApproved = false;
    } else if (rawStatus.isEmpty ||
        rawStatus.contains("belum") ||
        rawStatus.contains("baru") ||
        rawStatus.contains("masuk") ||
        rawStatus == "approved") {
      isApproved = true;
      _scannedQrIds.add(qrId); // tandai sudah digunakan
    } else if (rawStatus.contains("sudah") ||
        rawStatus.contains("rejected") ||
        rawStatus.contains("dipakai") ||
        rawStatus.contains("used")) {
      isApproved = false;
      _scannedQrIds.add(qrId); // juga tandai agar tetap ditolak ke depannya
    }

    final statusText = isApproved ? "Approved" : "Rejected";
    final statusColor = isApproved ? Colors.green : Colors.red;
    final statusIcon = isApproved ? Icons.check_circle : Icons.cancel;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3F37C9),
              Color(0xFF1D1879),
              
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
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📸 Foto
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
                        child: widget.userData["sim_url"] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: Image.network(
                                    widget.userData["sim_url"].startsWith("http")
                                        ? widget.userData["sim_url"]
                                        : Supabase.instance.client.storage.from("siswa").getPublicUrl(widget.userData["sim_url"]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : const Icon(Icons.credit_card,
                                size: 60, color: Colors.grey),
                      ),
                      // 🔍 Zoom button
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              if (widget.userData["sim_url"] != null) {
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
                                        widget.userData["sim_url"].startsWith("http")
                                            ? widget.userData["sim_url"]
                                            : Supabase.instance.client.storage.from("siswa").getPublicUrl(widget.userData["sim_url"]),
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

                // ✅ Status
                Row(
                  children: [
                    const Text(
                      "Status:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🧑 Info siswa
                _infoRow("Nama", widget.userData["nama"] ?? "-"),
                _infoRow("Kelas", widget.userData["kelas"] ?? "-"),
                _infoRow("Jurusan", widget.userData["jurusan"] ?? "-"),
                const SizedBox(height: 8),

                // ⏰ Waktu & Tanggal
                _infoRow("Waktu", formattedTime),
                _infoRow("Tanggal", formattedDate),
                const SizedBox(height: 20),

                // 🔘 Tombol selesai
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

  // 🔧 Widget info baris
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
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}