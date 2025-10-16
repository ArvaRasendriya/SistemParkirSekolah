import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingSimApprovalPage extends StatefulWidget {
  const PendingSimApprovalPage({super.key});

  @override
  State<PendingSimApprovalPage> createState() => _PendingSimApprovalPageState();
}

class _PendingSimApprovalPageState extends State<PendingSimApprovalPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pendingList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() => _loading = true);
    try {
      final response = await supabase
          .from('pending_siswa')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        pendingList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching pending data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat data pending SIM")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> approveSiswa(Map<String, dynamic> data) async {
    try {
      final id = data["id"];

      final qrValidationResult = QrValidator.validate(
        data: id,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.Q,
      );
      if (qrValidationResult.status != QrValidationStatus.valid) {
        throw Exception("QR Code tidak valid");
      }

      final painter = QrPainter.withQr(
        qr: qrValidationResult.qrCode!,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );

      final uiImage = await painter.toImage(300);
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final qrBytes = byteData!.buffer.asUint8List();

      final qrFileName = "${DateTime.now().millisecondsSinceEpoch}.png";
      final qrPath = "qr/$qrFileName";
      await supabase.storage.from("siswa").uploadBinary(
            qrPath,
            qrBytes,
            fileOptions: const FileOptions(contentType: "image/png"),
          );

      await supabase.from("siswa").insert({
        "id": id,
        "nama": data["nama"],
        "kelas": data["kelas"],
        "jurusan": data["jurusan"],
        "email": data["email"],
        "sim_url": data["sim_url"],
        "qr_url": qrPath,
        "status": "approved",
        "created_at": DateTime.now().toIso8601String(),
      });

      await supabase.from("pending_siswa").delete().eq("id", id);

      Future.microtask(() async {
        try {
          final qrUrl = supabase.storage.from("siswa").getPublicUrl(qrPath);
          final response = await supabase.functions.invoke(
            "sendEmailQr",
            body: {
              "email": data["email"],
              "nama": data["nama"],
              "kelas": data["kelas"],
              "jurusan": data["jurusan"],
              "qr_url": qrUrl,
            },
          );
          debugPrint("📧 Email sent: ${response.data}");
        } catch (e) {
          debugPrint("❌ Gagal kirim email: $e");
        }
      });

      _fetchPending();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Siswa ${data["nama"]} berhasil di-approve ✅')),
      );
    } catch (e) {
      debugPrint("Error approve: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal approve: $e")),
      );
    }
  }

  Future<void> rejectSiswa(String id) async {
    try {
      await supabase.from("pending_siswa").delete().eq("id", id);
      _fetchPending();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data SIM ditolak ❌')),
      );
    } catch (e) {
      debugPrint("Error reject: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menolak data SIM")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFFF8F8FF);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Pending Approvals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: textColor),
            onPressed: _fetchPending,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3F37C9),
              Color(0xFF1D1879),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : pendingList.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada data pending SIM',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                    child: ListView.builder(
                      itemCount: pendingList.length,
                      itemBuilder: (context, index) {
                        final sim = pendingList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white24, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: textColor, size: 26),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sim["nama"] ?? "-",
                                        style: const TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Email: ${sim["email"] ?? "-"}",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                Text(
                                  "Kelas: ${sim["kelas"] ?? "-"}",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                Text(
                                  "Jurusan: ${sim["jurusan"] ?? "-"}",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () =>
                                          rejectSiswa(sim["id"].toString()),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text("Reject"),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => approveSiswa(sim),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.greenAccent
                                            .withOpacity(0.9),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text("Approve"),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
