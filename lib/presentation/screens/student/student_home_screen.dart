import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_attendance_provider.dart';
import '../../widgets/status_badge.dart';
import 'qr_scanner_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToScan;
  final VoidCallback onNavigateToHistory;

  const StudentHomeScreen({
    super.key,
    required this.onNavigateToScan,
    required this.onNavigateToHistory,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final student = auth.currentUser;
    final studentProvider = context.watch<StudentAttendanceProvider>();
    final repo = context.read<AttendanceRepository>();

    if (student == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final classes = studentProvider.getStudentClasses(student.id);
    final history = studentProvider.getStudentHistory(student.id);

    // Hitung statistik kehadiran
    final attendedCount = history.where((h) => h.status == AttendanceStatus.hadir).length;
    final izinCount = history.where((h) => h.status == AttendanceStatus.izin).length;
    final sakitCount = history.where((h) => h.status == AttendanceStatus.sakit).length;
    final alfaCount = history.where((h) => h.status == AttendanceStatus.alfa).length;

    const totalSessions = 16;
    final double attendancePercentage = history.isNotEmpty
        ? ((attendedCount / history.length) * 100).clamp(0, 100)
        : 100.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceLG,
            vertical: AppDimensions.spaceMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Minimalis & Profil Mahasiswa
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                          ),
                          child: Text(
                            'UNIVERSITAS ALMUSLIM',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  letterSpacing: 0.8,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          student.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NPM ${student.identifier} • ${student.prodi}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // 2. Kartu Ringkasan Kehadiran Modern Flat (Banyak Ruang Kosong & Mudah Dipindai)
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceLG),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.insights_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Presensi Semester Ini',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'Ganjil 2026/2027',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.spaceMD),

                    // Angka Persentase Besar & Jelas
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${attendancePercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceSM),
                        Expanded(
                          child: Text(
                            '$attendedCount hadir dari ${history.isEmpty ? totalSessions : history.length} pertemuan terlaksana',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.spaceMD),

                    // Progress Bar Minimalis
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: attendancePercentage / 100.0,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 6,
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceLG),

                    // 4 Kartu Mini Statistik Kehadiran (Mudah Dipindai Sekilas)
                    Row(
                      children: [
                        _buildStatPill(
                          label: 'Hadir',
                          count: attendedCount,
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                          bgColor: const Color(0xFFECFDF5),
                        ),
                        const SizedBox(width: 8),
                        _buildStatPill(
                          label: 'Izin',
                          count: izinCount,
                          icon: Icons.assignment_outlined,
                          color: AppColors.warning,
                          bgColor: const Color(0xFFFFFBEB),
                        ),
                        const SizedBox(width: 8),
                        _buildStatPill(
                          label: 'Sakit',
                          count: sakitCount,
                          icon: Icons.medical_services_outlined,
                          color: const Color(0xFF0284C7),
                          bgColor: const Color(0xFFF0F9FF),
                        ),
                        const SizedBox(width: 8),
                        _buildStatPill(
                          label: 'Alfa',
                          count: alfaCount,
                          icon: Icons.remove_circle_outline_rounded,
                          color: AppColors.error,
                          bgColor: const Color(0xFFFEF2F2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // 3. Tombol Cepat Pindai Presensi (Desain Flat Minimalis)
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QrScannerScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceLG,
                    vertical: AppDimensions.spaceMD,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Pindai QR Presensi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Arahkan kamera ke layar proyeksi / dosen',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // 4. Jadwal Mata Kuliah Mahasiswa
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Kuliah',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Berdasarkan Kartu Rencana Studi (KRS)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: onNavigateToHistory,
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('Riwayat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              if (classes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.school_outlined, size: 40, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Belum Ada Mata Kuliah Terdaftar di KRS',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hubungi Admin Akademik untuk pengaturan KRS semester ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...classes.map((cls) => _buildModernClassCard(context, cls, repo)),

              const SizedBox(height: AppDimensions.spaceLG),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Mini Statistik Kehadiran
  Widget _buildStatPill({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kartu Jadwal Kelas Desain Flat Modern
  Widget _buildModernClassCard(
    BuildContext context,
    CourseClassModel cls,
    AttendanceRepository repo,
  ) {
    final activeSession = repo.getActiveSessionForClass(cls.id);
    final isOpen = activeSession != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: isOpen ? AppColors.primary : AppColors.border,
          width: isOpen ? 1.6 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Kode Kelas & Badge Status Sesi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${cls.courseCode} • ${cls.sks} SKS',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                StatusBadge(
                  label: isOpen ? 'Sesi Dibuka' : 'Belum Dibuka',
                  type: isOpen ? BadgeType.success : BadgeType.warning,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceSM),

            // Nama Mata Kuliah & Dosen Pengampu
            Text(
              cls.courseName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${cls.className} • Dosen: ${cls.lecturerName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),

            const SizedBox(height: AppDimensions.spaceMD),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppDimensions.spaceMD),

            // Info Ruang & Waktu dengan Ikon Jelas
            Row(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cls.roomName,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  cls.scheduleTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceMD),

            // Tombol Aksi Flat
            Row(
              children: [
                if (isOpen) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                      label: const Text('Pindai QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QrScannerScreen(preferredClassId: cls.id),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSM),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      ),
                    ),
                    icon: const Icon(Icons.note_alt_outlined, size: 16),
                    label: const Text('Izin / Sakit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      final auth = context.read<AuthProvider>();
                      final studentProvider = context.read<StudentAttendanceProvider>();
                      if (auth.currentUser != null) {
                        _showLeaveRequestDialog(context, cls, auth.currentUser!, studentProvider);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveRequestDialog(
    BuildContext context,
    CourseClassModel cls,
    UserModel student,
    StudentAttendanceProvider provider,
  ) {
    AttendanceStatus selectedType = AttendanceStatus.sakit;
    int meetingNumber = 7;
    final reasonController = TextEditingController();
    final fileController = TextEditingController(text: 'surat_keterangan_dokter.pdf');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          ),
          title: Text(
            'Pengajuan Izin/Sakit\n${cls.courseName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jenis Keterangan:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                SegmentedButton<AttendanceStatus>(
                  segments: const [
                    ButtonSegment(value: AttendanceStatus.sakit, label: Text('Sakit')),
                    ButtonSegment(value: AttendanceStatus.izin, label: Text('Izin')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (newVal) {
                    setDialogState(() {
                      selectedType = newVal.first;
                      fileController.text = selectedType == AttendanceStatus.sakit
                          ? 'surat_keterangan_dokter.pdf'
                          : 'surat_izin_kegiatan.pdf';
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text('Pertemuan Kuliah:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: meetingNumber,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: List.generate(16, (i) => i + 1)
                      .map((pNum) => DropdownMenuItem(value: pNum, child: Text('Pertemuan ke-$pNum')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => meetingNumber = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Alasan Lengkap (Wajib):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Sakit demam tinggi, rawat jalan di klinik',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Bukti Lampiran Dokumen:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: fileController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.attach_file, size: 18),
                    hintText: 'Nama file dokumen bukti',
                  ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
              ),
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alasan pengajuan wajib diisi secara jelas'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                await provider.submitLeaveRequest(
                  sessionId: 'ses_${cls.id}_p$meetingNumber',
                  classId: cls.id,
                  meetingNumber: meetingNumber,
                  student: student,
                  type: selectedType,
                  reason: reasonController.text.trim(),
                  attachmentName: fileController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengajuan izin/sakit berhasil dikirim ke Dosen untuk diverifikasi'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              child: const Text('Kirim Pengajuan'),
            ),
          ],
        ),
      ),
    );
  }
}
