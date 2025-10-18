import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../theme/app_theme.dart';
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
      // Filter hanya yang approved
      final approvedAccounts = accounts.where((account) {
        return account['status'] == 'approved';
      }).toList();
      
      setState(() {
        satgasAccounts = approvedAccounts;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching satgas accounts: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading satgas accounts: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
            const SizedBox(width: AppTheme.spaceS),
            Expanded(
              child: Text(
                'Hapus Akun',
                style: AppTheme.h3.copyWith(color: AppTheme.error),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus akun untuk $email?\n\nTindakan ini tidak bisa dibatalkan.',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await authService.deleteSatgasAccount(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Akun berhasil dihapus'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
        fetchSatgasAccounts();
      } catch (e) {
        debugPrint('Error menghapus akun: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error menghapus akun: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  void _showDetailDialog(Map<String, dynamic> account) {
    final fullName = account['full_name'] ?? '-';
    final email = account['email'] ?? 'No email';
    final status = account['status'] ?? 'Unknown';
    final kelas = account['kelas'] ?? '-';
    final jurusan = account['jurusan'] ?? '-';
    final createdAt = account['created_at'];
    final formattedDate = createdAt != null
        ? DateTime.parse(createdAt)
            .toLocal()
            .toString()
            .substring(0, 16)
        : 'Unknown date';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              gradient: AppTheme.primaryGradient,
              boxShadow: AppTheme.shadowLarge(),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceM),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: const Icon(
                          Icons.security,
                          color: AppTheme.textOnPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: AppTheme.h3.copyWith(
                                color: AppTheme.textOnPrimary,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceS,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'approved'
                                    ? AppTheme.success.withOpacity(0.3)
                                    : AppTheme.warning.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textOnPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceL),

                  // Info Cards
                  _buildInfoCard(
                    icon: Icons.email,
                    label: "Email",
                    value: email,
                  ),
                  const SizedBox(height: AppTheme.spaceM),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.class_,
                          label: "Kelas",
                          value: kelas,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.school,
                          label: "Jurusan",
                          value: jurusan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),

                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    label: "Terdaftar Sejak",
                    value: formattedDate,
                  ),
                  const SizedBox(height: AppTheme.spaceL),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteAccount(account['id'], email);
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text("Hapus"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: AppTheme.textOnPrimary,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spaceM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: AppTheme.textOnPrimary,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spaceM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                          child: const Text("Tutup"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required dynamic value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.textOnPrimary.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textOnPrimary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString() ?? '-',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Akun Satgas',
          style: AppTheme.h3.copyWith(
            color: AppTheme.textOnPrimary,
          ),
        ),
        centerTitle: true,  
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.pending_actions, color: AppTheme.textOnPrimary),
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
            icon: const Icon(Icons.refresh, color: AppTheme.textOnPrimary),
            onPressed: fetchSatgasAccounts,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.textOnPrimary),
            )
          : satgasAccounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 80,
                        color: AppTheme.textOnPrimary.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppTheme.spaceL),
                      Text(
                        'Tidak ada akun satgas',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchSatgasAccounts,
                  color: AppTheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceL,
                      100,
                      AppTheme.spaceL,
                      AppTheme.spaceL,
                    ),
                    child: ListView.builder(
                      itemCount: satgasAccounts.length,
                      itemBuilder: (context, index) {
                        final account = satgasAccounts[index];
                        final fullName = account['full_name'] ?? 'No name';
                        final email = account['email'] ?? 'No email';
                        final status = account['status'] ?? 'Unknown';
                        final kelas = account['kelas'] ?? '-';
                        final jurusan = account['jurusan'] ?? '-';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppTheme.spaceL),
                            opacity: 0.15,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppTheme.spaceM),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                      ),
                                      child: const Icon(
                                        Icons.security,
                                        color: AppTheme.textOnPrimary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spaceM),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullName,
                                            style: AppTheme.h3.copyWith(
                                              color: AppTheme.textOnPrimary,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "$kelas - $jurusan",
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.textOnPrimary.withOpacity(0.7),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.info_outline,
                                        color: AppTheme.textOnPrimary,
                                      ),
                                      onPressed: () => _showDetailDialog(account),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spaceM),

                                // Email Container
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spaceM),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.email,
                                        size: 16,
                                        color: AppTheme.textOnPrimary.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: AppTheme.spaceS),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.textOnPrimary.withOpacity(0.9),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: AppTheme.spaceS),

                                // Status Badge & Delete Button
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spaceM,
                                        vertical: AppTheme.spaceS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.success.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                        border: Border.all(
                                          color: AppTheme.success.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: AppTheme.textOnPrimary,
                                          ),
                                          const SizedBox(width: AppTheme.spaceS),
                                          Text(
                                            'ACTIVE',
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.textOnPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: AppTheme.error.withOpacity(0.9),
                                        size: 24,
                                      ),
                                      onPressed: () => _deleteAccount(account['id'], email),
                                      tooltip: 'Hapus akun',
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