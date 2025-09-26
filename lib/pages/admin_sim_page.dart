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
      final response =
          await supabase.from("pending_siswa").select().order("created_at");
      setState(() {
        simData = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetch data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat data")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> approveSiswa(Map<String, dynamic> data) async {
    try {
      await supabase.from("siswa").insert({
        "id": data["id"],
        "nama": data["nama"],
        "kelas": data["kelas"],
        "jurusan": data["jurusan"],
        "email": data["email"],
        "sim_url": data["sim_url"],
        "status": "approved",
        "created_at": DateTime.now().toIso8601String(),
      });

      await supabase.from("pending_siswa").delete().eq("id", data["id"]);

      _fetchSimData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Siswa ${data["nama"]} berhasil di-approve ✅')),
      );
    } catch (e) {
      debugPrint("Error approve: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal approve: $e")),
      );
    }
  }

Future<void> rejectSiswa(Map<String, dynamic> data) async {
  try {
    final simUrl = data["sim_url"];
    if (simUrl != null && simUrl.isNotEmpty) {
      final simPath = simUrl.split("/").skipWhile((part) => part != "sim").join("/");
      await supabase.storage.from("siswa").remove([simPath]);
    }

    await supabase.from("pending_siswa").delete().eq("id", data["id"]);

    _fetchSimData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('SIM ${data["nama"]} ditolak ❌ dan file dihapus')),
    );
  } catch (e) {
    debugPrint("Error reject siswa: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gagal menghapus data SIM")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Data SIM',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchSimData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : simData.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data SIM',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: simData.length,
                    itemBuilder: (context, index) {
                      final sim = simData[index];
                      return TweenAnimationBuilder(
                        duration: Duration(milliseconds: 600 + (index * 200)),
                        curve: Curves.easeOut,
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 40),
                              child: child,
                            ),
                          );
                        },
                        child: Card(
                          color: Colors.white.withOpacity(0.9),
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 6,
                          shadowColor: Colors.black54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.credit_card,
                                        color: Color(0xFF2C5364)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sim["nama"] ?? "-",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Email: ${sim["email"] ?? "-"}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  'Kelas: ${sim["kelas"] ?? "-"}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  'Jurusan: ${sim["jurusan"] ?? "-"}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  'Status: ${sim["status"] ?? "pending"}',
                                  style: TextStyle(
                                    color: sim["status"] == "approved"
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => rejectSiswa(sim["id"]),
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      label: const Text(
                                        'Tidak Valid',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: () => approveSiswa(sim),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Valid'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
