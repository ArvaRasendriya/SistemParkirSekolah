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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSimData();
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
          // Tombol ceklis menuju halaman pending approval
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
            colors: [
              Color(0xFF3F37C9),
              Color(0xFF1D1879),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : simData.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data SIM',
                      style: TextStyle(
                        fontSize: 18,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "Kelas: ${sim["kelas"] ?? "-"}",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                  Text(
                                    "Email: ${sim["email"] ?? "-"}",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteSim(sim["id"]),
                              ),
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
