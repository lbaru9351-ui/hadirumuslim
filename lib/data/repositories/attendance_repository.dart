import 'dart:math';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_request_model.dart';
import '../models/academic_calendar_model.dart';
import '../models/validation_result.dart';
import 'mock_database.dart';
import '../../core/utils/haversine.dart';

class AttendanceRepository {
  final MockDatabase _db = MockDatabase.instance;

  // ----------------------------------------------------
  // Autentikasi & Pengikatan Perangkat (Mahasiswa 1 HP, Dosen 2 HP)
  // ----------------------------------------------------
  Future<UserModel?> login({
    required String identifier,
    required String password,
    required String currentDeviceId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (password != '123456' && password != 'admin123') {
      return null;
    }

    final userIndex = _db.users.indexWhere(
      (u) => u.identifier.trim() == identifier.trim(),
    );

    if (userIndex == -1) return null;

    final user = _db.users[userIndex];

    if (!user.isDeviceAllowed(currentDeviceId)) {
      return null;
    }

    if (!user.boundDeviceIds.contains(currentDeviceId) && user.role != UserRole.admin) {
      final updatedDevices = List<String>.from(user.boundDeviceIds)..add(currentDeviceId);
      final updatedUser = user.copyWith(boundDeviceIds: updatedDevices);
      _db.users[userIndex] = updatedUser;
      return updatedUser;
    }

    return user;
  }

  void resetDeviceBinding(String userId) {
    final idx = _db.users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _db.users[idx] = _db.users[idx].copyWith(boundDeviceIds: []);
    }
  }

  // ----------------------------------------------------
  // Admin: Buat Akun Pengguna & Kelola Data Master
  // ----------------------------------------------------
  UserModel createUser({
    required String identifier,
    required String name,
    required UserRole role,
    required String email,
    String prodi = 'Informatika',
    String fakultas = 'Fakultas Ilmu Komputer',
    AdminScope? adminScope,
  }) {
    final newUser = UserModel(
      id: 'usr_${role.name}_${DateTime.now().millisecondsSinceEpoch}',
      identifier: identifier.trim(),
      name: name.trim(),
      role: role,
      email: email.trim(),
      prodi: prodi,
      fakultas: fakultas,
      adminScope: adminScope,
    );
    _db.users.add(newUser);
    return newUser;
  }

  CourseClassModel createCourseClass({
    required String courseCode,
    required String courseName,
    required String className,
    required int sks,
    required String lecturerId,
    required String roomName,
    required double roomLatitude,
    required double roomLongitude,
    double roomRadiusMeters = 30.0,
    required String scheduleDay,
    required String scheduleTime,
    List<String>? initialStudentIds,
    String prodi = 'Informatika',
    String fakultas = 'Fakultas Ilmu Komputer',
  }) {
    final lecturer = _db.users.firstWhere(
      (u) => u.id == lecturerId,
      orElse: () => _db.users.firstWhere((u) => u.role == UserRole.dosen),
    );

    final newClass = CourseClassModel(
      id: 'cls_${courseCode.toLowerCase().replaceAll('-', '_')}_${className.toLowerCase().replaceAll(' ', '_')}',
      courseCode: courseCode,
      courseName: courseName,
      className: className,
      sks: sks,
      lecturerId: lecturer.id,
      lecturerName: lecturer.name,
      roomName: roomName,
      roomLatitude: roomLatitude,
      roomLongitude: roomLongitude,
      roomRadiusMeters: roomRadiusMeters,
      scheduleDay: scheduleDay,
      scheduleTime: scheduleTime,
      enrolledStudentIds: initialStudentIds ?? [],
      prodi: prodi,
      fakultas: fakultas,
    );

    _db.classes.add(newClass);
    return newClass;
  }

  List<CourseClassModel> getClassesByScope({String? fakultas, String? prodi}) {
    return _db.classes.where((c) {
      if (fakultas != null && fakultas != 'Semua' && c.fakultas != fakultas) return false;
      if (prodi != null && prodi != 'Semua' && c.prodi != prodi) return false;
      return true;
    }).toList();
  }

