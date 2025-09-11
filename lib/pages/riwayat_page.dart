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

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  Future<void> fetchRiwayat() async {
    setState(() => _loading = true);

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      final response = await supabase
          .from('parkir')
          .select('id, created_at, siswa(nama, kelas)')
          .gte('created_at', thirtyDaysAgo)
          .order('created_at', ascending: false);

      // response is expected to be a List of maps
      final List<Map<String, dynamic>> rows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _rows = rows;
      });
    } catch (e) {
      debugPrint('fetchRiwayat error: $e');
      // optionally show snackbar
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

  // Partitioned grouping (no overlaps)
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

      if (createdAt.isAfter(startToday) || createdAt.isAtSameMomentAs(startToday)) {
        groups['Today']!.add(r);
      } else if (createdAt.isAfter(startYesterday) || createdAt.isAtSameMomentAs(startYesterday)) {
        groups['Yesterday']!.add(r);
      } else if (createdAt.isAfter(start7) || createdAt.isAtSameMomentAs(start7)) {
        // between start7 (inclusive) and startYesterday (exclusive)
        groups['Last 7 Days']!.add(r);
      } else if (createdAt.isAfter(start30) || createdAt.isAtSameMomentAs(start30)) {
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
      appBar: AppBar(title: const Text('Riwayat Parkir')),
      body: RefreshIndicator(
        onRefresh: fetchRiwayat,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _rows.isEmpty
                ? ListView(
                    // make pull-to-refresh possible when empty
                    children: const [
                      SizedBox(height: 150),
                      Center(child: Text('Belum ada riwayat parkir')),
                    ],
                  )
                : ListView(
                    children: [
                      for (final key in displayOrder)
                        if ((grouped[key]?.isNotEmpty ?? false))
                          ExpansionTile(
                            initiallyExpanded: key == 'Today',
                            title: Text(key),
                            children: grouped[key]!.map((r) {
                              final siswa = (r['siswa'] ?? {}) as Map<String, dynamic>;
                              final nama = siswa['nama'] ?? '—';
                              final kelas = siswa['kelas'] ?? '—';
                              final createdAt = DateTime.parse(r['created_at']).toLocal();
                              return ListTile(
                                title: Text(nama),
                                subtitle: Text('Kelas: $kelas'),
                                trailing: Text(formatTime(createdAt)),
                                onTap: () {
                                  // optional: show details or open profile
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(nama),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Kelas: $kelas'),
                                          Text('Waktu: ${formatTime(createdAt)}'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                    ],
                  ),
      ),
    );
  }
}
