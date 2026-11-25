enum AttendanceStatus {
  hadir,
  izin,
  sakit,
  alfa;

  String get displayName {
    switch (this) {
      case AttendanceStatus.hadir:
        return 'Hadir';
      case AttendanceStatus.izin:
        return 'Izin';
      case AttendanceStatus.sakit:
        return 'Sakit';
      case AttendanceStatus.alfa:
        return 'Alfa';
    }
  }

  static AttendanceStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'izin':
        return AttendanceStatus.izin;
      case 'sakit':
        return AttendanceStatus.sakit;
      case 'alfa':
        return AttendanceStatus.alfa;
      default:
        return AttendanceStatus.hadir;
    }
  }
}

enum AttendanceSource {
  qrScan, // Hasil pemindaian mandiri mahasiswa (7 lapis validasi)
  leaveRequest, // Pengajuan izin/sakit mandiri yang diverifikasi
  admin; // Perubahan resmi oleh Admin

  String get displayName {
    switch (this) {
      case AttendanceSource.qrScan:
        return 'Pindai QR Valid';
      case AttendanceSource.leaveRequest:
        return 'Pengajuan Izin/Sakit';
      case AttendanceSource.admin:
        return 'Koreksi Admin';
    }
  }
}

class AuditLogEntry {
  final DateTime timestamp;
  final AttendanceStatus previousStatus;
  final AttendanceStatus newStatus;
  final String changedBy;
  final String reason;

  AuditLogEntry({
    required this.timestamp,
    required this.previousStatus,
    required this.newStatus,
    required this.changedBy,
    required this.reason,
  });
}

class AttendanceModel {
  final String id; // Format: idSesi_uidMahasiswa
  final String sessionId;
  final String classId;
  final String studentId;
  final String studentName;
  final String studentNpm;
  AttendanceStatus status;
  final AttendanceSource source;
  final DateTime serverTimestamp;
  final double distanceMeters;
  final double studentLat;
  final double studentLon;
  final String deviceId;
  final int processDurationMs; // Pengukuran kinerja KF-14 (target <= 3000 ms)
  final bool isOnlineMode; // True jika sesi daring
  final List<AuditLogEntry> auditLogs; // Jejak audit anti-manipulasi
  String? editReason;
  DateTime? editedAt;
  String? editedBy;

  AttendanceModel({
    required this.id,
    required this.sessionId,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.studentNpm,
    this.status = AttendanceStatus.hadir,
    this.source = AttendanceSource.qrScan,
    required this.serverTimestamp,
    required this.distanceMeters,
    required this.studentLat,
    required this.studentLon,
    required this.deviceId,
    required this.processDurationMs,
    this.isOnlineMode = false,
    List<AuditLogEntry>? auditLogs,
    this.editReason,
    this.editedAt,
    this.editedBy,
  }) : auditLogs = auditLogs ?? [];

  /// Kehadiran hasil pindai QR sah dikunci agar tidak bisa diubah sepihak oleh dosen
  bool get isQrVerified => source == AttendanceSource.qrScan && status == AttendanceStatus.hadir;
}
