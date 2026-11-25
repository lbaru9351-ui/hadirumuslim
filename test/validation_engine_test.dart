import 'package:flutter_test/flutter_test.dart';
import 'package:hadirumuslim/data/repositories/attendance_repository.dart';
import 'package:hadirumuslim/data/repositories/mock_database.dart';
import 'package:hadirumuslim/data/models/user_model.dart';
import 'package:hadirumuslim/data/models/session_model.dart';
import 'package:hadirumuslim/data/models/attendance_model.dart';
import 'package:hadirumuslim/data/models/validation_result.dart';

void main() {
  group('Pengujian Sistem Absensi: Admin, KRS, Kalender, Otomasi Alfa & 7 Lapis Validasi', () {
    late AttendanceRepository repo;
    late UserModel student;
    const String validDeviceId = 'android_test_device_001';

    setUp(() {
      repo = AttendanceRepository();
      student = UserModel(
        id: 'usr_mhs_1',
        identifier: '210602001',
        name: 'M Hafizh',
        role: UserRole.mahasiswa,
        email: 'mhafizh@almuslim.ac.id',
        boundDeviceIds: [validDeviceId],
      );
    });

    test('Lapis 1: Ditolak bila akun bukan peserta kelas KRS', () async {
      final unEnrolledStudent = UserModel(
        id: 'usr_stranger_99',
        identifier: '210602099',
        name: 'Mahasiswa Luar',
        role: UserRole.mahasiswa,
        email: 'stranger@almuslim.ac.id',
      );

      final session = MockDatabase.instance.sessions.firstWhere((s) => s.id == 'ses_rpl_p7');
      final result = await repo.processAttendance(
        student: unEnrolledStudent,
        currentDeviceId: validDeviceId,
        qrPayload: '${session.id}|${session.currentToken}|7',
        studentLat: 5.197820,
        studentLon: 96.702950,
        scanStartTime: DateTime.now(),
      );

      expect(result.isValid, isFalse);
      expect(result.failedLayer, 1);
      expect(result.rejectionMessage, ValidationResult.errLayer1);
    });

    test('Lapis 2: Ditolak bila ID perangkat mahasiswa berbeda (1 HP 1 Akun)', () async {
      final session = MockDatabase.instance.sessions.firstWhere((s) => s.id == 'ses_rpl_p7');
      final result = await repo.processAttendance(
        student: student,
        currentDeviceId: 'android_other_phone_999',
        qrPayload: '${session.id}|${session.currentToken}|7',
        studentLat: 5.197820,
        studentLon: 96.702950,
        scanStartTime: DateTime.now(),
      );

      expect(result.isValid, isFalse);
      expect(result.failedLayer, 2);
      expect(result.rejectionMessage, ValidationResult.errLayer2);
    });

    test('Lapis 4: Ditolak bila token QR kedaluwarsa atau palsu (> 30 detik)', () async {
      final session = MockDatabase.instance.sessions.firstWhere((s) => s.id == 'ses_rpl_p7');
      final result = await repo.processAttendance(
        student: student,
        currentDeviceId: validDeviceId,
        qrPayload: '${session.id}|INVALIDTOKEN123|7',
        studentLat: 5.197820,
        studentLon: 96.702950,
        scanStartTime: DateTime.now(),
      );

      expect(result.isValid, isFalse);
      expect(result.failedLayer, 4);
      expect(result.rejectionMessage, ValidationResult.errLayer4);
    });

    test('Lapis 5 (Mode Luring): Ditolak bila jarak melebihi radius 30 meter', () async {
      final session = MockDatabase.instance.sessions.firstWhere((s) => s.id == 'ses_rpl_p7');
      expect(session.mode, SessionMode.luring);

      final result = await repo.processAttendance(
        student: student,
        currentDeviceId: validDeviceId,
        qrPayload: '${session.id}|${session.currentToken}|7',
        studentLat: 5.205000,
        studentLon: 96.710000,
        scanStartTime: DateTime.now(),
      );

      expect(result.isValid, isFalse);
      expect(result.failedLayer, 5);
      expect(result.rejectionMessage, ValidationResult.errLayer5);
    });

    test('Mode Daring: Radius GPS dilewati otomatis saat kuliah online virtual', () async {
      final daringSession = await repo.openSession(
        classId: 'cls_rpl_a',
        meetingNumber: 8,
        mode: SessionMode.daring,
      );

      final result = await repo.processAttendance(
        student: student,
        currentDeviceId: validDeviceId,
        qrPayload: '${daringSession.id}|${daringSession.currentToken}|8',
        studentLat: 5.250000,
        studentLon: 96.800000,
        scanStartTime: DateTime.now().subtract(const Duration(milliseconds: 1100)),
      );

      expect(result.isValid, isTrue);
    });

    test('Kebijakan Multi-Perangkat: Dosen diizinkan 2 perangkat, Mahasiswa maks 1', () async {
      final lecturer = MockDatabase.instance.users.firstWhere((u) => u.role == UserRole.dosen);
      expect(lecturer.maxAllowedDevices, 2);
      expect(student.maxAllowedDevices, 1);

      final d1 = await repo.login(identifier: lecturer.identifier, password: '123456', currentDeviceId: 'laptop_hp_001');
      expect(d1, isNotNull);

      final d2 = await repo.login(identifier: lecturer.identifier, password: '123456', currentDeviceId: 'hp_samsung_002');
      expect(d2, isNotNull);
    });

    test('Anti-Kecurangan: Dosen DILARANG mengubah kehadiran sah (Hadir) menjadi Alfa', () {
      final rianPresence = MockDatabase.instance.attendances.firstWhere((a) => a.studentNpm == '210602002');
      expect(rianPresence.isQrVerified, isTrue);

      final success = repo.updateAttendanceStatus(
        attendanceId: rianPresence.id,
        newStatus: AttendanceStatus.alfa,
        reason: 'Ubah semena-mena',
        lecturerName: 'Dr. Ir. Teuku Iskandar',
      );

      expect(success, isFalse);
    });

    test('Otomasi Alfa Aktual: Mahasiswa yang tidak hadir saat sesi ditutup otomatis dicatat Alfa', () async {
      final testSession = await repo.openSession(
        classId: 'cls_mob_b',
        meetingNumber: 3,
        sessionDate: DateTime.now(),
      );

      // Tutup sesi perkuliahan
      repo.closeSession(testSession.id);

      // Semua mahasiswa peserta KRS yang belum scan otomatis tercatat Alfa
      final autoAlfa = MockDatabase.instance.attendances.where((a) => a.sessionId == testSession.id).toList();
      expect(autoAlfa.isNotEmpty, isTrue);
      expect(autoAlfa.every((a) => a.status == AttendanceStatus.alfa), isTrue);
    });

    test('Admin: Buat Akun Pengguna, Tugaskan Dosen & Kelola KRS', () {
      // 1. Buat akun mahasiswa baru
      final newMhs = repo.createUser(
        identifier: '210602010',
        name: 'Ahmad Dani',
        role: UserRole.mahasiswa,
        email: 'ahmaddani@almuslim.ac.id',
      );
      expect(newMhs.id, isNotEmpty);

      // 2. Buat akun dosen baru
      final newDsn = repo.createUser(
        identifier: '0115088299',
        name: 'Dr. Mukhlis, M.T.',
        role: UserRole.dosen,
        email: 'mukhlis@almuslim.ac.id',
      );
      expect(newDsn.role, UserRole.dosen);

      // 3. Tugaskan dosen ke kelas
      repo.assignLecturerToClass('cls_rpl_a', newDsn.id);
      final rplClass = repo.getAllClasses().firstWhere((c) => c.id == 'cls_rpl_a');
      expect(rplClass.lecturerId, newDsn.id);
      expect(rplClass.lecturerName, newDsn.name);

      // 4. Update KRS
      repo.updateClassKrs('cls_rpl_a', [newMhs.id]);
      expect(rplClass.enrolledStudentIds, contains(newMhs.id));
    });

    test('Hirarki Admin: Pembeda Wewenang Admin Universitas, Admin Fakultas & Admin Prodi', () {
      final allUsers = repo.getAllUsers();

      // 1. Verifikasi Admin Universitas (BAA)
      final adminUniv = allUsers.firstWhere((u) => u.identifier == 'admin_univ');
      expect(adminUniv.role, UserRole.admin);
      expect(adminUniv.adminScope, AdminScope.universitas);
      expect(adminUniv.isAdminUniversitas, isTrue);

      // 2. Verifikasi Admin Fakultas (FIK)
      final adminFak = allUsers.firstWhere((u) => u.identifier == 'admin_fak');
      expect(adminFak.role, UserRole.admin);
      expect(adminFak.adminScope, AdminScope.fakultas);
      expect(adminFak.isAdminFakultas, isTrue);
      expect(adminFak.fakultas, 'Fakultas Ilmu Komputer');

      // 3. Verifikasi Admin Program Studi (Informatika)
      final adminProdi = allUsers.firstWhere((u) => u.identifier == 'admin_prodi');
      expect(adminProdi.role, UserRole.admin);
      expect(adminProdi.adminScope, AdminScope.prodi);
      expect(adminProdi.isAdminProdi, isTrue);
      expect(adminProdi.prodi, 'Informatika');

      // 4. Pengujian Filter Scope Mata Kuliah
      final ifClasses = repo.getClassesByScope(prodi: 'Informatika');
      expect(ifClasses.every((c) => c.prodi == 'Informatika'), isTrue);

      final fikClasses = repo.getClassesByScope(fakultas: 'Fakultas Ilmu Komputer');
      expect(fikClasses.every((c) => c.fakultas == 'Fakultas Ilmu Komputer'), isTrue);
      expect(fikClasses.length, greaterThanOrEqualTo(ifClasses.length));
    });
  });
}
