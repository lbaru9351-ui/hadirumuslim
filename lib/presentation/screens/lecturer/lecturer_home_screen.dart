import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/session_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lecturer_session_provider.dart';
import '../../widgets/custom_button.dart';
import 'dynamic_qr_session_screen.dart';
import 'attendance_recap_screen.dart';

class LecturerHomeScreen extends StatelessWidget {
  const LecturerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sessionProvider = context.watch<LecturerSessionProvider>();
    final lecturer = auth.currentUser;

    if (lecturer == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final classes = sessionProvider.getClasses(lecturer.id);
    final activeSession = sessionProvider.activeSession;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Beranda Dosen'),
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Sapaan Dosen
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                    child: const Icon(Icons.school, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lecturer.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIDN: ${lecturer.identifier} • Dosen Prodi ${lecturer.prodi}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceLG),

            // Sesi Aktif Card (bila ada sesi yang sedang dibuka)
            if (activeSession != null && activeSession.status.isOpen) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SESI PERKULIAHAN BERJALAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(Icons.wifi_tethering, color: AppColors.success, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${activeSession.courseName} - Pertemuan ke-${activeSession.meetingNumber}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Hadir: ${activeSession.attendedCount} / ${activeSession.totalStudents} Mahasiswa',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Buka Tampilan Layar QR Dinamis'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DynamicQrSessionScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
            ],

            // Daftar Kelas yang Diampu
            Text(
              'Kelas yang Diampu Semester Ini',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppDimensions.spaceSM),

            if (classes.isEmpty)
              const Center(child: Text('Tidak ada mata kuliah yang diampu.'))
            else
              ...classes.map((cls) => _buildClassCard(context, cls, sessionProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context,
    CourseClassModel cls,
    LecturerSessionProvider sessionProvider,
  ) {
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
                '${cls.courseCode} • ${cls.sks} SKS',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              Text(
                '${cls.enrolledStudentIds.length} Peserta',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            cls.courseName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          Text(
            '${cls.className} • ${cls.scheduleDay}, ${cls.scheduleTime}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${cls.roomName} (Radius: ${cls.roomRadiusMeters.toInt()}m)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Buka Sesi QR',
                  icon: Icons.qr_code,
                  onPressed: () {
                    _showOpenSessionDialog(context, cls, sessionProvider);
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSM),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                icon: const Icon(Icons.table_chart_outlined, color: AppColors.primary),
                tooltip: 'Rekap Kehadiran',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AttendanceRecapScreen(
                        sessionId: 'ses_${cls.id}_p7',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOpenSessionDialog(
    BuildContext context,
    CourseClassModel cls,
    LecturerSessionProvider sessionProvider,
  ) {
    int selectedMeeting = 7;
    int timeoutMinutes = AppDimensions.sessionTimeoutMinutes;
    SessionMode selectedMode = SessionMode.luring;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Buka Sesi: ${cls.courseName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode Perkuliahan:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                SegmentedButton<SessionMode>(
                  segments: const [
                    ButtonSegment(
                      value: SessionMode.luring,
                      label: Text('Luring (Kelas)'),
                      icon: Icon(Icons.location_on, size: 16),
                    ),
                    ButtonSegment(
                      value: SessionMode.daring,
                      label: Text('Daring (Meet)'),
                      icon: Icon(Icons.laptop_chromebook, size: 16),
                    ),
                  ],
                  selected: {selectedMode},
                  onSelectionChanged: (newSelection) {
                    setDialogState(() {
                      selectedMode = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selectedMode == SessionMode.luring ? AppColors.infoBg : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    selectedMode == SessionMode.luring
                        ? 'Mode Luring: Validasi radius GPS (<= 30 meter) ruang kelas wajib dipenuhi.'
                        : 'Mode Daring: Validasi lokasi fisik kelas dilewati. Mahasiswa memindai QR dinamis yang ditayangkan dosen di screen share Google Meet / Zoom.',
                    style: TextStyle(
                      fontSize: 11,
                      color: selectedMode == SessionMode.luring ? AppColors.info : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tanggal Perkuliahan:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2026, 1, 1),
                      lastDate: DateTime(2027, 12, 31),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd MMM yyyy').format(selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        const Text('Ubah Tanggal', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pilih Pertemuan Kuliah (1 - 16):',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: selectedMeeting,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: List.generate(16, (i) => i + 1)
                      .map((mNumber) => DropdownMenuItem(
                            value: mNumber,
                            child: Text('Pertemuan ke-$mNumber'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedMeeting = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Batas Waktu Sesi (Menit):',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: timeoutMinutes,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: const [10, 15, 20, 30]
                      .map((mins) => DropdownMenuItem(
                            value: mins,
                            child: Text('$mins Menit (Default 15 Menit)'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => timeoutMinutes = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await sessionProvider.startSession(
                  classId: cls.id,
                  meetingNumber: selectedMeeting,
                  sessionDate: selectedDate,
                  timeoutMinutes: timeoutMinutes,
                  mode: selectedMode,
                );
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DynamicQrSessionScreen(),
                    ),
                  );
                }
              },
              child: const Text('Buka Sesi'),
            ),
          ],
        ),
      ),
    );
  }
}
