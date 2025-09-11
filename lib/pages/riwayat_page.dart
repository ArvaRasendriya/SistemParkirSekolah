import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  String formatTime(DateTime t) =>
      DateFormat('dd MMM yyyy HH:mm').format(t);

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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Parkir',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2193b0), // Ocean Breeze Start
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // balik ke Homepage
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2193b0), // biru lautan
              Color(0xFF6dd5ed)  // langit cerah
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: fetchRiwayat,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : Column(
                    children: [
                      // 🔍 Search Box
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari berdasarkan nama atau kelas...',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      // List Data
                      Expanded(
                        child: _rows.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 150),
                                  Center(
                                    child: Text(
                                      'Belum ada riwayat parkir',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView(
                                padding: const EdgeInsets.all(12),
                                children: [
                                  for (final key in displayOrder)
                                    if ((grouped[key]?.isNotEmpty ?? false))
                                      Card(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        elevation: 4,
                                        child: ExpansionTile(
                                          collapsedIconColor:
                                              const Color(0xFF2193b0),
                                          iconColor: const Color(0xFF2193b0),
                                          title: Text(
                                            key,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2193b0),
                                            ),
                                          ),
                                          children: grouped[key]!
                                              .where((r) {
                                                final siswa =
                                                    (r['siswa'] ?? {})
                                                        as Map<String, dynamic>;
                                                final nama = (siswa['nama'] ??
                                                        '—')
                                                    .toString()
                                                    .toLowerCase();
                                                final kelas = (siswa['kelas'] ??
                                                        '—')
                                                    .toString()
                                                    .toLowerCase();
                                                return nama.contains(
                                                        _searchQuery) ||
                                                    kelas.contains(
                                                        _searchQuery);
                                              })
                                              .map((r) {
                                                final siswa =
                                                    (r['siswa'] ?? {}) as Map<
                                                        String, dynamic>;
                                                final nama =
                                                    siswa['nama'] ?? '—';
                                                final kelas =
                                                    siswa['kelas'] ?? '—';
                                                final createdAt =
                                                    DateTime.parse(
                                                            r['created_at'])
                                                        .toLocal();
                                                return ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        const Color(
                                                            0xFF2193b0),
                                                    child: Text(
                                                      nama.isNotEmpty
                                                          ? nama[0]
                                                          : '?',
                                                      style: const TextStyle(
                                                          color:
                                                              Colors.white),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    nama,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                      'Kelas: $kelas'),
                                                  trailing: Text(
                                                    formatTime(createdAt),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title: Text(nama),
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                'Kelas: $kelas'),
                                                            Text(
                                                                'Waktu: ${formatTime(createdAt)}'),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child: const Text(
                                                                'OK'),
                                                          )
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              })
                                              .toList(),
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
    );
  }
}