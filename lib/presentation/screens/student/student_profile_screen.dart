import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Mahasiswa'),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceLG,
          vertical: AppDimensions.spaceMD,
        ),
        child: Column(
          children: [
            // 1. Avatar & Info Utama Card (Modern Flat)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        user.name.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'NPM ${user.identifier}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Program Studi ${user.prodi}\nUniversitas Almuslim',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceMD),

            // 2. Card Pengikatan Perangkat (Lapis 2 - Keamanan Anti Titip Absen)
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                        ),
                        child: const Icon(
                          Icons.phonelink_lock_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengikatan Perangkat (Lapis 2)',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const Text(
                              'Aturan: 1 Akun Mahasiswa = 1 Perangkat HP',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: AppDimensions.spaceMD),
                  _buildDetailRow('Model HP Anda', auth.deviceModel, Icons.smartphone_rounded),
                  _buildDetailRow('ID Perangkat Terikat', user.boundDeviceId ?? 'Belum Terikat', Icons.fingerprint_rounded),
                  _buildDetailRow('Status Keamanan', 'Perangkat Terverifikasi', Icons.verified_user_outlined, isSuccess: true),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceXL),

            // 3. Tombol Keluar (Modern Flat Outlined)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  'Keluar dari Aplikasi',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                onPressed: () {
                  auth.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isSuccess ? AppColors.success : AppColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSuccess ? AppColors.success : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
