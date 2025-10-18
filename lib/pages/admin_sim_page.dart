import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class AdminSimPage extends StatefulWidget {
  const AdminSimPage({super.key});

  @override
  State<AdminSimPage> createState() => _AdminSimPageState();
}

class _AdminSimPageState extends State<AdminSimPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> simData = [];
  List<Map<String, dynamic>> filteredData = [];
  bool isLoading = true;
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
    setState(() => isLoading = true);
    try {
      final response =
          await supabase.from("siswa").select().order("created_at", ascending: false);
      setState(() {
        simData = List<Map<String, dynamic>>.from(response);
        filteredData = simData;
      });
    } catch (e) {
      debugPrint("Error fetch data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data SIM: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
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
          SnackBar(content: Text("Gagal menghapus data SIM: $e")),
        );
      }
    }
  }

  /// 🔹 Tombol ke halaman Pending SIM Approval
  void _goToPendingApproval() {
    Navigator.pushNamed(context, '/pendingSimApproval');
  }

  /// 🔹 Tampilkan detail SIM
  void _showSimDetail(Map<String, dynamic> sim) {
  final String? simFileName = sim["sim_url"];
  String? publicUrl;

  if (simFileName != null && simFileName.isNotEmpty) {
    // 🔹 Jika sudah berupa URL lengkap, langsung pakai
    if (simFileName.startsWith("http")) {
      publicUrl = simFileName;
    } else {
      // 🔹 Jika cuma nama file (misal: abc123.jpg), generate via Supabase
      try {
        const bucketName = "siswa";
        final filePath = simFileName;
        publicUrl = Supabase.instance.client.storage
            .from(bucketName)
            .getPublicUrl(filePath);
      } catch (e) {
        debugPrint("Error creating public URL: $e");
      }
    }
  }

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
          padding: const EdgeInsets.all(AppTheme.spaceL),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (sama seperti sebelumnya)
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
                        size: 30,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Kelas: ${sim["kelas"] ?? "-"}",
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textOnPrimary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceL),

                _buildInfoCard(Icons.email, "Email", sim["email"]),
                const SizedBox(height: AppTheme.spaceM),
                _buildInfoCard(Icons.school, "Jurusan", sim["jurusan"]),
                const SizedBox(height: AppTheme.spaceM),

                // 🖼️ Gambar SIM
                if (publicUrl != null && publicUrl.isNotEmpty) ...[
                  Text(
                    "Foto SIM",
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: Image.network(
                      publicUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          alignment: Alignment.center,
                          color: Colors.white.withOpacity(0.1),
                          child: const Text(
                            "Gagal memuat gambar ❌",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  _buildInfoCard(
                    Icons.image_not_supported,
                    "Foto SIM",
                    "Tidak tersedia",
                  ),

                const SizedBox(height: AppTheme.spaceL),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteSim(sim["id"]);
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text("Hapus"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: AppTheme.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spaceM),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceM),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: AppTheme.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spaceM),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                          ),
                        ),
                        child: const Text("Tutup"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  Widget _buildInfoCard(IconData icon, String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textOnPrimary.withOpacity(0.8), size: 20),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textOnPrimary.withOpacity(0.7))),
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
        automaticallyImplyLeading: false,
        title: Text('Data SIM', style: AppTheme.h3.copyWith(color: AppTheme.textOnPrimary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 🔹 Tombol ke Pending Approval (seperti di versi lama)
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
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textOnPrimary),
            onPressed: _fetchSimData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.textOnPrimary))
          : Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spaceL, 100, AppTheme.spaceL, AppTheme.spaceL),
              child: Column(
                children: [
                  // 🔍 Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Cari nama atau kelas...",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        border: InputBorder.none,
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.filter_list, color: Colors.white),
                          onSelected: (value) {
                            if (value == 'Semua Kelas') {
                              setState(() => filteredData = simData);
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
                              const PopupMenuItem(value: 'Semua Kelas', child: Text('Semua Kelas')),
                              ...kelasSet.map((k) => PopupMenuItem(value: k, child: Text(k))),
                            ];
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceL),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchSimData,
                      color: AppTheme.primary,
                      child: filteredData.isEmpty
                          ? const Center(
                              child: Text('Tidak ada hasil ditemukan 😕',
                                  style: TextStyle(color: AppTheme.textOnPrimary)),
                            )
                          : ListView.builder(
                              itemCount: filteredData.length,
                              itemBuilder: (context, index) {
                                final sim = filteredData[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(AppTheme.spaceL),
                                    opacity: 0.15,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(sim["nama"] ?? "-",
                                                  style: AppTheme.h3.copyWith(
                                                      color: AppTheme.textOnPrimary,
                                                      fontSize: 16)),
                                              const SizedBox(height: 4),
                                              Text("Kelas: ${sim["kelas"] ?? "-"}",
                                                  style: AppTheme.bodySmall.copyWith(
                                                      color: AppTheme.textOnPrimary
                                                          .withOpacity(0.7))),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.info_outline,
                                              color: AppTheme.textOnPrimary),
                                          onPressed: () => _showSimDetail(sim),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline,
                                              color: AppTheme.error.withOpacity(0.9)),
                                          onPressed: () => _deleteSim(sim["id"]),
                                        ),
                                      ],
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
    );
  }
}
