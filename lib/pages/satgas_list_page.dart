import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';

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
      appBar: AppBar(
        title: const Text('Satgas Accounts'),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchSatgasAccounts,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : satgasAccounts.isEmpty
                ? const Center(
                    child: Text(
                      'No satgas accounts found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
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
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Status: $status',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                'Registered: $formattedDate',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
