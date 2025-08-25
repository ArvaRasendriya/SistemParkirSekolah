import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BerhasilScanPage extends StatefulWidget {
  final String parkirId; // id parkir hasil scan
  const BerhasilScanPage({super.key, required this.parkirId});

  @override
  State<BerhasilScanPage> createState() => _BerhasilScanPageState();
}

class _BerhasilScanPageState extends State<BerhasilScanPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await supabase
        .from('parkir')
        .select('id, waktu, tanggal, status, siswa (id, nama, kelas, jurusan, sim_url)')
        .eq('id', widget.parkirId)
        .single();

    setState(() {
      data = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[400],
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Foto SIM
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data!['siswa']['sim_url'], // sim_url dari supabase
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.account_circle,
                                    size: 80, color: Colors.black54);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "KARTU E SIM",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Informasi siswa + parkir
                    buildRow("Nama", data!['siswa']['nama']),
                    buildRow("Kelas", data!['siswa']['kelas']),
                    buildRow("Jurusan", data!['siswa']['jurusan']),
                    buildRow("Waktu", data!['waktu']),
                    buildRow("Tanggal", data!['tanggal']),
                    buildRow(
                        "Status",
                        data!['status'] == "Masuk"
                            ? "✅ ${data!['status']}"
                            : "❌ ${data!['status']}"),

                    const SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Selesai",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
