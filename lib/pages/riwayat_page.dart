import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tambahan import biar tombol bawah bisa navigasi
import 'qr_scan_page.dart';
import 'daftar_page.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final supabase = Supabase.instance.client;
  bool _loading = false;
  List<Map<String, dynamic>> _rows = [];
  String _searchQuery = '';
  String? _selectedKelas; // 🔽 filter kelas

  // Palet gradient modern
  static const Color _g1 = Color(0xFF1F1B63);
  static const Color _g2 = Color(0xFF3F37C9);

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  Future<void> fetchRiwayat() async {
    setState(() => _loading = true);

    try {
      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      final response = await supabase
          .from('parkir')
          .select('id, created_at, siswa(nama, kelas)')
          .gte('created_at', thirtyDaysAgo)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> rows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _rows = rows;
      });
    } catch (e) {
      debugPrint('fetchRiwayat error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil riwayat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

  String formatTime(DateTime t) => DateFormat('dd MMM yyyy HH:mm').format(t);

  Map<String, List<Map<String, dynamic>>> groupRows() {
    final Map<String, List<Map<String, dynamic>>> groups = {
      'Today': [],
      'Yesterday': [],
      'Last 7 Days': [],
      'Last Month': [],
    };

    final now = DateTime.now();
    final startToday = startOfDay(now);
    final startYesterday = startToday.subtract(const Duration(days: 1));
    final start7 = startToday.subtract(const Duration(days: 7));
    final start30 = startToday.subtract(const Duration(days: 30));

    for (final r in _rows) {
      final createdAtRaw = r['created_at'];
      if (createdAtRaw == null) continue;
      final createdAt = DateTime.parse(createdAtRaw).toLocal();

      if (createdAt.isAfter(startToday) ||
          createdAt.isAtSameMomentAs(startToday)) {
        groups['Today']!.add(r);
      } else if (createdAt.isAfter(startYesterday) ||
          createdAt.isAtSameMomentAs(startYesterday)) {
        groups['Yesterday']!.add(r);
      } else if (createdAt.isAfter(start7) ||
          createdAt.isAtSameMomentAs(start7)) {
        groups['Last 7 Days']!.add(r);
      } else if (createdAt.isAfter(start30) ||
          createdAt.isAtSameMomentAs(start30)) {
        groups['Last Month']!.add(r);
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupRows();
    final displayOrder = ['Today', 'Yesterday', 'Last 7 Days', 'Last Month'];

    // 🔽 Ambil semua kelas unik dari data
    final kelasList = _rows
        .map((r) => (r['siswa'] ?? {})['kelas']?.toString() ?? '—')
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      extendBody: true,

      // ===== AppBar: GRADIENT #1F1B63 → #3F37C9 =====
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_g1, Color.fromRGBO(63, 55, 201, 1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Riwayat Parkir",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.search, color: Colors.white),
          )
        ],
      ),

      // ===== Body: GRADIENT sama =====
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_g1, Color.fromRGBO(63, 55, 201, 1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: fetchRiwayat,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Column(
                    children: [
                      // 🔍 Search + Filter Row (putih biar kontras)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value.toLowerCase();
                                  });
                                },
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: "Cari berdasarkan nama...",
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFC7CCFF),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFFC7CCFF),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<String?>(
                              value: _selectedKelas,
                              hint: const Text(
                                "Kelas",
                                style: TextStyle(color: Color(0xFFE6E8FF)),
                              ),
                              dropdownColor: const Color.fromARGB(50, 255, 255, 255),
                              style: const TextStyle(color: Color.fromARGB(221, 255, 255, 255)),
                              iconEnabledColor: const Color.fromARGB(255, 255, 255, 255),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text("Semua Kelas"),
                                ),
                                ...kelasList.map(
                                  (k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(k),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedKelas = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // 🔽 List data
                      Expanded(
                        child: _rows.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 150),
                                  Center(
                                    child: Text(
                                      'Belum ada riwayat parkir',
                                      style: TextStyle(
                                        color: Color.fromARGB(48, 255, 255, 255),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView(
                                padding: const EdgeInsets.only(bottom: 96),
                                children: [
                                  for (final key in displayOrder)
                                    if ((grouped[key]?.isNotEmpty ?? false))
                                      ExpansionTile(
                                        initiallyExpanded: key == 'Today',
                                        iconColor: Colors.white,
                                        collapsedIconColor: Colors.white70,
                                        title: Text(
                                          key,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        children: grouped[key]!.map((r) {
                                          final siswa = (r['siswa'] ?? {})
                                              as Map<String, dynamic>;
                                          final nama = siswa['nama'] ?? '—';
                                          final kelas = siswa['kelas'] ?? '—';
                                          final createdAt =
                                              DateTime.parse(r['created_at'])
                                                  .toLocal();

                                          return Card(
                                            color:
                                                Colors.white.withOpacity(0.10),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: ListTile(
                                              leading: const Icon(
                                                Icons.person,
                                                color: Colors.white70,
                                              ),
                                              // ✅ perbaikan: cukup satu title, gak pakai DefaultTextStyle
                                              title: Text(
                                                nama,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                "Kelas: $kelas",
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              trailing: Text(
                                                formatTime(createdAt),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                ],
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ),

      // ===== FAB tengah =====
      floatingActionButton: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 6),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _g2.withOpacity(0.22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, 6),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScanPage()),
                );
              },
              backgroundColor: _g2,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ===== Bottom nav putih rounded =====
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.history, color: _g2),
                label: const Text('Riwayat', style: TextStyle(color: _g2)),
              ),
              const SizedBox(width: 40),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DaftarPage()),
                  );
                },
                icon: const Icon(Icons.add, color: Color(0xFF98A2B3)),
                label: const Text(
                  'Tambah',
                  style: TextStyle(color: Color(0xFF98A2B3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
