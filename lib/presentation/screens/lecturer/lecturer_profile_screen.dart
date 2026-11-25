import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

/// Halaman Profil Dosen Modern Flat & Minimalis
/// Menampilkan data NIDN, fakultas, prodi, dan aturan multi-perangkat (Lapis 2).
class LecturerProfileScreen extends StatelessWidget {
  const LecturerProfileScreen({super.key});

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
        title: const Text('Profil Dosen'),
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
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
            // 1. Avatar & Info Dosen (Modern Flat)
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
                        user.name.isNotEmpty ? user.name.substring(0, 1) : 'D',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIDN: ${user.identifier}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.prodi} • ${user.fakultas}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceMD),

            // 2. Kartu Aturan Multi-Perangkat (Lapis 2 - Spesifikasi Dosen 2 Perangkat)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
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
                      const Icon(Icons.devices_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Kebijakan Perangkat (Lapis 2)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Kuota Perangkat Dosen',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Maksimal 2 Perangkat',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ID Perangkat Aktif: ${auth.currentDeviceId.length > 20 ? auth.currentDeviceId.substring(0, 20) : auth.currentDeviceId}...',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceMD),

            // 3. Kartu Informasi Afiliasi Akademik
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoTile('Peran Akun', 'Dosen Pengampu / Pengajar'),
                  const Divider(height: 16),
                  _buildInfoTile('Fakultas', user.fakultas ?? 'Fakultas Ilmu Komputer'),
                  const Divider(height: 16),
                  _buildInfoTile('Program Studi', user.prodi ?? 'Informatika'),
                  const Divider(height: 16),
                  _buildInfoTile('Institusi', 'Universitas Almuslim Bireuen'),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceXL),

            // 4. Tombol Keluar (Modern Flat Outlined)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.2),
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onPressed: () {
                _showLogoutConfirmation(context, auth);
              },
            ),
            const SizedBox(height: AppDimensions.spaceLG),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun dosen ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              auth.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }
}

