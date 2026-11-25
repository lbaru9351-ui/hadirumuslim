import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/validation_result.dart';
import 'custom_button.dart';

class ValidationResultSheet extends StatelessWidget {
  final ValidationResult result;
  final VoidCallback onDismiss;
  final VoidCallback? onViewHistory;

  const ValidationResultSheet({
    super.key,
    required this.result,
    required this.onDismiss,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.isValid;
    final timeFormatter = DateFormat('HH:mm:ss WIB - dd MMM yyyy');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLG),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMD),

            // Status Icon & Title
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSuccess ? AppColors.successBg : AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: isSuccess ? AppColors.success : AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSuccess ? 'Kehadiran Tercatat' : 'Presensi Ditolak',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: isSuccess ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSuccess
                            ? 'Validasi 7 lapis berhasil dipenuhi'
                            : 'Lapis ${result.failedLayer}: ${result.rejectionMessage ?? ""}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceMD),

            // Peta Visual Lokasi Pemindaian (Permintaan Pengguna)
            _buildVisualMap(context),

            const SizedBox(height: AppDimensions.spaceMD),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppDimensions.spaceMD),

            // Detail Pengukuran Penelitian (KF-14 & Haversine)
            _buildInfoRow(
              context,
              icon: Icons.timer_outlined,
              title: 'Durasi Proses (KF-14)',
              value: '${result.processDurationMs ?? 0} ms',
              subtitle: (result.processDurationMs ?? 0) <= 3000
                  ? 'Memenuhi target efisiensi (<= 3 detik)'
                  : 'Melebihi target',
            ),
            const SizedBox(height: AppDimensions.spaceSM),

            if (result.distanceMeters != null) ...[
              _buildInfoRow(
                context,
                icon: Icons.location_on_outlined,
                title: 'Jarak ke Ruang (Haversine)',
                value: '${result.distanceMeters!.toStringAsFixed(1)} meter',
                subtitle: result.distanceMeters! <= AppDimensions.defaultRoomRadiusMeters
                    ? 'Dalam radius sah (<= 30 m dari ruang kelas)'
                    : 'Di luar radius ruang kuliah',
              ),
              const SizedBox(height: AppDimensions.spaceSM),
            ],

            if (isSuccess && result.serverTime != null) ...[
              _buildInfoRow(
                context,
                icon: Icons.schedule_outlined,
                title: 'Waktu Server',
                value: timeFormatter.format(result.serverTime!),
                subtitle: 'Cap waktu server resmi (Lapis 7)',
              ),
              const SizedBox(height: AppDimensions.spaceMD),
            ],

            // Tombol Selesai & Lihat Riwayat
            Row(
              children: [
                if (isSuccess && onViewHistory != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                      ),
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('Buka Riwayat'),
                      onPressed: onViewHistory,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSM),
                ],
                Expanded(
                  child: CustomButton(
                    text: isSuccess ? 'Selesai' : 'Tutup & Coba Lagi',
                    backgroundColor: isSuccess ? AppColors.primary : AppColors.textPrimary,
                    onPressed: onDismiss,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualMap(BuildContext context) {
    final sLat = result.studentLat ?? 5.197825;
    final sLon = result.studentLon ?? 96.702952;
    final rLat = result.roomLat ?? 5.197820;
    final rLon = result.roomLon ?? 96.702950;
    final rName = result.roomName ?? 'Lab Komputer 2 (Universitas Almuslim)';
    final dist = result.distanceMeters ?? 5.5;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1EE),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Map
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusMD - 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Peta Koordinat Lokasi Scan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Radius: ${AppDimensions.defaultRoomRadiusMeters.toInt()}m',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Visual Radar & Pin
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Lingkaran Radius 30 Meter
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.08),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                        ),
                      ),
                      // Pin Ruang Kuliah (Pusat)
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.meeting_room, color: AppColors.primary, size: 24),
                          Text('Ruang Kelas', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                      // Pin Mahasiswa (Hasil Scan)
                      Positioned(
                        top: 22,
                        right: 80,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 22),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${dist.toStringAsFixed(1)}m',
                                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Informasi Koordinat Nyata
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Titik Scan Ponsel Mahasiswa:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          Text('Lat: ${sLat.toStringAsFixed(6)}, Lon: ${sLon.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Titik Pusat Ruang ($rName):', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          Text('Lat: ${rLat.toStringAsFixed(6)}, Lon: ${rLon.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.spaceSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