  List<UserModel> getUsersByScope({String? fakultas, String? prodi, UserRole? role}) {
    return _db.users.where((u) {
      if (role != null && u.role != role) return false;
      if (fakultas != null && fakultas != 'Semua' && u.fakultas != fakultas && u.adminScope != AdminScope.universitas) return false;
      if (prodi != null && prodi != 'Semua' && u.prodi != prodi && u.adminScope != AdminScope.universitas && u.adminScope != AdminScope.fakultas) return false;
      return true;
    }).toList();
  }

  void assignLecturerToClass(String classId, String lecturerId) {
    final classIdx = _db.classes.indexWhere((c) => c.id == classId);
    final lecturer = _db.users.firstWhere((u) => u.id == lecturerId);
    if (classIdx != -1) {
      _db.classes[classIdx].lecturerId = lecturer.id;
      _db.classes[classIdx].lecturerName = lecturer.name;
    }
  }

  void updateClassKrs(String classId, List<String> studentIds) {
    final classIdx = _db.classes.indexWhere((c) => c.id == classId);
    if (classIdx != -1) {
      _db.classes[classIdx].enrolledStudentIds.clear();
      _db.classes[classIdx].enrolledStudentIds.addAll(studentIds);
    }
  }

  List<AcademicEventModel> getAcademicCalendar() => _db.academicEvents;

  void addAcademicEvent(AcademicEventModel event) {
    _db.academicEvents.add(event);
  }

  // ----------------------------------------------------
  // Dosen: Sesi Luring / Daring, Tanggal & QR Dinamis
  // ----------------------------------------------------
  Future<SessionModel> openSession({
    required String classId,
    required int meetingNumber,
    DateTime? sessionDate,
    int timeoutMinutes = 15,
    SessionMode mode = SessionMode.luring,
  }) async {
    final courseClass = _db.classes.firstWhere((c) => c.id == classId);
    final now = DateTime.now();
    final token = _generateToken();

    final session = SessionModel(
      id: 'ses_${courseClass.id}_p$meetingNumber',
      classId: courseClass.id,
      courseName: courseClass.courseName,
      className: courseClass.className,
      meetingNumber: meetingNumber,
      sessionDate: sessionDate ?? now,
      openedAt: now,
      expiresAt: now.add(Duration(minutes: timeoutMinutes)),
      mode: mode,
      status: SessionStatus.buka,
      currentToken: token,
      previousToken: null,
      tokenLastUpdatedAt: now,
      totalStudents: courseClass.enrolledStudentIds.length,
      attendedCount: 0,
    );

    _db.sessions.removeWhere((s) => s.id == session.id);
    _db.sessions.add(session);
    return session;
  }

  SessionModel? getActiveSessionForClass(String classId) {
    try {
      return _db.sessions.firstWhere(
        (s) => s.classId == classId && s.status == SessionStatus.buka && !s.isExpired,
      );
    } catch (_) {
      return null;
    }
  }

  List<SessionModel> getSessionsByClassId(String classId) {
    return _db.sessions.where((s) => s.classId == classId).toList();
  }

  List<SessionModel> getAllSessions() {
    return _db.sessions;
  }

  void rotateSessionToken(String sessionId) {
    final session = _db.sessions.firstWhere((s) => s.id == sessionId);
    session.previousToken = session.currentToken;
    session.currentToken = _generateToken();
    session.tokenLastUpdatedAt = DateTime.now();
  }

  /// Menutup sesi dan MENETAPKAN ALFA OTOMATIS tanpa celah kecurangan
  void closeSession(String sessionId) {
    final idx = _db.sessions.indexWhere((s) => s.id == sessionId);
    if (idx == -1) return;

    final session = _db.sessions[idx];
    session.status = SessionStatus.tutup;

    // OTOMASI ALFA AKTUAL & REAL:
    // Semua mahasiswa di KRS kelas yang tidak memindai QR dan tidak ada permohonan izin/sakit sah
    // otomatis dicatat sebagai ALFA oleh sistem.
    final courseClass = _db.classes.firstWhere((c) => c.id == session.classId);

    for (final studentId in courseClass.enrolledStudentIds) {
      final attendanceDocId = '${session.id}_$studentId';
      final alreadyRecorded = _db.attendances.any((a) => a.id == attendanceDocId);

      if (!alreadyRecorded) {
        final student = _db.users.firstWhere((u) => u.id == studentId);
        _db.attendances.add(
          AttendanceModel(
            id: attendanceDocId,
            sessionId: session.id,
            classId: courseClass.id,
            studentId: student.id,
            studentName: student.name,
            studentNpm: student.identifier,
            status: AttendanceStatus.alfa,
            source: AttendanceSource.admin,
            serverTimestamp: DateTime.now(),
            distanceMeters: 0.0,
            studentLat: 0.0,
            studentLon: 0.0,
            deviceId: 'sistem_otomatis',
            processDurationMs: 0,
            editReason: 'Otomatis Alfa: Sesi perkuliahan ditutup tanpa pemindaian QR / izin sah.',
          ),
        );
      }
    }
  }

