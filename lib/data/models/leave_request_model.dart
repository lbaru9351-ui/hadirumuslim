import 'attendance_model.dart';

enum LeaveStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Menunggu Verifikasi';
      case LeaveStatus.approved:
        return 'Disetujui Dosen';
      case LeaveStatus.rejected:
        return 'Ditolak';
    }
  }
}

class LeaveRequestModel {
  final String id;
  final String sessionId;
  final String classId;
  final int meetingNumber;
  final String studentId;
  final String studentName;
  final String studentNpm;
  final AttendanceStatus type; // Izin atau Sakit
  final String reason;
  final String? attachmentName;
  final DateTime submittedAt;
  LeaveStatus status;
  String? reviewedBy;
  DateTime? reviewedAt;
  String? reviewNote;

  LeaveRequestModel({
    required this.id,
    required this.sessionId,
    required this.classId,
    required this.meetingNumber,
    required this.studentId,
    required this.studentName,
    required this.studentNpm,
    required this.type,
    required this.reason,
    this.attachmentName,
    required this.submittedAt,
    this.status = LeaveStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
  });
}

