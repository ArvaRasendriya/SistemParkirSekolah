import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'admin_approval_page.dart';

class SatgasListPage extends StatefulWidget {
  const SatgasListPage({super.key});

  @override
  State<SatgasListPage> createState() => _SatgasListPageState();
}

class _SatgasListPageState extends State<SatgasListPage> {
  final authService = AuthService();
  List<Map<String, dynamic>> satgasAccounts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSatgasAccounts();
  }

  Future<void> fetchSatgasAccounts() async {
    setState(() => isLoading = true);
    try {
      final accounts = await authService.getSatgasAccounts();
      setState(() {
        satgasAccounts = accounts;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching satgas accounts: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading satgas accounts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Akun Satgas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminApprovalPage()),
              );
            },
            tooltip: 'Pending Approvals',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchSatgasAccounts,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : satgasAccounts.isEmpty
                ? const Center(
                    child: Text(
                      'No satgas accounts found',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3), // box hitam transparan
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: satgasAccounts.length,
                        itemBuilder: (context, index) {
                          final account = satgasAccounts[index];
                          final email = account['email'] ?? 'No email';
                          final status = account['status'] ?? 'Unknown';
                          final createdAt = account['created_at'];
                          final formattedDate = createdAt != null
                              ? DateTime.parse(createdAt).toLocal().toString().substring(0, 16)
                              : 'Unknown date';

                          return Card(
                            color: Colors.white.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.person,
                                  color: Colors.grey, size: 32),
                              title: Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: $status',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                  Text(
                                    'Registered: $formattedDate',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
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
