import 'package:flutter/material.dart';

class AdminSimPage extends StatefulWidget {
  const AdminSimPage({super.key});

  @override
  State<AdminSimPage> createState() => _AdminSimPageState();
}

class _AdminSimPageState extends State<AdminSimPage> {
  // Data dummy SIM
  final List<Map<String, dynamic>> simData = [
    {
      "id": "1",
      "nama": "Andi Saputra",
      "nomor": "SIM123456",
      "jenis": "C",
      "created_at": "2025-09-20 10:30"
    },
    {
      "id": "2",
      "nama": "Budi Santoso",
      "nomor": "SIM654321",
      "jenis": "A",
      "created_at": "2025-09-21 09:15"
    },
    {
      "id": "3",
      "nama": "Citra Dewi",
      "nomor": "SIM789012",
      "jenis": "C",
      "created_at": "2025-09-22 14:05"
    },
  ];

  Future<void> _refreshDummy() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data dummy di-refresh')),
    );
  }

  void _approveSim(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('SIM $id divalidasi ✅')),
    );
  }

  void _rejectSim(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('SIM $id ditolak ❌')),
    );
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data dummy di-refresh')),
              );
            },
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
        child: RefreshIndicator(
          onRefresh: _refreshDummy,
          child: simData.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Text(
                        'Belum ada data SIM',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    ),
                  ],
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
                                      sim["nama"],
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
                                'Nomor SIM: ${sim["nomor"]}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              Text(
                                'Jenis SIM: ${sim["jenis"]}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              Text(
                                'Dibuat: ${sim["created_at"]}',
                                style: TextStyle(color: Colors.grey[700]),
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
                                    onPressed: () => _rejectSim(sim["id"]),
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    label: const Text(
                                      'Tidak Valid',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => _approveSim(sim["id"]),
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
      ),
    );
  }
}