  // ----------------------------------------------------
  // Anti-Kecurangan: Perlindungan Data, Audit Trail Terantai Hash, & Sanggahan
  // ----------------------------------------------------
  /// Dosen HANYA boleh mengubah status dengan alasan wajib (minimal 5 karakter).
  /// Dosen TIDAK BOLEH menghapus kehadiran mahasiswa.
  /// Status awal pemindaian QR tetap tersimpan permanen.
  bool updateAttendanceStatus({
    required String attendanceId,
    required AttendanceStatus newStatus,
    required String reason,
    required String lecturerName,
  }) {
    if (reason.trim().length < 5) return false;

    final idx = _db.attendances.indexWhere((a) => a.id == attendanceId);
    if (idx == -1) return false;

    final attendance = _db.attendances[idx];

    // ATURAN ANTI-KECURANGAN:
    // Jika mahasiswa sah memindai QR (Hadir), dosen tidak dapat mengubah sepihak menjadi Alfa tanpa verifikasi
    if (attendance.isQrVerified && newStatus == AttendanceStatus.alfa) {
      return false;
    }

    final oldStatus = attendance.status;
    final now = DateTime.now();

    // Rantai Hash Kriptografis (Blockchain-like Hash Chaining)
    final prevHash = attendance.auditLogs.isEmpty
        ? AuditLogEntry.genesisHash
        : attendance.auditLogs.last.entryHash;
    final seq = attendance.auditLogs.length + 1;
    final entryHash = AuditLogEntry.computeHash(
      previousHash: prevHash,
      sequence: seq,
      timestamp: now,
      previousStatus: oldStatus,
      newStatus: newStatus,
      changedBy: lecturerName,
      reason: reason.trim(),
    );

    attendance.auditLogs.add(
      AuditLogEntry(
        sequence: seq,
        timestamp: now,
        previousStatus: oldStatus,
        newStatus: newStatus,
        changedBy: lecturerName,
        reason: reason.trim(),
        previousHash: prevHash,
        entryHash: entryHash,
      ),
    );

    attendance.status = newStatus;
    attendance.editReason = reason.trim();
    attendance.editedAt = now;
    attendance.editedBy = lecturerName;
    return true;
  }

  /// Pengajuan Sanggahan / Keberatan Mahasiswa atas Perubahan Status
  bool submitAttendanceDispute({
    required String attendanceId,
    required String studentId,
    required String reason,
  }) {
    final idx = _db.attendances.indexWhere((a) => a.id == attendanceId && a.studentId == studentId);
    if (idx == -1) return false;

    final attendance = _db.attendances[idx];
    attendance.disputeStatus = DisputeStatus.pending;
    attendance.disputeReason = reason.trim();
    attendance.disputedAt = DateTime.now();
    return true;
  }

