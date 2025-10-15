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

  Future<void> _deleteAccount(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1F6F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Akun',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus akun untuk $email?\nTindakan ini tidak bisa dibatalkan.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await authService.deleteSatgasAccount(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun berhasil dihapus')),
          );
        }
        fetchSatgasAccounts();
      } catch (e) {
        debugPrint('Error menghapus akun: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error menghapus akun: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFFF8F8FF);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Akun Satgas',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: textColor),
            tooltip: 'Pending Approvals',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminApprovalPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: textColor),
            onPressed: fetchSatgasAccounts,
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
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : satgasAccounts.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada akun satgas ditemukan.',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                    child: RefreshIndicator(
                      onRefresh: fetchSatgasAccounts,
                      color: const Color(0xFF3F37C9),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 1),
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
                                ? DateTime.parse(createdAt)
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16)
                                : 'Unknown date';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.white24, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.person,
                                  color: textColor,
                                  size: 32,
                                ),
                                title: Text(
                                  email,
                                  style: const TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status: $status',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        'Registered: $formattedDate',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () =>
                                      _deleteAccount(account['id'], email),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}