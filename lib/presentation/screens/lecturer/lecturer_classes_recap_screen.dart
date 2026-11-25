import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lecturer_session_provider.dart';
import 'attendance_recap_screen.dart';

/// Halaman Rekapitulasi Presensi Dosen Modern Flat & Minimalis
/// Memungkinkan dosen meninjau ringkasan presensi 16 pertemuan untuk seluruh mata kuliah yang diampu.
class LecturerClassesRecapScreen extends StatelessWidget {
  const LecturerClassesRecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sessionProvider = context.watch<LecturerSessionProvider>();
    final repo = context.read<AttendanceRepository>();
    final lecturer = auth.currentUser;

    if (lecturer == null) {
      return const SizedBox.shrink();
    }

    final classes = sessionProvider.getClasses(lecturer.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rekap Presensi Perkuliahan'),
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: classes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada mata kuliah yang diampu',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceLG,
                vertical: AppDimensions.spaceMD,
              ),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final cls = classes[index];
                final sessions = repo.getSessionsByClassId(cls.id);
                final completedSessions = sessions.where((s) => s.status.isClosed).length;
                final enrolledCount = cls.enrolledStudentIds.length;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                            ),
                            child: Text(
                              '${cls.courseCode} • ${cls.sks} SKS',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            '$enrolledCount Mahasiswa Terdaftar',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cls.courseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Kelas ${cls.className} • ${cls.scheduleDay}, ${cls.scheduleTime}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),

                      // Progress Bar 16 Pertemuan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pertemuan Terlaksana: $completedSessions / 16',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${((completedSessions / 16) * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (completedSessions / 16.0).clamp(0.0, 1.0),
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),

                      const SizedBox(height: AppDimensions.spaceLG),

                      // Tombol Lihat Detail Rekap
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          ),
                        ),
                        icon: const Icon(Icons.table_chart_outlined, size: 16),
                        label: const Text(
                          'Buka Rekap Detail & Izin Mahasiswa',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          // Ambil sesi terbaru atau sesi pertama untuk rekap
                          final targetSession = sessions.isNotEmpty ? sessions.last : null;
                          if (targetSession != null) {
                            sessionProvider.loadSessionAttendances(targetSession.id);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AttendanceRecapScreen(sessionId: targetSession.id),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Belum ada pertemuan yang dibuka untuk kelas ini.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