  /// Penyelesaian Sanggahan oleh Admin Program Studi / BAA
  bool resolveAttendanceDispute({
    required String attendanceId,
    required bool isApproved,
    required String resolutionNotes,
    required String adminName,
  }) {
    final idx = _db.attendances.indexWhere((a) => a.id == attendanceId);
    if (idx == -1) return false;

    final attendance = _db.attendances[idx];
    final now = DateTime.now();
    final oldStatus = attendance.status;
    final newStatus = isApproved ? attendance.initialStatus : attendance.status;

    // Rantai log audit untuk resolusi sanggahan
    final prevHash = attendance.auditLogs.isEmpty
        ? AuditLogEntry.genesisHash
        : attendance.auditLogs.last.entryHash;
    final seq = attendance.auditLogs.length + 1;
    final reasonLog = isApproved
        ? 'Sanggahan Mahasiswa Diterima: $resolutionNotes'
        : 'Sanggahan Mahasiswa Ditolak: $resolutionNotes';

    final entryHash = AuditLogEntry.computeHash(
      previousHash: prevHash,
      sequence: seq,
      timestamp: now,
      previousStatus: oldStatus,
      newStatus: newStatus,
      changedBy: adminName,
      reason: reasonLog,
    );

    attendance.auditLogs.add(
      AuditLogEntry(
        sequence: seq,
        timestamp: now,
        previousStatus: oldStatus,
        newStatus: newStatus,
        changedBy: adminName,
        reason: reasonLog,
        previousHash: prevHash,
        entryHash: entryHash,
      ),
    );

    attendance.status = newStatus;
    attendance.disputeStatus = isApproved ? DisputeStatus.approved : DisputeStatus.rejected;
    attendance.disputeResolvedBy = adminName;
    attendance.disputeResolutionNotes = resolutionNotes;
    return true;
  }

  /// Daftar Sanggahan Menunggu Peninjauan Admin Prodi
  List<AttendanceModel> getPendingDisputes() {
    return _db.attendances.where((a) => a.disputeStatus == DisputeStatus.pending).toList();
  }

  /// Verifikasi Keaslian Kode Bukti Presensi oleh Prodi / BAA
  Map<String, dynamic> verifyAttendanceProofCode(String proofCode) {
    final cleanCode = proofCode.trim().toUpperCase();
    final match = _db.attendances.where((a) => a.proofCode.toUpperCase() == cleanCode).toList();

    if (match.isEmpty) {
      return {
        'found': false,
        'message': 'Kode bukti presensi tidak ditemukan di server.',
      };
    }

    final attendance = match.first;
    final isChainValid = attendance.verifyAuditChainIntegrity();

    return {
      'found': true,
      'attendance': attendance,
      'proofCode': attendance.proofCode,
      'studentName': attendance.studentName,
      'studentNpm': attendance.studentNpm,
      'status': attendance.status.displayName,
      'initialStatus': attendance.initialStatus.displayName,
      'serverTimestamp': attendance.serverTimestamp,
      'isChainValid': isChainValid,
      'auditLogsCount': attendance.auditLogs.length,
      'isFlagged': attendance.isFlagged,
      'flagReason': attendance.flagReason,
      'message': isChainValid
          ? 'Bukti Sah! Integritas rantai hash terverifikasi penuh.'
          : 'Peringatan: Terdeteksi ketidakcocokan pada rantai hash audit!',
    };
  }

  // ----------------------------------------------------
  // Pengajuan Izin / Sakit Mandiri oleh Mahasiswa
  // ----------------------------------------------------
  Future<LeaveRequestModel> submitLeaveRequest({
    required String sessionId,
    required String classId,
    required int meetingNumber,
    required UserModel student,
    required AttendanceStatus type,
    required String reason,
    String? attachmentName,
  }) async {
    final request = LeaveRequestModel(
      id: 'leave_${sessionId}_${student.id}',
      sessionId: sessionId,
      classId: classId,
      meetingNumber: meetingNumber,
      studentId: student.id,
      studentName: student.name,
      studentNpm: student.identifier,
      type: type,
      reason: reason,
      attachmentName: attachmentName ?? 'surat_keterangan.pdf',
      submittedAt: DateTime.now(),
      status: LeaveStatus.pending,
    );

    _db.leaveRequests.removeWhere((r) => r.id == request.id);
    _db.leaveRequests.add(request);
    return request;
  }

  List<LeaveRequestModel> getLeaveRequestsForSession(String sessionId) {
    return _db.leaveRequests.where((r) => r.sessionId == sessionId).toList();
  }

  List<LeaveRequestModel> getLeaveRequestsForStudent(String studentId) {
    return _db.leaveRequests.where((r) => r.studentId == studentId).toList();
  }

