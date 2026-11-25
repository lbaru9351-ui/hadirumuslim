import 'dart:math';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_request_model.dart';
import '../models/academic_calendar_model.dart';

class MockDatabase {
  static final MockDatabase instance = MockDatabase._internal();
  MockDatabase._internal() {
    _initSampleData();
  }

  final List<UserModel> users = [];
  final List<CourseClassModel> classes = [];
  final List<SessionModel> sessions = [];
  final List<AttendanceModel> attendances = [];
  final List<LeaveRequestModel> leaveRequests = [];
  final List<AcademicEventModel> academicEvents = [];

  void _initSampleData() {
    // 1. Data Pengguna (Mahasiswa, Dosen, dan Hirarki 3 Tingkat Admin)
    users.addAll([
      // Mahasiswa (Maksimal 1 HP Terikat)
      UserModel(
        id: 'usr_mhs_1',
        identifier: '210602001',
        name: 'M Hafizh',
        role: UserRole.mahasiswa,
        email: 'mhafizh@almuslim.ac.id',
        boundDeviceIds: [], // Maks 1 HP (otomatis terikat pada login pertama)
        prodi: 'Informatika',
        fakultas: 'Fakultas Ilmu Komputer',
      ),
      UserModel(
        id: 'usr_mhs_2',
        identifier: '210602002',
        name: 'Rian Hidayat',
        role: UserRole.mahasiswa,
        email: 'rian@almuslim.ac.id',
        boundDeviceIds: ['android_samsung_a52_demo'],
        prodi: 'Informatika',
        fakultas: 'Fakultas Ilmu Komputer',
      ),
      UserModel(
        id: 'usr_mhs_3',
        identifier: '210602003',
        name: 'Sarah Nadia',
        role: UserRole.mahasiswa,
        email: 'sarah@almuslim.ac.id',
        boundDeviceIds: [],
        prodi: 'Informatika',
        fakultas: 'Fakultas Ilmu Komputer',
      ),
      UserModel(
        id: 'usr_mhs_4',
        identifier: '220701001',
        name: 'Cut Nurul Aini',
        role: UserRole.mahasiswa,
        email: 'cutnurul@almuslim.ac.id',
        boundDeviceIds: [],
        prodi: 'Sistem Informasi',
        fakultas: 'Fakultas Ilmu Komputer',
      ),

      // Dosen (Dapat login hingga 2 perangkat: Laptop & HP)
      UserModel(
        id: 'usr_dsn_1',
        identifier: '0115088201',
        name: 'Dr. Ir. Teuku Iskandar, M.Kom.',
        role: UserRole.dosen,
        email: 'teuku.iskandar@almuslim.ac.id',
        boundDeviceIds: [],
        prodi: 'Informatika',
        fakultas: 'Fakultas Ilmu Komputer',
      ),
      UserModel(
        id: 'usr_dsn_2',
        identifier: '0123048502',
        name: 'Faisal, S.T., M.T.',
        role: UserRole.dosen,
        email: 'faisal@almuslim.ac.id',
        boundDeviceIds: [],
        prodi: 'Informatika',
        fakultas: 'Fakultas Ilmu Komputer',
      ),
      UserModel(
        id: 'usr_dsn_3',
        identifier: '0101017503',
        name: 'Drs. Ridwan, M.Pd.',
        role: UserRole.dosen,
        email: 'ridwan@almuslim.ac.id',
        boundDeviceIds: [],
        prodi: 'Pendidikan Matematika',
        fakultas: 'FKIP',
      ),

      // HIRARKI ADMINISTRATOR:
      // A. Admin Universitas (Biro Administrasi Akademik / BAA Universitas Almuslim)
      UserModel(
        id: 'usr_adm_univ',
        identifier: 'admin_univ',
        name: 'Drs. H. Marwan Hamid, M.Pd.',
        role: UserRole.admin,
        adminScope: AdminScope.universitas,
        email: 'baa@almuslim.ac.id',
        boundDeviceIds: [],
        fakultas: 'Universitas Almuslim',
        prodi: 'Biro Administrasi Akademik (BAA)',
      ),
      UserModel(
        id: 'usr_adm_default',
        identifier: 'admin', // Alias kompatibilitas
        name: 'Drs. H. Marwan Hamid, M.Pd. (BAA Univ)',
        role: UserRole.admin,
        adminScope: AdminScope.universitas,
        email: 'baa@almuslim.ac.id',
        boundDeviceIds: [],
        fakultas: 'Universitas Almuslim',
        prodi: 'Biro Administrasi Akademik (BAA)',
      ),

      // B. Admin Fakultas (Dekanat & Tata Usaha Fakultas Ilmu Komputer)
      UserModel(
        id: 'usr_adm_fak',
        identifier: 'admin_fak',
        name: 'Zulfan, S.Kom., M.Kom.',
        role: UserRole.admin,
        adminScope: AdminScope.fakultas,
        email: 'dekanat.fik@almuslim.ac.id',
        boundDeviceIds: [],
        fakultas: 'Fakultas Ilmu Komputer',
        prodi: 'Dekanat FIK',
      ),

      // C. Admin Program Studi (Ketua/Sekretaris/Operator Prodi Informatika)
      UserModel(
        id: 'usr_adm_prodi',
        identifier: 'admin_prodi',
        name: 'Ria Rizki, S.Kom., M.T.',
        role: UserRole.admin,
        adminScope: AdminScope.prodi,
        email: 'prodi.if@almuslim.ac.id',
        boundDeviceIds: [],
        fakultas: 'Fakultas Ilmu Komputer',
        prodi: 'Informatika',
      ),
    ]);

    // 2. Data Kelas, Mata Kuliah & KRS Berdasarkan Fakultas & Prodi
    classes.addAll([
      // Kelas Prodi Informatika (FIK)
      CourseClassModel(
        id: 'cls_rpl_a',
        courseCode: 'IF-301',
        courseName: 'Rekayasa Perangkat Lunak',
        className: 'Kelas A',
        sks: 3,
        lecturerId: 'usr_dsn_1',
        lecturerName: 'Dr. Ir. Teuku Iskandar, M.Kom.',
        roomName: 'Lab Komputer 2 (Gedung Timur Lt. 2)',
        roomLatitude: 5.197820,
        roomLongitude: 96.702950,
        roomRadiusMeters: 30.0,
        scheduleDay: 'Senin',
        scheduleTime: '08:00 - 10:30 WIB',
        enrolledStudentIds: ['usr_mhs_1', 'usr_mhs_2', 'usr_mhs_3'], // KRS mahasiswa IF
        prodi: 'Informatika',
        fakultas: 'Fakultas Ilmu Komputer',
      ),
      CourseClassModel(
        id: 'cls_mob_b',
        courseCode: 'IF-304',
        courseName: 'Pemrograman Mobile',
        className: 'Kelas B',
        sks: 3,
        lecturerId: 'usr_dsn_1',
        lecturerName: 'Dr. Ir. Teuku Iskandar, M.Kom.',
        roomName: 'Ruang Kuliah 204 (Gedung Kuliah)',
        roomLatitude: 5.198100,
        roomLongitude: 96.703100,
        roomRadiusMeters: 30.0,
        scheduleDay: 'Rabu',
        scheduleTime: '10:45 - 13:15 WIB',
        enrolledStudentIds: ['usr_mhs_1', 'usr_mhs_2'],
        prodi: 'Informatika',
        fakultas: 'Fakultas Ilmu Komputer',
      ),
      // Kelas Prodi Sistem Informasi (FIK)
      CourseClassModel(
        id: 'cls_si_a',
        courseCode: 'SI-201',
        courseName: 'Analisis & Perancangan Sistem',
        className: 'Kelas A',
        sks: 3,
        lecturerId: 'usr_dsn_2',
        lecturerName: 'Faisal, S.T., M.T.',
        roomName: 'Lab Multimedia (Lt. 1)',
        roomLatitude: 5.197900,
        roomLongitude: 96.702800,
        roomRadiusMeters: 30.0,
        scheduleDay: 'Kamis',
        scheduleTime: '14:00 - 16:30 WIB',
        enrolledStudentIds: ['usr_mhs_4'],
        prodi: 'Sistem Informasi',
        fakultas: 'Fakultas Ilmu Komputer',
      ),
      // Kelas Luar Fakultas (FKIP - Pendidikan Matematika)
      CourseClassModel(
        id: 'cls_fkip_a',
        courseCode: 'PM-102',
        courseName: 'Kalkulus Dasar',
        className: 'Kelas Reguler',
        sks: 3,
        lecturerId: 'usr_dsn_3',
        lecturerName: 'Drs. Ridwan, M.Pd.',
        roomName: 'Ruang FKIP 102 (Gedung FKIP)',
        roomLatitude: 5.198500,
        roomLongitude: 96.703500,
        roomRadiusMeters: 30.0,
        scheduleDay: 'Selasa',
        scheduleTime: '08:00 - 10:30 WIB',
        enrolledStudentIds: [],
        prodi: 'Pendidikan Matematika',
        fakultas: 'FKIP',
      ),
    ]);

    // 3. Kalender Akademik Master Universitas Almuslim
    academicEvents.addAll([
      AcademicEventModel(
        id: 'evt_1',
        title: 'Pengisian KRS Online',
        description: 'Masa pengisian Kartu Rencana Studi (KRS) mahasiswa oleh Admin Prodi & Dosen PA',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 10),
        category: 'krs',
      ),
      AcademicEventModel(
        id: 'evt_2',
        title: 'Awal Perkuliahan Semester Ganjil',
        description: 'Hari pertama perkuliahan efektif pertemuan 1 - 16 seluruh program studi',
        startDate: DateTime(2026, 9, 15),
        endDate: DateTime(2026, 12, 30),
        category: 'kuliah',
      ),
      AcademicEventModel(
        id: 'evt_3',
        title: 'Ujian Tengah Semester (UTS)',
        description: 'Pelaksanaan evaluasi pembelajaran UTS semester ganjil serentak',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 12),
        category: 'uts',
      ),
      AcademicEventModel(
        id: 'evt_4',
        title: 'Ujian Akhir Semester (UAS)',
        description: 'Pelaksanaan ujian akhir semester ganjil (Syarat kehadiran minimal 75%)',
        startDate: DateTime(2027, 1, 5),
        endDate: DateTime(2027, 1, 16),
        category: 'uas',
      ),
    ]);

    // 4. Sesi Contoh (Pertemuan 7 - Luring)
    final now = DateTime.now();
    final sampleToken = _generateRandomToken();
    sessions.add(
      SessionModel(
        id: 'ses_rpl_p7',
        classId: 'cls_rpl_a',
        courseName: 'Rekayasa Perangkat Lunak',
        className: 'Kelas A',
        meetingNumber: 7,
        sessionDate: now,
        openedAt: now.subtract(const Duration(minutes: 2)),
        expiresAt: now.add(const Duration(minutes: 13)),
        mode: SessionMode.luring,
        status: SessionStatus.buka,
        currentToken: sampleToken,
        previousToken: null,
        tokenLastUpdatedAt: now,
        totalStudents: 3,
        attendedCount: 1,
      ),
    );

    // 5. Kehadiran Rian (Hadir via QR - Sah & Terkunci)
    attendances.add(
      AttendanceModel(
        id: 'ses_rpl_p7_usr_mhs_2',
        sessionId: 'ses_rpl_p7',
        classId: 'cls_rpl_a',
        studentId: 'usr_mhs_2',
        studentName: 'Rian Hidayat',
        studentNpm: '210602002',
        status: AttendanceStatus.hadir,
        source: AttendanceSource.qrScan,
        serverTimestamp: now.subtract(const Duration(minutes: 1)),
        distanceMeters: 8.5,
        studentLat: 5.197825,
        studentLon: 96.702952,
        deviceId: 'android_samsung_a52_demo',
        processDurationMs: 1420,
      ),
    );

    // 6. Pengajuan Izin dari Sarah Nadia
    leaveRequests.add(
      LeaveRequestModel(
        id: 'leave_req_001',
        sessionId: 'ses_rpl_p7',
        classId: 'cls_rpl_a',
        meetingNumber: 7,
        studentId: 'usr_mhs_3',
        studentName: 'Sarah Nadia',
        studentNpm: '210602003',
        type: AttendanceStatus.izin,
        reason: 'Mengikuti Lomba Debat Ilmiah Mahasiswa mewakili Universitas Almuslim',
        attachmentName: 'surat_tugas_lomba.pdf',
        submittedAt: now.subtract(const Duration(minutes: 10)),
        status: LeaveStatus.pending,
      ),
    );
  }

  static String _generateRandomToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
