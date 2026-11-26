import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_attendance_provider.dart';
import '../../widgets/status_badge.dart';

/// Halaman Riwayat Presensi Mahasiswa Modern Flat
/// Memuat Kode Bukti Digital Kriptografis, Deteksi Anomali ("Perlu Verifikasi"),
/// Jejak Perubahan Dosen dengan Rantai Hash, serta Hak Pengajuan Sanggahan.
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
        title: const Text('Riwayat & Bukti Presensi'),
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
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
                      'Catatan kehadiran dari pemindaian QR code sah akan tertera di sini bersama kode bukti digital yang dapat diverifikasi oleh Prodi.',
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
                return _buildModernHistoryCard(context, item, dateFormatter, student.id);
              },
            ),
    );
  }

  Widget _buildModernHistoryCard(
    BuildContext context,
    AttendanceModel item,
    DateFormat dateFormatter,
    String studentId,
  ) {
    BadgeType badgeType;
    switch (item.status) {
      case AttendanceStatus.hadir:
        badgeType = BadgeType.success;
        break;
      case AttendanceStatus.izin:
      case AttendanceStatus.sakit:
      case AttendanceStatus.perluVerifikasi:
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

    final isModified = item.isModifiedByLecturer;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: item.status == AttendanceStatus.perluVerifikasi
              ? AppColors.warning.withValues(alpha: 0.6)
              : AppColors.border,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Kartu: Sesi & Status Terkini
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
                icon: item.status == AttendanceStatus.perluVerifikasi
                    ? Icons.flag_outlined
                    : (item.status == AttendanceStatus.hadir ? Icons.check_circle_outline : null),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spaceSM),

          // 2. Judul & Waktu Pemindaian Server
          Text(
            'Presensi Perkuliahan Resmi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 4),
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

          // 3. KODE BUKTI DIGITAL KRIPTOGRAFIS (Digital Proof of Presence)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KODE BUKTI DIGITAL SAH (SERVER)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        item.proofCode,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                  tooltip: 'Salin Kode Bukti',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.proofCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kode bukti disalin: ${item.proofCode}'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 4. KASUS MERAGUKAN / ANOMALI (PRINSIP FAIRNESS)
          if (item.status == AttendanceStatus.perluVerifikasi) ...[
            const SizedBox(height: AppDimensions.spaceSM),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kasus Ditandai: Perlu Verifikasi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.flagReason ??
                              'Pola pemindaian terdeteksi memerlukan konfirmasi. Sesuai prinsip keadilan, kehadiran Anda tidak ditolak langsung dan akan ditinjau Dosen/Prodi.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 5. BANNER PERUBAHAN STATUS OLEH DOSEN (STATUS AWAL TETAP DISIMPAN)
          if (isModified) ...[
            const SizedBox(height: AppDimensions.spaceSM),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_edu_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Status Awal: ${item.initialStatus.displayName.toUpperCase()} → Diubah Menjadi ${item.status.displayName.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alasan Wajib Dosen: "${item.editReason ?? '-'}" (${item.editedBy ?? 'Dosen Pengampu'})',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        item.verifyAuditChainIntegrity() ? Icons.lock_outline : Icons.broken_image_outlined,
                        size: 13,
                        color: item.verifyAuditChainIntegrity() ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.verifyAuditChainIntegrity()
                            ? 'Rantai Hash Audit Log Sah (${item.auditLogs.length} entri terverifikasi)'
                            : 'Peringatan: Anomali Integritas Rantai Hash Terdeteksi!',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: item.verifyAuditChainIntegrity() ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tombol Ajukan Sanggahan
            const SizedBox(height: AppDimensions.spaceSM),
            if (item.canSubmitDispute) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.1),
                  minimumSize: const Size.fromHeight(38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
                icon: const Icon(Icons.gavel_rounded, size: 16),
                label: const Text(
                  'Ajukan Sanggahan / Keberatan ke Prodi',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _showDisputeDialog(context, item, studentId),
              ),
            ] else if (item.disputeStatus != DisputeStatus.none) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: item.disputeStatus == DisputeStatus.approved
                      ? AppColors.successBg
                      : (item.disputeStatus == DisputeStatus.pending ? AppColors.warningBg : AppColors.errorBg),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.disputeStatus == DisputeStatus.approved
                          ? Icons.check_circle_outline
                          : (item.disputeStatus == DisputeStatus.pending
                              ? Icons.hourglass_top_rounded
                              : Icons.cancel_outlined),
                      size: 14,
                      color: item.disputeStatus == DisputeStatus.approved
                          ? AppColors.success
                          : (item.disputeStatus == DisputeStatus.pending ? AppColors.warning : AppColors.error),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.disputeStatus.displayName}: ${item.disputeResolutionNotes ?? item.disputeReason ?? ""}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.disputeStatus == DisputeStatus.approved
                              ? AppColors.success
                              : (item.disputeStatus == DisputeStatus.pending ? AppColors.warning : AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: AppDimensions.spaceMD),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppDimensions.spaceSM),

          // 6. Detail Audit Geofencing & Pengukuran Kinerja (ISO/IEC 25010)
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
                    'Kinerja: ${item.processDurationMs} ms (KF-14)',
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
        ],
      ),
    );
  }

  void _showDisputeDialog(BuildContext context, AttendanceModel item, String studentId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.gavel_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Sanggahan Kehadiran', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda mengajukan keberatan atas perubahan status kehadiran sesi ${item.sessionId.replaceAll("ses_", "").toUpperCase()}. Kode bukti ${item.proofCode} akan diteruskan ke Admin Program Studi.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'Alasan Sanggahan & Bukti:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan mengapa status ini harus dikembalikan ke Hadir...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan sanggahan minimal 5 karakter.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              final studentProvider = context.read<StudentAttendanceProvider>();
              final success = studentProvider.submitDispute(
                attendanceId: item.id,
                studentId: studentId,
                reason: reason,
              );
              Navigator.of(ctx).pop();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sanggahan untuk kode ${item.proofCode} berhasil dikirim ke Admin Prodi!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Kirim Sanggahan'),
          ),
        ],
      ),
    );
  }
}
