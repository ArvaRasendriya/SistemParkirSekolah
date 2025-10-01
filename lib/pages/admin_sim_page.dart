import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSimPage extends StatefulWidget {
  const AdminSimPage({super.key});

  @override
  State<AdminSimPage> createState() => _AdminSimPageState();
}

class _AdminSimPageState extends State<AdminSimPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> simData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSimData();
  }

  Future<void> _fetchSimData() async {
    setState(() => _loading = true);
    try {
      final response =
          await supabase.from("pending_siswa").select().order("created_at");
      setState(() {
        simData = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetch data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat data")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> approveSiswa(Map<String, dynamic> data) async {
    try {
      final id = data["id"];

      // Generate QR
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
      final qrUrl = supabase.storage.from("siswa").getPublicUrl(qrPath);

      await supabase.from("siswa").insert({
        "id": id,
        "nama": data["nama"],
        "kelas": data["kelas"],
        "jurusan": data["jurusan"],
        "email": data["email"],
        "sim_url": data["sim_url"],
        "qr_url": qrUrl,
        "status": "approved",
        "created_at": DateTime.now().toIso8601String(),
      });

      await supabase.from("pending_siswa").delete().eq("id", id);

      Future.microtask(() async {
        try {
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

      _fetchSimData();
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
      _fetchSimData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SIM $id ditolak ❌')),
      );
    } catch (e) {
      debugPrint("Error reject: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal reject: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Data SIM',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchSimData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : simData.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data SIM',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 1, 16, 16), // ✅ ditambahkan seperti SatgasListPage
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: simData.length,
                        itemBuilder: (context, index) {
                          final sim = simData[index];
                          return Card(
                            color: const Color(0xFF1E2A32),
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            shadowColor: Colors.black45,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.credit_card,
                                          color: Colors.white70, size: 20),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          sim["nama"] ?? "-",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Email: ${sim["email"] ?? "-"}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                  Text(
                                    'Kelas: ${sim["kelas"] ?? "-"}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                  Text(
                                    'Jurusan: ${sim["jurusan"] ?? "-"}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                  Text(
                                    'Status: ${sim["status"] ?? "pending"}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: Colors.red, width: 1.2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                        ),
                                        onPressed: () =>
                                            rejectSiswa(sim["id"]),
                                        icon: const Icon(Icons.close,
                                            color: Colors.red, size: 18),
                                        label: const Text(
                                          'Tidak Valid',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => approveSiswa(sim),
                                        icon: const Icon(Icons.check,
                                            color: Colors.white, size: 18),
                                        label: const Text(
                                          'Valid',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          elevation: 3,
                                        ),
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
      ),
    );
  }
}
