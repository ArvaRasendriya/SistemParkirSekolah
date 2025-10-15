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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Pending Approvals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              Color(0xFF3F37C9),
              Color(0xFF1D1879),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                        'Tidak ada akun pending',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 90, 16, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
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
                              color: Colors.white.withOpacity(0.08),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.6,
                                ),
                              ),
                              margin: const EdgeInsets.only(bottom: 14),
                              shadowColor: Colors.black.withOpacity(0.3),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person,
                                            color: Colors.white70, size: 28),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            email,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Role: $role',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    Text(
                                      'Applied: $formattedDate',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () =>
                                              rejectProfile(profile['id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.red.withOpacity(0.85),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Reject',
                                            style: TextStyle(
                                                fontFamily: 'Montserrat'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: () =>
                                              approveProfile(profile['id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.withOpacity(0.85),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Approve',
                                            style: TextStyle(
                                                fontFamily: 'Montserrat'),
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
        ),
      ),
    );
  }
}