import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../theme/app_theme.dart';

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  State<AdminApprovalPage> createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  final authService = AuthService();
  List<Map<String, dynamic>> pendingProfiles = [];
  bool isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPendingProfiles();
  }

  Future<void> fetchPendingProfiles() async {
    setState(() {
      isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final profiles = await authService.getPendingProfiles();
      setState(() {
        pendingProfiles = profiles;
        isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error fetching pending profiles: $e');
      
      String errorMsg;
      if (e.toString().contains('connection') ||
          e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMsg = 'Tidak ada koneksi internet';
      } else if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMsg = 'Akses ditolak';
      } else if (e.toString().contains('timeout')) {
        errorMsg = 'Waktu permintaan habis';
      } else {
        errorMsg = 'Gagal memuat data pending approval';
      }

      setState(() {
        isLoading = false;
        _hasError = true;
        _errorMessage = errorMsg;
      });
    }
  }

  Future<void> approveProfile(String profileId) async {
    try {
      await authService.updateProfileStatus(profileId, 'approved');
      await fetchPendingProfiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile approved successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error approving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving profile: $e'),
            backgroundColor: AppTheme.error,
          ),
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
          SnackBar(
            content: const Text('Profile rejected'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting profile: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showDetailDialog(Map<String, dynamic> profile) {
    final fullName = profile['full_name'] ?? '-';
    final email = profile['email'] ?? 'No email';
    final role = profile['role'] ?? 'Unknown';
    final kelas = profile['kelas'] ?? '-';
    final jurusan = profile['jurusan'] ?? '-';
    final createdAt = profile['created_at'];
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceM),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: const Icon(
                          Icons.person,
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
                            Text(
                              role.toUpperCase(),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textOnPrimary.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceL),

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
                    label: "Tanggal Daftar",
                    value: formattedDate,
                  ),
                  const SizedBox(height: AppTheme.spaceL),

                  AppButton(
                    text: "Tutup",
                    onPressed: () => Navigator.pop(context),
                    isSecondary: true,
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

  Widget _buildErrorState() {
    IconData errorIcon;
    String title;
    String subtitle;
    
    if (_errorMessage?.contains('koneksi internet') ?? false) {
      errorIcon = Icons.wifi_off_rounded;
      title = 'Tidak Ada Koneksi';
      subtitle = 'Pastikan Anda terhubung ke internet dan coba lagi.';
    } else if (_errorMessage?.contains('Akses ditolak') ?? false) {
      errorIcon = Icons.lock_outline_rounded;
      title = 'Akses Ditolak';
      subtitle = 'Anda tidak memiliki izin untuk melihat data ini.';
    } else if (_errorMessage?.contains('timeout') ?? false) {
      errorIcon = Icons.access_time_rounded;
      title = 'Waktu Habis';
      subtitle = 'Server membutuhkan waktu terlalu lama. Coba lagi.';
    } else {
      errorIcon = Icons.error_outline_rounded;
      title = 'Terjadi Kesalahan';
      subtitle = 'Gagal memuat data pending approval. Silakan coba lagi.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorIcon,
                size: 64,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textOnPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textOnPrimary.withOpacity(0.8),
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: fetchPendingProfiles,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Pending Admin Approval',
            style: AppTheme.h3.copyWith(
              color: AppTheme.textOnPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textOnPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.textOnPrimary),
              onPressed: fetchPendingProfiles,
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.textOnPrimary),
                )
              : _hasError
                  ? _buildErrorState()
                  : pendingProfiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 80,
                                color: AppTheme.textOnPrimary.withOpacity(0.5),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              Text(
                                'Tidak ada akun pending',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.textOnPrimary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.spaceL,
                            100,
                            AppTheme.spaceL,
                            AppTheme.spaceL,
                          ),
                          child: RefreshIndicator(
                            onRefresh: fetchPendingProfiles,
                            color: AppTheme.primary,
                            child: ListView.builder(
                              key: ValueKey(pendingProfiles.length),
                              itemCount: pendingProfiles.length,
                              itemBuilder: (context, index) {
                                final profile = pendingProfiles[index];
                                final fullName = profile['full_name'] ?? 'No name';
                                final email = profile['email'] ?? 'No email';
                                final role = profile['role'] ?? 'Unknown';
                                final kelas = profile['kelas'] ?? '-';
                                final jurusan = profile['jurusan'] ?? '-';

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
                                                Icons.person,
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
                                              onPressed: () => _showDetailDialog(profile),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppTheme.spaceM),
                                        
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
                                        
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppTheme.spaceM,
                                            vertical: AppTheme.spaceS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryLight.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                            border: Border.all(
                                              color: AppTheme.primaryLight.withOpacity(0.5),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.admin_panel_settings,
                                                size: 14,
                                                color: AppTheme.textOnPrimary,
                                              ),
                                              const SizedBox(width: AppTheme.spaceS),
                                              Text(
                                                "Role: $role",
                                                style: AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.textOnPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(height: AppTheme.spaceL),
                                        
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => rejectProfile(profile['id']),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.error,
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: AppTheme.spaceM,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                                  ),
                                                ),
                                                child: Text(
                                                  "Reject",
                                                  style: AppTheme.button.copyWith(
                                                    fontSize: 14,
                                                    color: AppTheme.textOnPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: AppTheme.spaceM),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => approveProfile(profile['id']),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.success,
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: AppTheme.spaceM,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                                  ),
                                                ),
                                                child: Text(
                                                  "Approve",
                                                  style: AppTheme.button.copyWith(
                                                    fontSize: 14,
                                                    color: AppTheme.textOnPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
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