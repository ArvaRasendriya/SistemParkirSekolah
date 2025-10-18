import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data pending SIM"),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Siswa ${data["nama"]} berhasil di-approve ✅'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error approve: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal approve: $e"),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> rejectSiswa(String id) async {
    try {
      await supabase.from("pending_siswa").delete().eq("id", id);
      _fetchPending();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data SIM ditolak ❌'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error reject: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Gagal menolak data SIM"),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showDetailDialog(Map<String, dynamic> sim) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              gradient: AppTheme.primaryGradient,
              boxShadow: AppTheme.shadowLarge(),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceM),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          color: AppTheme.textOnPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      Expanded(
                        child: Text(
                          sim["nama"] ?? "-",
                          style: AppTheme.h3.copyWith(
                            color: AppTheme.textOnPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceL),

                  // Info Cards
                  _buildInfoCard(
                    icon: Icons.email,
                    label: "Email",
                    value: sim["email"],
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.class_,
                          label: "Kelas",
                          value: sim["kelas"],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.school,
                          label: "Jurusan",
                          value: sim["jurusan"],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    label: "Tanggal Daftar",
                    value: sim["created_at"] != null
                        ? DateTime.parse(sim["created_at"])
                            .toLocal()
                            .toString()
                            .substring(0, 16)
                        : "-",
                  ),
                  const SizedBox(height: AppTheme.spaceL),

                  // SIM Image
                  if (sim["sim_url"] != null) ...[
                    Text(
                      "Foto SIM",
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      child: Image.network(
                        sim["sim_url"].startsWith("http")
                            ? sim["sim_url"]
                            : Supabase.instance.client.storage.from("siswa").getPublicUrl(sim["sim_url"]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.white.withOpacity(0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppTheme.textOnPrimary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: AppTheme.textOnPrimary.withOpacity(0.5),
                                  size: 48,
                                ),
                                const SizedBox(height: AppTheme.spaceS),
                                Text(
                                  "Gagal memuat gambar SIM",
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textOnPrimary.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                  ],

                  // Close Button
                  AppButton(
                    text: "Tutup",
                    onPressed: () => Navigator.pop(context),
                    isSecondary: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required dynamic value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.textOnPrimary.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textOnPrimary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString() ?? '-',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Pending SIM Approval',
          style: AppTheme.h3.copyWith(
            color: AppTheme.textOnPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textOnPrimary),
            onPressed: _fetchPending,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.textOnPrimary),
            )
          : pendingList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: AppTheme.textOnPrimary.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppTheme.spaceL),
                      Text(
                        'Tidak ada data pending SIM',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceL,
                    100,
                    AppTheme.spaceL,
                    AppTheme.spaceL,
                  ),
                  child: ListView.builder(
                    itemCount: pendingList.length,
                    itemBuilder: (context, index) {
                      final sim = pendingList[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(AppTheme.spaceL),
                        opacity: 0.15,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spaceM),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppTheme.textOnPrimary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sim["nama"] ?? "-",
                                        style: AppTheme.h3.copyWith(
                                          color: AppTheme.textOnPrimary,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${sim["kelas"]} - ${sim["jurusan"]}",
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.textOnPrimary.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.info_outline,
                                    color: AppTheme.textOnPrimary,
                                  ),
                                  onPressed: () => _showDetailDialog(sim),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spaceM),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    size: 16,
                                    color: AppTheme.textOnPrimary.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: AppTheme.spaceS),
                                  Expanded(
                                    child: Text(
                                      sim["email"] ?? "-",
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textOnPrimary.withOpacity(0.9),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceL),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => rejectSiswa(sim["id"].toString()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.error,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppTheme.spaceM,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                      ),
                                    ),
                                    child: Text(
                                      "Reject",
                                      style: AppTheme.button.copyWith(
                                        fontSize: 14,
                                        color: AppTheme.textOnPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceM),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => approveSiswa(sim),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.success,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppTheme.spaceM,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                      ),
                                    ),
                                    child: Text(
                                      "Approve",
                                      style: AppTheme.button.copyWith(
                                        fontSize: 14,
                                        color: AppTheme.textOnPrimary,
                                      ),
                                    ),
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
    );
  }
}