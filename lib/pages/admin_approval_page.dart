import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  State<AdminApprovalPage> createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  final authService = AuthService();
  List<Map<String, dynamic>> pendingProfiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingProfiles();
  }

  Future<void> fetchPendingProfiles() async {
    setState(() => isLoading = true);
    try {
      final profiles = await authService.getPendingProfiles();
      setState(() {
        pendingProfiles = profiles;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching pending profiles: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pending profiles: $e')),
        );
      }
    }
  }

  Future<void> approveProfile(String profileId) async {
    try {
      await authService.updateProfileStatus(profileId, 'approved');
      await fetchPendingProfiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile approved successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error approving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving profile: $e')),
        );
      }
    }
  }

  Future<void> rejectProfile(String profileId) async {
    try {
      await authService.updateProfileStatus(profileId, 'rejected');
      await fetchPendingProfiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile rejected')),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Pending Approvals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
            onPressed: fetchPendingProfiles,
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : pendingProfiles.isEmpty
                  ? const Center(
                      child: Text(
                        'No pending approvals',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(16), // 🔹 Jarak ke tepi
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2), // 🔹 Background belakang card
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        key: ValueKey(pendingProfiles.length),
                        itemCount: pendingProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = pendingProfiles[index];
                          final email = profile['email'] ?? 'No email';
                          final role = profile['role'] ?? 'Unknown';
                          final createdAt = profile['created_at'];
                          final formattedDate = createdAt != null
                              ? DateTime.parse(createdAt)
                                  .toLocal()
                                  .toString()
                                  .substring(0, 16)
                              : 'Unknown date';

                          return Card(
                            color: const Color(0xFF1E2A32),
                            elevation: 4,
                            shadowColor: Colors.black54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person,
                                          color: Colors.white70),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Role: $role',
                                    style: const TextStyle(
                                        color: Colors.white70),
                                  ),
                                  Text(
                                    'Applied: $formattedDate',
                                    style: const TextStyle(
                                        color: Colors.white70),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            rejectProfile(profile['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () =>
                                            approveProfile(profile['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                    ],
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
