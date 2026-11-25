enum SessionStatus {
  buka,
  tutup;

  bool get isOpen => this == SessionStatus.buka;
  bool get isClosed => this == SessionStatus.tutup;
}

enum SessionMode {
  luring, // Tatap Muka: Wajib di ruang kelas (Geofencing Lapis 5 aktif, radius <= 30m)
  daring; // Kuliah Virtual / Online: Radius dilewati, tetapi 1 HP dan QR 30 detik tetap ketat

  String get displayName {
    switch (this) {
      case SessionMode.luring:
        return 'Luring (Tatap Muka)';
      case SessionMode.daring:
        return 'Daring (Kuliah Online)';
    }
  }
}

class SessionModel {
  final String id;
  final String classId;
  final String courseName;
  final String className;
  final int meetingNumber; // Pertemuan ke- (1 - 16)
  final DateTime sessionDate; // Tanggal pelaksanaan sesi perkuliahan
  final DateTime openedAt;
  final DateTime expiresAt;
  final SessionMode mode;
  SessionStatus status;
  String currentToken;
  String? previousToken;
  DateTime tokenLastUpdatedAt;
  final int totalStudents;
  int attendedCount;

  SessionModel({
    required this.id,
    required this.classId,
    required this.courseName,
    required this.className,
    required this.meetingNumber,
    DateTime? sessionDate,
    required this.openedAt,
    required this.expiresAt,
    this.mode = SessionMode.luring,
    this.status = SessionStatus.buka,
    required this.currentToken,
    this.previousToken,
    required this.tokenLastUpdatedAt,
    required this.totalStudents,
    this.attendedCount = 0,
  }) : sessionDate = sessionDate ?? DateTime(openedAt.year, openedAt.month, openedAt.day);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Format payload QR: `sessionId|token|meetingNumber|mode`
  String get qrPayload => '$id|$currentToken|$meetingNumber|${mode.name}';
}