  void reviewLeaveRequest({
    required String requestId,
    required bool isApproved,
    required String lecturerName,
    String? note,
  }) {
    final idx = _db.leaveRequests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return;

    final req = _db.leaveRequests[idx];
    req.status = isApproved ? LeaveStatus.approved : LeaveStatus.rejected;
    req.reviewedBy = lecturerName;
    req.reviewedAt = DateTime.now();
    req.reviewNote = note;

    if (isApproved) {
      final attendanceId = '${req.sessionId}_${req.studentId}';
      final existingIdx = _db.attendances.indexWhere((a) => a.id == attendanceId);

      final attendanceItem = AttendanceModel(
        id: attendanceId,
        sessionId: req.sessionId,
        classId: req.classId,
        studentId: req.studentId,
        studentName: req.studentName,
        studentNpm: req.studentNpm,
        status: req.type,
        source: AttendanceSource.leaveRequest,
        serverTimestamp: DateTime.now(),
        distanceMeters: 0.0,
        studentLat: 0.0,
        studentLon: 0.0,
        deviceId: 'pengajuan_mandiri',
        processDurationMs: 500,
        editReason: 'Disetujui dari permohonan izin/sakit mahasiswa: ${req.reason}',
        editedBy: lecturerName,
        editedAt: DateTime.now(),
      );

      if (existingIdx != -1) {
        _db.attendances[existingIdx] = attendanceItem;
      } else {
        _db.attendances.add(attendanceItem);
      }
    }
  }

