// admin_dashboard_page.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'admin_approval_page.dart';
import 'satgas_list_page.dart';
import 'admin_sim_page.dart';
import 'login_page.dart'; // pastikan file ada
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardContent(),
    const SatgasListPage(),
    const AdminSimPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bottom nav styling sesuai Zona4: rounded top, white background, icons purple/grey
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFFF8F8FF), // putih sesuai Zona4 bar
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: "Satgas",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card),
              label: "SIM",
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF3F37C9),
          unselectedItemColor: const Color(0xFF313638),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

/// ================= Dashboard Content =================
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final supabase = Supabase.instance.client;

  // Stats
  int jumlahSimApproved = 0;
  int jumlahSimPending = 0;
  int jumlahSatgas = 0;
  int jumlahAdmin = 0;

  // Parkir today
  List<Map<String, dynamic>> sudahParkir = [];
  List<Map<String, dynamic>> belumParkir = [];

  // Pending SIM for activity list
  List<Map<String, dynamic>> pendingSiswa = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    try {
      // 1) Stats: jumlahSimApproved (table 'siswa' status='approved')
      final resApproved = await supabase
          .from('siswa')
          .select<Map<String, dynamic>>('id')
          .eq('status', 'approved');
      jumlahSimApproved = (resApproved as List).length;

      // 2) jumlahSimPending (table 'pending_siswa')
      final resPending = await supabase.from('pending_siswa').select();
      jumlahSimPending = (resPending as List).length;

      // 3) jumlahSatgas & jumlahAdmin from profiles role field
      final profiles = await supabase.from('profiles').select<Map<String, dynamic>>('id, role');
      final List<Map<String, dynamic>> profilesList =
          (profiles as List).map((e) => Map<String, dynamic>.from(e)).toList();
      jumlahSatgas = profilesList.where((p) => (p['role'] ?? '') == 'satgas').length;
      jumlahAdmin = profilesList.where((p) => (p['role'] ?? '') == 'admin').length;

      // 4) Parkir hari ini
      final today = DateTime.now();
      final dateStr = "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // Query parkir today and include siswa relation if available
      final parkirRes = await supabase
          .from('parkir')
          .select('siswa_id, siswa(id, nama, kelas)')
          .eq('tanggal', dateStr);

      final List<Map<String, dynamic>> parkirList = (parkirRes as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Build set of siswa ids who already parked
      final Set<String> parkedIds = {};
      for (final p in parkirList) {
        final sid = p['siswa_id']?.toString();
        if (sid != null) parkedIds.add(sid);
      }

      // Fetch all siswa accounts (from profiles where role = 'siswa')
      final siswaProfilesRes = await supabase
          .from('profiles')
          .select<Map<String, dynamic>>('id, full_name, kelas')
          .eq('role', 'siswa');

      final List<Map<String, dynamic>> siswaProfiles = (siswaProfilesRes as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      sudahParkir = [];
      belumParkir = [];

      for (final s in siswaProfiles) {
        final id = s['id']?.toString() ?? '';
        if (parkedIds.contains(id)) {
          sudahParkir.add(s);
        } else {
          belumParkir.add(s);
        }
      }

      // 5) pending_siswa list for activities (order by created_at desc)
      final pendingRes = await supabase.from('pending_siswa').select().order('created_at', ascending: false);
      pendingSiswa = (pendingRes as List).map((e) => Map<String, dynamic>.from(e)).toList();

      setState(() {});
    } catch (e) {
      debugPrint('Error load dashboard: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat dashboard: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // Approve pending siswa — replicates logic from AdminSimPage:
  Future<void> _approvePending(Map<String, dynamic> data) async {
    try {
      final id = data['id']?.toString();
      if (id == null) throw Exception('ID tidak ditemukan');

      // generate qr
      final qrValidationResult = QrValidator.validate(
        data: id,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.Q,
      );
      if (qrValidationResult.status != QrValidationStatus.valid) {
        throw Exception('QR Code tidak valid');
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

      // insert into siswa table
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

      // delete pending
      await supabase.from("pending_siswa").delete().eq("id", id);

      // try send email via edge function (best-effort)
      try {
        await supabase.functions.invoke("sendEmailQr", body: {
          "email": data["email"],
          "nama": data["nama"],
          "kelas": data["kelas"],
          "jurusan": data["jurusan"],
          "qr_url": qrUrl,
        });
      } catch (e) {
        debugPrint('Gagal kirim email (tidak fatal): $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Siswa ${data["nama"]} berhasil di-approve ✅')));
      await _loadAll();
    } catch (e) {
      debugPrint('Error approve pending: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal approve: $e')));
    }
  }

  Future<void> _rejectPending(String id) async {
    try {
      await supabase.from('pending_siswa').delete().eq('id', id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pending $id ditolak ❌')));
      await _loadAll();
    } catch (e) {
      debugPrint('Error reject pending: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal reject: $e')));
    }
  }

  Widget _buildTopCards() {
    // Two cards: sudah parkir and belum parkir
    return Row(
      children: [
        Expanded(
          child: _MiniListCard(
            title: 'Sudah Parkir Hari Ini',
            items: sudahParkir,
            emptyText: 'Belum ada yang parkir',
            colorIcon: const Color(0xFF3F37C9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniListCard(
            title: 'Belum Parkir Hari Ini',
            items: belumParkir,
            emptyText: 'Semua telah parkir',
            colorIcon: const Color(0xFF3F37C9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    // Four statistic boxes with outline and count below label:
    Widget _stat(String label, int value, Color color) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Jumlah akun', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        _stat('Siswa (SIM Approved)', jumlahSimApproved, const Color(0xFF3F37C9)),
        _stat('Siswa (SIM Pending)', jumlahSimPending, Colors.orangeAccent),
        _stat('Akun Satgas', jumlahSatgas, Colors.blueAccent),
        _stat('Akun Admin', jumlahAdmin, Colors.purpleAccent),
      ],
    );
  }

  Widget _buildActivityList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Text('Aktivitas Terbaru', style: TextStyle(color: Color(0xFFF8F8FF), fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // Container wrapper with outline (background) like kamu minta
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.6),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: pendingSiswa.map((sim) {
              // Use the exact container design you requested
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white24,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.credit_card, color: Color(0xFFF8F8FF), size: 28),
                  title: Text(
                    sim["nama"] ?? "-",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF8F8FF),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'Email: ${sim["email"] ?? "-"}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        'Kelas: ${sim["kelas"] ?? "-"}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        'Jurusan: ${sim["jurusan"] ?? "-"}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        'Status: ${sim["status"] ?? "pending"}',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _rejectPending(sim['id'].toString()),
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                            label: const Text(
                              'Tidak Valid',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _approvePending(sim),
                            icon: const Icon(Icons.check, color: Colors.white, size: 18),
                            label: const Text(
                              'Valid',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 55, 201, 92),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 5,
                              shadowColor: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        bottom: false,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('ADMIN', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            SizedBox(height: 6),
                            Text('Selamat datang di admin dashboard', style: TextStyle(color: Color(0xFFF8F8FF), fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Top two cards: sudah / belum parkir
                      _buildTopCards(),
                      const SizedBox(height: 18),

                      // stats grid (4)
                      _buildStatsGrid(),
                      const SizedBox(height: 18),

                      // activities
                      _buildActivityList(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Small helper widget for top mini list card
class _MiniListCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String emptyText;
  final Color colorIcon;

  const _MiniListCard({
    required this.title,
    required this.items,
    required this.emptyText,
    required this.colorIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFF8F8FF), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(emptyText, style: const TextStyle(color: Colors.white54)))
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, idx) {
                      final row = items[idx];
                      final name = row['full_name'] ?? row['nama'] ?? '-';
                      final kelas = row['kelas'] ?? '-';
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: colorIcon.withOpacity(0.15),
                            child: Icon(Icons.person, color: colorIcon, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(name, style: const TextStyle(color: Colors.white70))),
                          Text(kelas.toString(), style: const TextStyle(color: Colors.white30, fontSize: 12)),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: items.length,
                  ),
          ),
        ],
      ),
    );
  }
}

/// ================== Satgas & Siswa detail pages (kept minimal & themed) ==============
class SatgasListPage extends StatefulWidget {
  const SatgasListPage({super.key});

  @override
  State<SatgasListPage> createState() => _SatgasListPageState();
}

class _SatgasListPageState extends State<SatgasListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> accounts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await supabase.from('profiles').select('id, email, role, created_at').eq('role', 'satgas').order('created_at', ascending: false);
      accounts = (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Error load satgas: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteAccount(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F6F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Apakah kamu yakin menghapus akun $email?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        // contoh: hapus dari auth & profiles (disesuaikan dengan implementasi AuthService)
        await supabase.from('profiles').delete().eq('id', userId);
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun dihapus')));
      } catch (e) {
        debugPrint('Error delete satgas: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Akun Satgas'), backgroundColor: Colors.transparent, elevation: 0),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF3F37C9), Color(0xFF1D1879)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final acc = accounts[index];
                      final email = acc['email'] ?? '-';
                      final date = acc['created_at'] ?? '-';
                      return Card(
                        color: Colors.white.withOpacity(0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.0),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.white70, size: 32),
                          title: Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Registered: ${date.toString().substring(0, 16)}', style: const TextStyle(color: Colors.white70)),
                          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteAccount(acc['id'], email)),
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
      final response = await supabase.from("pending_siswa").select().order("created_at");
      simData = (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint("Error fetch data: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memuat data")));
    } finally {
      if (mounted) setState(() => _loading = false);
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
          debugPrint("❌ Gagal kirim email: $e");
        }
      });

      _fetchSimData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Siswa ${data["nama"]} berhasil di-approve ✅')));
    } catch (e) {
      debugPrint("Error approve: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal approve: $e")));
    }
  }

  Future<void> rejectSiswa(String id) async {
    try {
      await supabase.from("pending_siswa").delete().eq("id", id);
      _fetchSimData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SIM $id ditolak ❌')));
    } catch (e) {
      debugPrint("Error reject: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal reject: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Data SIM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchSimData),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F37C9), Color(0xFF1D1879)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : simData.isEmpty
                ? const Center(child: Text('Belum ada data SIM', style: TextStyle(fontSize: 18, color: Colors.white70)))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                    child: RefreshIndicator(
                      onRefresh: _fetchSimData,
                      color: const Color(0xFF3F37C9),
                      child: ListView.builder(
                        itemCount: simData.length,
                        itemBuilder: (context, index) {
                          final sim = simData[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: const Icon(Icons.credit_card, color: Colors.white70, size: 28),
                              title: Text(sim["nama"] ?? "-", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const SizedBox(height: 6),
                                Text('Email: ${sim["email"] ?? "-"}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                Text('Kelas: ${sim["kelas"] ?? "-"}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                Text('Jurusan: ${sim["jurusan"] ?? "-"}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                Text('Status: ${sim["status"] ?? "pending"}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 12),
                                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => rejectSiswa(sim["id"]),
                                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                    label: const Text('Tidak Valid', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => approveSiswa(sim),
                                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                                    label: const Text('Valid', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 55, 201, 92),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      elevation: 5,
                                      shadowColor: Colors.blueAccent,
                                    ),
                                  ),
                                ]),
                              ]),
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
