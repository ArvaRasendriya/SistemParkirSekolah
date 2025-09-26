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
      await fetchPendingProfiles(); // Refresh the list
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
      await fetchPendingProfiles(); // Refresh the list
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
        title: const Text('Pending Approvals'),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchPendingProfiles,
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
        child: RefreshIndicator(
          onRefresh: fetchPendingProfiles,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : pendingProfiles.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'No pending approvals',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pendingProfiles.length,
                      itemBuilder: (context, index) {
                        final profile = pendingProfiles[index];
                        final email = profile['email'] ?? 'No email';
                        final role = profile['role'] ?? 'Unknown';
                        final createdAt = profile['created_at'];
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
                                  'Role: $role',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Text(
                                  'Applied: $formattedDate',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => rejectProfile(profile['id']),
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => approveProfile(profile['id']),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
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
    );
  }
}
