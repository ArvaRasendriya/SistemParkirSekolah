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
  static const Color _g1 = Color(0xFF1D1879);
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

  Map<String, List<Map<String, dynamic>>> groupRows(List<Map<String, dynamic>> rows) {
    final Map<String, List<Map<String, dynamic>>> groups = {
      'Hari Ini': [],
      'Kemarin': [],
      '7 Hari Yang Lalu': [],
      '30 Hari Yang Lalu': [],
    };

    final now = DateTime.now();
    final startToday = startOfDay(now);
    final startYesterday = startToday.subtract(const Duration(days: 1));
    final start7 = startToday.subtract(const Duration(days: 7));
    final start30 = startToday.subtract(const Duration(days: 30));

    for (final r in rows) {
      final createdAtRaw = r['created_at'];
      if (createdAtRaw == null) continue;
      final createdAt = DateTime.parse(createdAtRaw).toLocal();

      if (createdAt.isAfter(startToday) ||
          createdAt.isAtSameMomentAs(startToday)) {
        groups['Hari Ini']!.add(r);
      } else if (createdAt.isAfter(startYesterday) ||
          createdAt.isAtSameMomentAs(startYesterday)) {
        groups['Kemarin']!.add(r);
      } else if (createdAt.isAfter(start7) ||
          createdAt.isAtSameMomentAs(start7)) {
        groups['7 Hari Yang Lalu']!.add(r);
      } else if (createdAt.isAfter(start30) ||
          createdAt.isAtSameMomentAs(start30)) {
        groups['30 Hari Yang Lalu']!.add(r);
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    // 🔽 Filter rows based on search and kelas
    final filteredRows = _rows.where((r) {
      final nama = (r['siswa'] ?? {})['nama']?.toString().toLowerCase() ?? '';
      final kelas = (r['siswa'] ?? {})['kelas']?.toString() ?? '';
      return nama.contains(_searchQuery) && (_selectedKelas == null || kelas == _selectedKelas);
    }).toList();

    final grouped = groupRows(filteredRows);
    final displayOrder = ['Hari Ini', 'Kemarin', '7 Hari Yang Lalu', '30 Hari Yang Lalu'];

    // 🔽 Ambil semua kelas unik dari data
    final kelasList = _rows
        .map((r) => (r['siswa'] ?? {})['kelas']?.toString() ?? '—')
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      extendBody: true,

      // ===== Body: GRADIENT sama =====
      body: Stack(
        children: [
          // Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3F37C9), Color(0xFF1D1879)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: fetchRiwayat,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFF8F8FF)),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 96),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom top bar with back button
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Color(0xFFF8F8FF)),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),

                          // Search + Filter Row (putih biar kontras)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value.toLowerCase();
                                      });
                                    },
                                    style: const TextStyle(color: Color(0xFF313638)),
                                    decoration: InputDecoration(
                                      hintText: "Siapa yang kamu cari?",
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF313638),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Color(0xFF313638),
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, color: Color(0xFFC7CCFF)),
                                              onPressed: () {
                                                setState(() {
                                                  _searchQuery = '';
                                                });
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: Color(0xFFF8F8FF),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF8F8FF).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Color(0xFFF8F8FF).withOpacity(0.25)),
                                  ),
                                  child: DropdownButton<String?>(
                                    value: _selectedKelas,
                                    hint: const Text(
                                      "Semua Kelas",
                                      style: TextStyle(color: Color(0xFFF8F8FF)),
                                    ),
                                    dropdownColor: Color(0xFFF8F8FF).withOpacity(0.15),
                                    style: const TextStyle(color: Color(0xFFF8F8FF)),
                                    iconEnabledColor: Color(0xFFF8F8FF),
                                    underline: const SizedBox(),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                          "Semua Kelas",
                                          style: TextStyle(color: Color(0xFFF8F8FF)),
                                        ),
                                      ),
                                      ...kelasList.map(
                                        (k) => DropdownMenuItem(
                                          value: k,
                                          child: Text(
                                            k,
                                            style: const TextStyle(color: Color(0xFFF8F8FF)),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedKelas = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                for (final key in displayOrder)
                                  if ((grouped[key]?.isNotEmpty ?? false))
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF8F8FF).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ExpansionTile(
                                        initiallyExpanded: key == 'Hari Ini',
                                        iconColor: Color(0xFFF8F8FF),
                                        collapsedIconColor: Colors.white70,
                                        title: Text(
                                          key,
                                          style: const TextStyle(
                                            color: Color(0xFFF8F8FF),
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
                                                Color(0xFFF8F8FF).withOpacity(0.05),
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
                                                  color: Color(0xFFF8F8FF),
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
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),

      // Floating QR button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3F37C9).withOpacity(0.22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF313638),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),

          // Bigger FAB
          SizedBox(
            width: 90,
            height: 90,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScanPage()),
                );
              },
              backgroundColor: const Color(0xFF3F37C9),
              shape: const CircleBorder(),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 42,
                color: Color(0xFFF8F8FF),
              ),
            ),
          ),
        ],
      ),

      // Bottom nav
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.transparent,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), // radius on top left
            topRight: Radius.circular(20), // radius on top right
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8FF),
            ),
            child: BottomNavigationBar(
              selectedItemColor: Color(0xFF3F37C9),
              unselectedItemColor: Color(0xFF313638),
              selectedLabelStyle: const TextStyle(fontSize: 16),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              type: BottomNavigationBarType.fixed,
              currentIndex: 0,
              onTap: (index) {
                if (index == 1) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DaftarPage()));
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.history, size: 30), label: 'Riwayat'),
                BottomNavigationBarItem(icon: Icon(Icons.add, size: 30,), label: 'Tambah'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
