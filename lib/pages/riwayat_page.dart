import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './Qr/qr_scan_page.dart';
import 'daftar_page.dart';
import 'profile_page.dart';

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
  String? _selectedKelas;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 RiwayatPage: initState called');
    fetchRiwayat();
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  Future<void> fetchRiwayat() async {
    debugPrint('🔵 fetchRiwayat: Starting data fetch...');
    
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      debugPrint('🔵 fetchRiwayat: Querying data from $sevenDaysAgo');
      
      final response = await supabase
          .from('parkir')
          .select('id, created_at, siswa(nama, kelas)')
          .gte('created_at', sevenDaysAgo)
          .order('created_at', ascending: false);

      debugPrint('🔵 fetchRiwayat: Raw response type: ${response.runtimeType}');
      debugPrint('🔵 fetchRiwayat: Response data: $response');

      final List<Map<String, dynamic>> rows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      debugPrint('✅ fetchRiwayat: Successfully loaded ${rows.length} records');
      
      // Debug: Print first record if available
      if (rows.isNotEmpty) {
        debugPrint('🔍 fetchRiwayat: Sample record: ${rows.first}');
      } else {
        debugPrint('⚠️ fetchRiwayat: No records found in the last 7 days');
      }

      setState(() {
        _rows = rows;
        _hasError = false;
        _errorMessage = null;
      });
      
      debugPrint('✅ fetchRiwayat: State updated successfully');
      
    } catch (e, stackTrace) {
      debugPrint('❌ fetchRiwayat ERROR: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      String errorMsg;
      IconData errorIcon;

      if (e.toString().contains('connection') ||
          e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMsg = 'Tidak ada koneksi internet';
        errorIcon = Icons.wifi_off;
        debugPrint('❌ Error type: Network/Connection issue');
      } else if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMsg = 'Akses ditolak';
        errorIcon = Icons.lock_outline;
        debugPrint('❌ Error type: Permission denied');
      } else if (e.toString().contains('timeout')) {
        errorMsg = 'Waktu permintaan habis';
        errorIcon = Icons.access_time;
        debugPrint('❌ Error type: Timeout');
      } else {
        errorMsg = 'Gagal memuat riwayat absensi';
        errorIcon = Icons.error_outline;
        debugPrint('❌ Error type: Unknown/General error');
      }

      setState(() {
        _hasError = true;
        _errorMessage = errorMsg;
      });
      
      debugPrint('❌ fetchRiwayat: Error state updated with message: $errorMsg');

      if (mounted) {
        debugPrint('🔔 fetchRiwayat: Showing error SnackBar');
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(errorIcon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: fetchRiwayat,
            ),
          ),
        );
      } else {
        debugPrint('⚠️ fetchRiwayat: Widget not mounted, SnackBar not shown');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        debugPrint('🔵 fetchRiwayat: Loading state set to false');
      } else {
        debugPrint('⚠️ fetchRiwayat: Widget not mounted in finally block');
      }
    }
  }

  DateTime startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

  String formatTime(DateTime t) => DateFormat('dd MMM yyyy HH:mm').format(t);

  String getDayName(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return days[date.weekday - 1];
  }

  Map<String, List<Map<String, dynamic>>> groupRows(List<Map<String, dynamic>> rows) {
    debugPrint('🔵 groupRows: Grouping ${rows.length} rows');
    
    final Map<String, List<Map<String, dynamic>>> groups = {};
    
    final now = DateTime.now();
    final startToday = startOfDay(now);

    // Generate keys untuk 7 hari terakhir
    for (int i = 0; i < 7; i++) {
      final date = startToday.subtract(Duration(days: i));
      String key;
      
      if (i == 0) {
        key = 'Hari Ini';
      } else if (i == 1) {
        key = 'Kemarin';
      } else {
        key = getDayName(date);
      }
      
      groups[key] = [];
    }

    int processedCount = 0;
    int skippedCount = 0;

    // Distribusikan data ke grup yang sesuai
    for (final r in rows) {
      try {
        final createdAtRaw = r['created_at'];
        if (createdAtRaw == null) {
          debugPrint('⚠️ groupRows: Skipped record with null created_at: $r');
          skippedCount++;
          continue;
        }
        
        final createdAt = DateTime.parse(createdAtRaw);
        final createdAtStart = startOfDay(createdAt);

        final daysDifference = startToday.difference(createdAtStart).inDays;

        if (daysDifference < 0 || daysDifference >= 7) {
          debugPrint('⚠️ groupRows: Skipped record outside 7-day range (${daysDifference} days): ${r['id']}');
          skippedCount++;
          continue;
        }

        String targetKey;
        if (daysDifference == 0) {
          targetKey = 'Hari Ini';
        } else if (daysDifference == 1) {
          targetKey = 'Kemarin';
        } else {
          targetKey = getDayName(createdAtStart);
        }

        if (groups.containsKey(targetKey)) {
          groups[targetKey]!.add(r);
          processedCount++;
        }
      } catch (e) {
        debugPrint('❌ groupRows: Error processing record: $r');
        debugPrint('❌ Error: $e');
        skippedCount++;
      }
    }

    debugPrint('✅ groupRows: Processed $processedCount records, skipped $skippedCount');
    
    // Debug: Print group summary
    groups.forEach((key, value) {
      if (value.isNotEmpty) {
        debugPrint('📊 groupRows: "$key" has ${value.length} records');
      }
    });

    return groups;
  }

  Widget _buildErrorState() {
    debugPrint('🔴 Building error state UI');
    
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
      subtitle = 'Gagal memuat data riwayat absensi. Silakan coba lagi.';
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
                color: Color(0xFFF8F8FF),
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
                color: const Color(0xFFF8F8FF).withOpacity(0.8),
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: fetchRiwayat,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F37C9),
                foregroundColor: Colors.white,
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
    debugPrint('🔵 Building RiwayatPage UI - _loading: $_loading, _hasError: $_hasError, rows count: ${_rows.length}');
    
    final filteredRows = _rows.where((r) {
      final nama = (r['siswa'] ?? {})['nama']?.toString().toLowerCase() ?? '';
      final kelas = (r['siswa'] ?? {})['kelas']?.toString() ?? '';
      return nama.contains(_searchQuery) && (_selectedKelas == null || kelas == _selectedKelas);
    }).toList();

    debugPrint('🔍 Filtered rows: ${filteredRows.length} (search: "$_searchQuery", kelas: $_selectedKelas)');

    final grouped = groupRows(filteredRows);
    
    final now = DateTime.now();
    final startToday = startOfDay(now);
    final List<String> displayOrder = [];
    
    for (int i = 0; i < 7; i++) {
      final date = startToday.subtract(Duration(days: i));
      if (i == 0) {
        displayOrder.add('Hari Ini');
      } else if (i == 1) {
        displayOrder.add('Kemarin');
      } else {
        displayOrder.add(getDayName(date));
      }
    }

    final kelasList = _rows
        .map((r) => (r['siswa'] ?? {})['kelas']?.toString() ?? '—')
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
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
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFF8F8FF)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Riwayat Absensi',
                        style: TextStyle(
                          color: Color(0xFFF8F8FF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          '7 Hari Terakhir',
                          style: TextStyle(
                            color: const Color(0xFFF8F8FF).withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (!_hasError) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8FF),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                                debugPrint('🔍 Search query changed: "$value"');
                              },
                              style: const TextStyle(color: Color(0xFF313638)),
                              decoration: InputDecoration(
                                hintText: "Cari nama siswa...",
                                hintStyle: TextStyle(
                                  color: const Color(0xFF313638).withOpacity(0.5),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF3F37C9),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Color(0xFF313638)),
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                          debugPrint('🔍 Search cleared');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFFF8F8FF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF8F8FF).withOpacity(0.4)),
                          ),
                          child: DropdownButton<String?>(
                            value: _selectedKelas,
                            hint: const Text(
                              "Kelas",
                              style: TextStyle(color: Color(0xFFF8F8FF), fontWeight: FontWeight.w600),
                            ),
                            dropdownColor: const Color(0xFF3F37C9),
                            style: const TextStyle(color: Color(0xFFF8F8FF), fontWeight: FontWeight.w600),
                            iconEnabledColor: const Color(0xFFF8F8FF),
                            underline: const SizedBox(),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  "Semua",
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
                              debugPrint('🔍 Kelas filter changed: $value');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '${filteredRows.length} hasil',
                          style: TextStyle(
                            color: const Color(0xFFF8F8FF).withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],

                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFFF8F8FF)),
                        )
                      : _hasError
                          ? _buildErrorState()
                          : RefreshIndicator(
                              onRefresh: () {
                                debugPrint('🔄 Pull-to-refresh triggered');
                                return fetchRiwayat();
                              },
                              color: const Color(0xFF3F37C9),
                              child: filteredRows.isEmpty
                                  ? ListView(
                                      children: [
                                        SizedBox(
                                          height: MediaQuery.of(context).size.height * 0.5,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.inbox_rounded,
                                                size: 64,
                                                color: const Color(0xFFF8F8FF).withOpacity(0.5),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Tidak ada riwayat absensi',
                                                style: TextStyle(
                                                  color: const Color(0xFFF8F8FF).withOpacity(0.7),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.only(bottom: 96),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Column(
                                          children: [
                                            for (final key in displayOrder)
                                              if ((grouped[key]?.isNotEmpty ?? false))
                                                Builder(
                                                  builder: (context) {
                                                    debugPrint('🎨 Rendering UI for group: "$key" with ${grouped[key]!.length} items');
                                                    return Container(
                                                      margin: const EdgeInsets.only(bottom: 16),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF8F8FF).withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Theme(
                                                        data: Theme.of(context).copyWith(
                                                          dividerColor: Colors.transparent,
                                                        ),
                                                        child: ExpansionTile(
                                                          initiallyExpanded: key == 'Hari Ini',
                                                          iconColor: const Color(0xFFF8F8FF),
                                                          collapsedIconColor: const Color(0xFFF8F8FF).withOpacity(0.7),
                                                          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                                          childrenPadding: const EdgeInsets.only(bottom: 12),
                                                          title: Row(
                                                            children: [
                                                              Icon(
                                                                key == 'Hari Ini'
                                                                    ? Icons.today
                                                                    : key == 'Kemarin'
                                                                        ? Icons.calendar_today
                                                                        : Icons.date_range,
                                                                color: const Color(0xFFF8F8FF),
                                                                size: 20,
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Text(
                                                                key,
                                                                style: const TextStyle(
                                                                  color: Color(0xFFF8F8FF),
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                              const Spacer(),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFFF8F8FF).withOpacity(0.25),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                ),
                                                                child: Text(
                                                                  '${grouped[key]!.length}',
                                                                  style: const TextStyle(
                                                                    color: Color(0xFFF8F8FF),
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          children: grouped[key]!.map((r) {
                                                            try {
                                                              final siswa = (r['siswa'] ?? {}) as Map<String, dynamic>;
                                                              final nama = siswa['nama'] ?? '—';
                                                              final kelas = siswa['kelas'] ?? '—';
                                                              final createdAt = DateTime.parse(r['created_at']);

                                                              return Container(
                                                                margin: const EdgeInsets.symmetric(
                                                                  horizontal: 16,
                                                                  vertical: 6,
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFFF8F8FF).withOpacity(0.08),
                                                                  borderRadius: BorderRadius.circular(16),
                                                                  border: Border.all(
                                                                    color: const Color(0xFFF8F8FF).withOpacity(0.15),
                                                                  ),
                                                                ),
                                                                child: ListTile(
                                                                  contentPadding: const EdgeInsets.symmetric(
                                                                    horizontal: 16,
                                                                    vertical: 8,
                                                                  ),
                                                                  leading: Container(
                                                                    width: 48,
                                                                    height: 48,
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(0xFFF8F8FF).withOpacity(0.2),
                                                                      shape: BoxShape.circle,
                                                                    ),
                                                                    child: const Icon(
                                                                      Icons.person,
                                                                      color: Color(0xFFF8F8FF),
                                                                      size: 24,
                                                                    ),
                                                                  ),
                                                                  title: Text(
                                                                    nama,
                                                                    style: const TextStyle(
                                                                      color: Color(0xFFF8F8FF),
                                                                      fontWeight: FontWeight.w600,
                                                                      fontSize: 15,
                                                                    ),
                                                                  ),
                                                                  subtitle: Padding(
                                                                    padding: const EdgeInsets.only(top: 4),
                                                                    child: Text(
                                                                      "Kelas: $kelas",
                                                                      style: TextStyle(
                                                                        color: const Color(0xFFF8F8FF).withOpacity(0.7),
                                                                        fontSize: 13,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  trailing: Column(
                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                                    children: [
                                                                      Text(
                                                                        DateFormat('HH:mm').format(createdAt),
                                                                        style: const TextStyle(
                                                                          color: Color(0xFFF8F8FF),
                                                                          fontSize: 16,
                                                                          fontWeight: FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        DateFormat('dd MMM').format(createdAt),
                                                                        style: TextStyle(
                                                                          color: const Color(0xFFF8F8FF).withOpacity(0.6),
                                                                          fontSize: 11,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              );
                                                            } catch (e) {
                                                              debugPrint('❌ Error rendering ListTile for record: $r');
                                                              debugPrint('❌ Error: $e');
                                                              return Container(
                                                                margin: const EdgeInsets.symmetric(
                                                                  horizontal: 16,
                                                                  vertical: 6,
                                                                ),
                                                                padding: const EdgeInsets.all(16),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.red.withOpacity(0.1),
                                                                  borderRadius: BorderRadius.circular(16),
                                                                ),
                                                                child: Text(
                                                                  'Error rendering item',
                                                                  style: TextStyle(
                                                                    color: const Color(0xFFF8F8FF).withOpacity(0.7),
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF3F37C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3F37C9).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavButton(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),
                
                _buildQRButton(),
                
                _buildNavButton(
                  icon: Icons.person_add_rounded,
                  label: 'Tambah',
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DaftarPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );  
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isActive 
                ? const Color(0xFFF8F8FF).withOpacity(0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: const Color(0xFFF8F8FF),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFFF8F8FF),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrScanPage()),
        );
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFF8F8FF), Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF8F8FF).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Color(0xFF3F37C9),
          size: 36,
        ),
      ),
    );
  }
}