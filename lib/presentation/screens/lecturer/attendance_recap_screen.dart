import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/leave_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lecturer_session_provider.dart';
import '../../widgets/status_badge.dart';

class AttendanceRecapScreen extends StatefulWidget {
  final String sessionId;

  const AttendanceRecapScreen({super.key, required this.sessionId});

  @override
  State<AttendanceRecapScreen> createState() => _AttendanceRecapScreenState();
}

class _AttendanceRecapScreenState extends State<AttendanceRecapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<LecturerSessionProvider>();
    final auth = context.watch<AuthProvider>();
    final attendances = sessionProvider.currentSessionAttendances;
    final leaveRequests = sessionProvider.sessionLeaveRequests;
    final timeFormatter = DateFormat('HH:mm:ss WIB');

    final hadirCount = attendances.where((a) => a.status == AttendanceStatus.hadir).length;
    final izinCount = attendances.where((a) => a.status == AttendanceStatus.izin).length;
    final sakitCount = attendances.where((a) => a.status == AttendanceStatus.sakit).length;
    final alfaCount = attendances.where((a) => a.status == AttendanceStatus.alfa).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rekap & Verifikasi Sesi'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Presensi (${attendances.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Izin / Sakit (${leaveRequests.length})'),
                  if (leaveRequests.any((r) => r.status == LeaveStatus.pending)) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Presensi Mahasiswa & Audit Log
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildSummaryBadge('Hadir', hadirCount, AppColors.success, AppColors.successBg),
                    const SizedBox(width: AppDimensions.spaceSM),
                    _buildSummaryBadge('Izin', izinCount, AppColors.warning, AppColors.warningBg),
                    const SizedBox(width: AppDimensions.spaceSM),
                    _buildSummaryBadge('Sakit', sakitCount, AppColors.info, AppColors.infoBg),
                    const SizedBox(width: AppDimensions.spaceSM),
                    _buildSummaryBadge('Alfa', alfaCount, AppColors.error, AppColors.errorBg),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.security, size: 18, color: AppColors.info),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sistem Integritas Data (ISO/IEC 25010): Kehadiran sah via pemindaian QR dikunci agar tidak dapat diubah sepihak menjadi Alfa.',
                          style: TextStyle(fontSize: 11, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                if (attendances.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceXL),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'Belum ada mahasiswa yang tercatat hadir pada sesi ini.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...attendances.map(
                    (item) => _buildStudentAttendanceItem(
                      context,
                      item,
                      timeFormatter,
                      sessionProvider,
                      auth.currentUser?.name ?? 'Dosen',
                    ),
                  ),
              ],
            ),
          ),

          // Tab 2: Verifikasi Izin & Sakit Mahasiswa
          _buildLeaveRequestsTab(context, leaveRequests, sessionProvider, auth.currentUser?.name ?? 'Dosen'),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(String title, int count, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(color: textColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceItem(
    BuildContext context,
    AttendanceModel item,
    DateFormat timeFormatter,
    LecturerSessionProvider provider,
    String lecturerName,
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.studentName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        if (item.isQrVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 16, color: AppColors.primary),
                        ],
                      ],
                    ),
                    Text(
                      'NPM ${item.studentNpm} • ${timeFormatter.format(item.serverTimestamp)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: item.status.displayName, type: badgeType),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.isOnlineMode
                    ? 'Sesi Daring (Online Zoom/Meet)'
                    : 'Jarak: ${item.distanceMeters.toStringAsFixed(1)} m | KF-14: ${item.processDurationMs} ms',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(60, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Dispensasi', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  _showEditStatusDialog(context, item, provider, lecturerName);
                },
              ),
            ],
          ),
          if (item.auditLogs.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Jejak Audit: Diubah ke ${item.status.displayName} oleh ${item.auditLogs.last.changedBy} (Alasan: ${item.auditLogs.last.reason})',
                style: const TextStyle(fontSize: 11, color: AppColors.warning),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaveRequestsTab(
    BuildContext context,
    List<LeaveRequestModel> requests,
    LecturerSessionProvider provider,
    String lecturerName,
  ) {
    if (requests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spaceXL),
          child: Text('Tidak ada permohonan izin atau sakit dari mahasiswa pada sesi ini.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final isPending = req.status == LeaveStatus.pending;

        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
          padding: const EdgeInsets.all(AppDimensions.spaceMD),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    req.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  StatusBadge(
                    label: req.status.displayName,
                    type: req.status == LeaveStatus.approved
                        ? BadgeType.success
                        : req.status == LeaveStatus.rejected
                            ? BadgeType.error
                            : BadgeType.warning,
                  ),
                ],
              ),
              Text(
                'NPM ${req.studentNpm} • Jenis: ${req.type.displayName.toUpperCase()}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Alasan: ${req.reason}',
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
              if (req.attachmentName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Lampiran Dokumen: ${req.attachmentName}',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              if (isPending) ...[
                const SizedBox(height: AppDimensions.spaceMD),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        onPressed: () {
                          provider.reviewLeaveRequest(
                            requestId: req.id,
                            isApproved: false,
                            lecturerName: lecturerName,
                            note: 'Dokumen bukti tidak lengkap',
                          );
                        },
                        child: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSM),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () {
                          provider.reviewLeaveRequest(
                            requestId: req.id,
                            isApproved: true,
                            lecturerName: lecturerName,
                            note: 'Disetujui dosen pengampu',
                          );
                        },
                        child: const Text('Setujui Kehadiran'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showEditStatusDialog(
    BuildContext context,
    AttendanceModel item,
    LecturerSessionProvider provider,
    String lecturerName,
  ) {
    AttendanceStatus selectedStatus = item.status;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Dispensasi: ${item.studentName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.isQrVerified) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Perhatian: Mahasiswa telah memindai QR secara sah (Hadir). Sistem melarang pengubahan sepihak menjadi Alfa demi integritas data.',
                    style: TextStyle(fontSize: 11, color: AppColors.warning),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const Text(
                'Pilih status pengganti:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AttendanceStatus>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                items: AttendanceStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.displayName),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedStatus = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Alasan Perubahan (Wajib untuk Log Audit):',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Mahasiswa sakit di tengah perkuliahan',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alasan wajib diisi untuk catatan jejak audit'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final success = provider.updateStudentStatus(
                  attendanceId: item.id,
                  newStatus: selectedStatus,
                  reason: reasonController.text.trim(),
                  lecturerName: lecturerName,
                );

                Navigator.pop(ctx);

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('DITOLAK: Kehadiran sah via pemindaian QR tidak dapat diubah menjadi Alfa!'),
                      backgroundColor: AppColors.error,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status kehadiran berhasil diperbarui dengan catatan audit'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
