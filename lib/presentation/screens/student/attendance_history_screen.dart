import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_attendance_provider.dart';
import '../../widgets/status_badge.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final student = auth.currentUser;
    final studentProvider = context.watch<StudentAttendanceProvider>();

    if (student == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final historyList = studentProvider.getStudentHistory(student.id);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm WIB');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Presensi'),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: historyList.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_toggle_off_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    Text(
                      'Belum Ada Riwayat Presensi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Catatan kehadiran dari pemindaian QR code atau persetujuan izin/sakit akan tertera di sini secara otomatis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceLG,
                vertical: AppDimensions.spaceMD,
              ),
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final item = historyList[index];
                return _buildModernHistoryCard(context, item, dateFormatter);
              },
            ),
    );
  }

  Widget _buildModernHistoryCard(
    BuildContext context,
    AttendanceModel item,
    DateFormat dateFormatter,
  ) {
    BadgeType badgeType;
    switch (item.status) {
      case AttendanceStatus.hadir:
        badgeType = BadgeType.success;
        break;
      case AttendanceStatus.izin:
      case AttendanceStatus.sakit:
        badgeType = BadgeType.warning;
        break;
      case AttendanceStatus.alfa:
        badgeType = BadgeType.error;
        break;
    }

    final formattedSession = item.sessionId
        .replaceAll('ses_', '')
        .replaceAll('_', ' ')
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  formattedSession,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              StatusBadge(
                label: item.status.displayName.toUpperCase(),
                type: badgeType,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          Text(
            'Presensi Perkuliahan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                dateFormatter.format(item.serverTimestamp),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppDimensions.spaceMD),

          // Detail Audit & Pengukuran Penelitian (ISO/IEC 25010)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.near_me_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Jarak: ${item.distanceMeters.toStringAsFixed(1)} m',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.speed_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Proses: ${item.processDurationMs} ms (KF-14)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (item.editReason != null) ...[
            const SizedBox(height: AppDimensions.spaceSM),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: ${item.editReason!} (${item.editedBy ?? "Dosen"})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