  // ----------------------------------------------------
  // Mahasiswa: 7 Lapis Validasi (Luring & Daring Support)
  // ----------------------------------------------------
  Future<ValidationResult> processAttendance({
    required UserModel student,
    required String currentDeviceId,
    required String qrPayload, // Format: sessionId|token|meetingNumber[|mode]
    required double studentLat,
    required double studentLon,
    required DateTime scanStartTime,
  }) async {
    final parts = qrPayload.split('|');
    if (parts.length < 2) {
      return const ValidationResult.failure(
        failedLayer: 4,
        rejectionMessage: 'Format QR Code tidak valid',
      );
    }

    final sessionId = parts[0];
    final scannedToken = parts[1];

    SessionModel? session;
    try {
      session = _db.sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return const ValidationResult.failure(
        failedLayer: 3,
        rejectionMessage: ValidationResult.errLayer3,
      );
    }

    final courseClass = _db.classes.firstWhere(
      (c) => c.id == session!.classId,
      orElse: () => throw Exception('Kelas tidak ditemukan'),
    );

    // LAPIS 1: Akun login dan terdaftar sebagai peserta kelas (KRS Mahasiswa)
    if (!courseClass.enrolledStudentIds.contains(student.id)) {
      return const ValidationResult.failure(
        failedLayer: 1,
        rejectionMessage: ValidationResult.errLayer1,
      );
    }

    // LAPIS 2: ID perangkat sama dengan perangkat yang terikat pada akun (1 HP Mahasiswa)
    if (student.boundDeviceIds.isNotEmpty && !student.boundDeviceIds.contains(currentDeviceId)) {
      return const ValidationResult.failure(
        failedLayer: 2,
        rejectionMessage: ValidationResult.errLayer2,
      );
    }

    // LAPIS 3: Sesi berstatus buka dan belum melewati batas waktu
    final serverTime = DateTime.now();
    if (session.status != SessionStatus.buka || serverTime.isAfter(session.expiresAt)) {
      return const ValidationResult.failure(
        failedLayer: 3,
        rejectionMessage: ValidationResult.errLayer3,
      );
    }

    // LAPIS 4: Token pada QR sama dengan token aktif atau token sebelumnya (toleransi 1 siklus)
    final isTokenValid = scannedToken == session.currentToken ||
        (session.previousToken != null && scannedToken == session.previousToken);
    if (!isTokenValid) {
      return const ValidationResult.failure(
        failedLayer: 4,
        rejectionMessage: ValidationResult.errLayer4,
      );
    }

    // LAPIS 5: Jarak ke koordinat ruang (Haversine)
    double distanceMeters = 0.0;
    if (session.mode == SessionMode.luring) {
      distanceMeters = HaversineUtil.calculateDistanceInMeters(
        lat1: studentLat,
        lon1: studentLon,
        lat2: courseClass.roomLatitude,
        lon2: courseClass.roomLongitude,
      );

      if (distanceMeters > courseClass.roomRadiusMeters) {
        return ValidationResult.failure(
          failedLayer: 5,
          rejectionMessage: ValidationResult.errLayer5,
          distanceMeters: distanceMeters,
          studentLat: studentLat,
          studentLon: studentLon,
          roomLat: courseClass.roomLatitude,
          roomLon: courseClass.roomLongitude,
          roomName: courseClass.roomName,
        );
      }
    }

    // LAPIS 6: Belum ada kehadiran untuk sesi dan mahasiswa yang sama
    final attendanceDocId = '${session.id}_${student.id}';
    final alreadyAttended = _db.attendances.any((a) => a.id == attendanceDocId);
    if (alreadyAttended) {
      return ValidationResult.failure(
        failedLayer: 6,
        rejectionMessage: ValidationResult.errLayer6,
        distanceMeters: distanceMeters,
        studentLat: studentLat,
        studentLon: studentLon,
        roomLat: courseClass.roomLatitude,
        roomLon: courseClass.roomLongitude,
        roomName: courseClass.roomName,
      );
    }

    // DETEKSI ANOMALI POLA MENCURIGAKAN (Prinsip Fairness: Ditandai "Perlu Verifikasi", Tidak Ditolak Sepihak)
    bool isAnomaly = false;
    String? anomalyReason;

    final recentSameScans = _db.attendances.where((a) =>
        a.sessionId == session!.id &&
        serverTime.difference(a.serverTimestamp).inSeconds.abs() <= 5 &&
        (a.studentLat - studentLat).abs() < 0.00001 &&
        (a.studentLon - studentLon).abs() < 0.00001);

    if (recentSameScans.isNotEmpty) {
      isAnomaly = true;
      anomalyReason = 'Pola koordinat identik dalam rentang < 5 detik (ditandai untuk tinjauan dosen/prodi)';
    }

    // LAPIS 7: Cap waktu server dan durasi proses (KF-14)
    final processDurationMs = serverTime.difference(scanStartTime).inMilliseconds;

    final newAttendance = AttendanceModel(
      id: attendanceDocId,
      sessionId: session.id,
      classId: courseClass.id,
      studentId: student.id,
      studentName: student.name,
      studentNpm: student.identifier,
      initialStatus: isAnomaly ? AttendanceStatus.perluVerifikasi : AttendanceStatus.hadir,
      status: isAnomaly ? AttendanceStatus.perluVerifikasi : AttendanceStatus.hadir,
      source: AttendanceSource.qrScan,
      serverTimestamp: serverTime,
      distanceMeters: distanceMeters,
      studentLat: studentLat,
      studentLon: studentLon,
      deviceId: currentDeviceId,
      processDurationMs: processDurationMs > 0 ? processDurationMs : 1250,
      isOnlineMode: session.mode == SessionMode.daring,
      isFlagged: isAnomaly,
      flagReason: anomalyReason,
    );

    _db.attendances.add(newAttendance);
    session.attendedCount += 1;

    return ValidationResult.success(
      distanceMeters: distanceMeters,
      processDurationMs: newAttendance.processDurationMs,
      serverTime: serverTime,
      studentLat: studentLat,
      studentLon: studentLon,
      roomLat: courseClass.roomLatitude,
      roomLon: courseClass.roomLongitude,
      roomName: courseClass.roomName,
    );
  }

  // ----------------------------------------------------
  // Pengambilan Data
  // ----------------------------------------------------
  List<CourseClassModel> getClassesForStudent(String studentId) {
    return _db.classes.where((c) => c.enrolledStudentIds.contains(studentId)).toList();
  }

  List<CourseClassModel> getClassesForLecturer(String lecturerId) {
    return _db.classes.where((c) => c.lecturerId == lecturerId).toList();
  }

  List<CourseClassModel> getAllClasses() => _db.classes;

  List<UserModel> getAllStudents() =>
      _db.users.where((u) => u.role == UserRole.mahasiswa).toList();

  List<UserModel> getAllLecturers() =>
      _db.users.where((u) => u.role == UserRole.dosen).toList();

  List<UserModel> getAllUsers() => _db.users;

  List<AttendanceModel> getAttendanceHistoryForStudent(String studentId) {
    return _db.attendances.where((a) => a.studentId == studentId).toList();
  }

  List<AttendanceModel> getAttendancesForSession(String sessionId) {
    return _db.attendances.where((a) => a.sessionId == sessionId).toList();
  }

  static String _generateToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
