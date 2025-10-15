import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSimPage extends StatefulWidget {
  const AdminSimPage({super.key});

  @override
  State<AdminSimPage> createState() => _AdminSimPageState();
}

class _AdminSimPageState extends State<AdminSimPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> simData = [];
  List<Map<String, dynamic>> filteredData = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSimData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredData = simData.where((item) {
        final nama = (item["nama"] ?? "").toString().toLowerCase();
        final kelas = (item["kelas"] ?? "").toString().toLowerCase();
        return nama.contains(query) || kelas.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchSimData() async {
    setState(() => _loading = true);
    try {
      final response = await supabase
          .from("siswa")
          .select()
          .order("created_at", ascending: false);

      setState(() {
        simData = List<Map<String, dynamic>>.from(response);
        filteredData = simData;
      });
    } catch (e) {
      debugPrint("Error fetch data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat data SIM")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteSim(String id) async {
    try {
      await supabase.from("siswa").delete().eq("id", id);
      _fetchSimData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data SIM berhasil dihapus 🗑️")),
        );
      }
    } catch (e) {
      debugPrint("Error delete SIM: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus data SIM")),
        );
      }
    }
  }

  void _goToPendingApproval() {
    Navigator.pushNamed(context, '/pendingSimApproval');
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFFF8F8FF);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Data SIM',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: _goToPendingApproval,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF5146D9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: textColor),
            onPressed: _fetchSimData,
          ),
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
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                child: Column(
                  children: [
                    // 🔍 Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Siapa yang kamu cari?",
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: PopupMenuButton<String>(
                            icon: const Icon(Icons.filter_list,
                                color: Colors.white),
                            onSelected: (value) {
                              if (value == 'Semua Kelas') {
                                setState(() {
                                  filteredData = simData;
                                });
                              } else {
                                setState(() {
                                  filteredData = simData
                                      .where((item) =>
                                          (item["kelas"] ?? "")
                                              .toString()
                                              .toLowerCase() ==
                                          value.toLowerCase())
                                      .toList();
                                });
                              }
                            },
                            itemBuilder: (context) {
                              final kelasSet = simData
                                  .map((e) => e["kelas"]?.toString() ?? "")
                                  .where((k) => k.isNotEmpty)
                                  .toSet()
                                  .toList();
                              return [
                                const PopupMenuItem(
                                    value: 'Semua Kelas',
                                    child: Text('Semua Kelas')),
                                ...kelasSet.map(
                                  (k) =>
                                      PopupMenuItem(value: k, child: Text(k)),
                                ),
                              ];
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 📋 Daftar Data
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchSimData,
                        color: const Color(0xFF3F37C9),
                        child: filteredData.isEmpty
                            ? const Center(
                                child: Text(
                                  'Tidak ada hasil ditemukan 😕',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredData.length,
                                itemBuilder: (context, index) {
                                  final sim = filteredData[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.white24, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: const Icon(Icons.credit_card,
                                          color: textColor),
                                      title: Text(
                                        sim["nama"] ?? "-",
                                        style: const TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            "Kelas: ${sim["kelas"] ?? "-"}",
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13),
                                          ),
                                          Text(
                                            "Email: ${sim["email"] ?? "-"}",
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        onPressed: () =>
                                            _deleteSim(sim["id"]),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
