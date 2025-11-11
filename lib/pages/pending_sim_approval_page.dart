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
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
    });
    
    try {
      final response = await supabase
          .from('pending_siswa')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        pendingList = List<Map<String, dynamic>>.from(response);
        _hasError = false;
      });
    } catch (e) {
      debugPrint("Error fetching pending data: $e");
      
      String errorMsg;
      if (e.toString().contains('connection') ||
          e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMsg = 'Tidak ada koneksi internet';
      } else if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMsg = 'Akses ditolak';
      } else if (e.toString().contains('timeout')) {
        errorMsg = 'Waktu permintaan habis';
      } else {
        errorMsg = 'Gagal memuat data pending SIM';
      }

      setState(() {
        _hasError = true;
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showLoadingDialog(String studentName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 2 * 3.14159,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                
                const SizedBox(height: 24),
                
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Memproses Approval',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    studentName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressStep('Membuat QR Code', true),
                    _buildProgressStep('Menyimpan data', true),
                    _buildProgressStep('Mengirim email', true),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Mohon tunggu sebentar...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(String text, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.7),
                ),
              ),
            )
          else
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> approveSiswa(Map<String, dynamic> data) async {
    final studentName = data['nama'] ?? 'Siswa';
    
    _showLoadingDialog(studentName);

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
          await supabase.functions.invoke(
            "sendEmailQr",
            body: {
              "email": data["email"],
              "nama": data["nama"],
              "kelas": data["kelas"],
              "jurusan": data["jurusan"],
              "qr_url": qrUrl,
            },
          );
        } catch (e) {
          debugPrint("Email error: $e");
        }
      });

      Navigator.pop(context);
      
      _showSuccessDialog(studentName);
      
      _fetchPending();
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog(String studentName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppTheme.success,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Berhasil!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                '$studentName berhasil di-approve',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppTheme.error,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Approve',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> rejectSiswa(String id, String nama) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                AppTheme.error.withOpacity(0.95),
                AppTheme.error,
              ],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tolak Data SIM?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Data SIM untuk "$nama" akan ditolak dan dihapus.\n\nTindakan ini tidak dapat dibatalkan.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tolak',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from("pending_siswa").delete().eq("id", id);
        _fetchPending();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✓ Data SIM ditolak'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✗ Error: $e"),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showDetailDialog(Map<String, dynamic> sim) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: AppTheme.primaryGradient,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sim["nama"] ?? "-",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PENDING',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildInfoCard(Icons.email, "Email", sim["email"]),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(Icons.class_, "Kelas", sim["kelas"]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(Icons.school, "Jurusan", sim["jurusan"]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildInfoCard(
                  Icons.calendar_today,
                  "Tanggal Daftar",
                  sim["created_at"] != null
                      ? DateTime.parse(sim["created_at"])
                          .toLocal()
                          .toString()
                          .substring(0, 16)
                      : "-",
                ),
                const SizedBox(height: 20),

                if (sim["sim_url"] != null) ...[
                  const Text(
                    "Foto SIM",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      sim["sim_url"].startsWith("http")
                          ? sim["sim_url"]
                          : supabase.storage.from("siswa").getPublicUrl(sim["sim_url"]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.white.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white.withOpacity(0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Gagal memuat gambar SIM",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Tutup"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString() ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    IconData errorIcon;
    String title;
    String subtitle;
    
    if (_errorMessage?.contains('koneksi internet') ?? false) {
      errorIcon = Icons.wifi_off_rounded;
      title = 'Tidak Ada Koneksi';
      subtitle = 'Pastikan Anda terhubung ke internet dan coba lagi.';
    } else if (_errorMessage?.contains('Akses ditolak') ?? false) {
      errorIcon = Icons.lock_outline_rounded;
      title = 'Akses Ditolak';
      subtitle = 'Anda tidak memiliki izin untuk melihat data ini.';
    } else if (_errorMessage?.contains('timeout') ?? false) {
      errorIcon = Icons.access_time_rounded;
      title = 'Waktu Habis';
      subtitle = 'Server membutuhkan waktu terlalu lama. Coba lagi.';
    } else {
      errorIcon = Icons.error_outline_rounded;
      title = 'Terjadi Kesalahan';
      subtitle = 'Gagal memuat data pending SIM. Silakan coba lagi.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorIcon,
                size: 64,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchPending,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Pending SIM Approval',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchPending,
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : _hasError
                ? _buildErrorState()
                : pendingList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data pending SIM',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPending,
                        color: AppTheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                          itemCount: pendingList.length,
                          itemBuilder: (context, index) {
                            final sim = pendingList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.person_outline,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sim["nama"] ?? "-",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${sim["kelas"]} • ${sim["jurusan"]}",
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.7),
                                                  fontSize: 13,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.info_outline,
                                            color: Colors.white,
                                          ),
                                          onPressed: () => _showDetailDialog(sim),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => rejectSiswa(
                                              sim["id"].toString(),
                                              sim["nama"] ?? "",
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.error,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              "Reject",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => approveSiswa(sim),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.success,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              "Approve",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
      );
  }
}