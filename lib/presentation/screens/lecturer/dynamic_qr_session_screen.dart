import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/session_model.dart';
import '../../providers/lecturer_session_provider.dart';
import '../../widgets/status_badge.dart';
import 'attendance_recap_screen.dart';

class DynamicQrSessionScreen extends StatelessWidget {
  const DynamicQrSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<LecturerSessionProvider>();
    final session = sessionProvider.activeSession;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sesi Perkuliahan')),
        body: const Center(child: Text('Tidak ada sesi yang sedang aktif')),
      );
    }

    final remaining = session.remainingTime;
    final remainingMinutes = remaining.inMinutes;
    final remainingSeconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final isClosed = session.status == SessionStatus.tutup;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${session.courseName} (${session.className})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Lihat Rekap Kehadiran',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AttendanceRecapScreen(sessionId: session.id),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner (Sesi Berjalan / Selesai)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isClosed ? AppColors.errorBg : AppColors.successBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isClosed ? Icons.lock : Icons.timer,
                        size: 20,
                        color: isClosed ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: AppDimensions.spaceSM),
                      Text(
                        isClosed
                            ? 'Sesi Absensi Telah Ditutup'
                            : 'Sisa Waktu Sesi: $remainingMinutes:$remainingSeconds',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isClosed ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      StatusBadge(
                        label: session.mode.displayName,
                        type: session.mode == SessionMode.luring ? BadgeType.info : BadgeType.warning,
                        icon: session.mode == SessionMode.luring ? Icons.location_on : Icons.laptop_chromebook,
                      ),
                      const SizedBox(width: AppDimensions.spaceXS),
                      StatusBadge(
                        label: 'Pertemuan ke-${session.meetingNumber}',
                        type: isClosed ? BadgeType.error : BadgeType.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceMD),

            // Card QR Dinamis
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'QR Code Dinamis (Lapis 4)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Token berubah otomatis setiap 30 detik untuk mencegah kecurangan berbagi foto QR.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // Display QR Code
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: isClosed
                          ? Container(
                              width: 220,
                              height: 220,
                              color: AppColors.background,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2, size: 64, color: AppColors.textMuted),
                                  SizedBox(height: 8),
                                  Text(
                                    'QR Tidak Aktif',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            )
                          : QrImageView(
                              data: session.qrPayload,
                              version: QrVersions.auto,
                              size: 220.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.primaryDark,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spaceMD),

                  // Indikator Hitung Mundur Token
                  if (!isClosed) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sync, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Pembaruan token dalam ${sessionProvider.tokenSecondsLeft} detik',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: sessionProvider.tokenSecondsLeft / AppDimensions.qrTokenIntervalSeconds,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    Text(
                      'Token Aktif: ${session.currentToken} | Sblm: ${session.previousToken ?? "-"}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceMD),

            // Card Ringkasan Kehadiran Sesi Real-time
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    title: 'Total Mahasiswa',
                    value: '${session.totalStudents}',
                    color: AppColors.textPrimary,
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _buildStatItem(
                    context,
                    title: 'Hadir Saat Ini',
                    value: '${session.attendedCount}',
                    color: AppColors.success,
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _buildStatItem(
                    context,
                    title: 'Belum Hadir',
                    value: '${(session.totalStudents - session.attendedCount).clamp(0, session.totalStudents)}',
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceLG),

            // Tombol Aksi: Tutup Sesi & Buka Rekap
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Rekap Sesi'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AttendanceRecapScreen(sessionId: session.id),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceMD),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                      backgroundColor: isClosed ? AppColors.textMuted : AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(isClosed ? Icons.check : Icons.stop_circle_outlined),
                    label: Text(isClosed ? 'Sesi Selesai' : 'Tutup Sesi'),
                    onPressed: isClosed
                        ? null
                        : () {
                            _showCloseConfirmation(context, sessionProvider);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXL),
          ],
        ),
      ),
    );
  }

  void _showCloseConfirmation(BuildContext context, LecturerSessionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutup Sesi Perkuliahan?'),
        content: const Text(
          'Setelah sesi ditutup, mahasiswa yang memindai QR Code akan langsung ditolak (Lapis 3: Sesi sudah ditutup).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              provider.closeCurrentSession();
            },
            child: const Text('Ya, Tutup Sesi'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

