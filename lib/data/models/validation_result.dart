class ValidationResult {
  final bool isValid;
  final int? failedLayer; // 1 s/d 7 bila ditolak
  final String? rejectionMessage;
  final double? distanceMeters;
  final int? processDurationMs;
  final DateTime? serverTime;
  final double? studentLat;
  final double? studentLon;
  final double? roomLat;
  final double? roomLon;
  final String? roomName;

  const ValidationResult.success({
    required this.distanceMeters,
    required this.processDurationMs,
    required this.serverTime,
    this.studentLat,
    this.studentLon,
    this.roomLat,
    this.roomLon,
    this.roomName,
  })  : isValid = true,
        failedLayer = null,
        rejectionMessage = null;

  const ValidationResult.failure({
    required this.failedLayer,
    required this.rejectionMessage,
    this.distanceMeters,
    this.processDurationMs,
    this.studentLat,
    this.studentLon,
    this.roomLat,
    this.roomLon,
    this.roomName,
  })  : isValid = false,
        serverTime = null;

  // Pesan baku sesuai Tabel 7 Lapis Validasi pada SKILL.md
  static const String errLayer1 = 'Anda bukan peserta kelas ini';
  static const String errLayer2 = 'Perangkat tidak sesuai dengan akun Anda';
  static const String errLayer3 = 'Sesi sudah ditutup';
  static const String errLayer4 = 'QR Code kedaluwarsa, pindai ulang';
  static const String errLayer5 = 'Anda berada di luar ruang kuliah';
  static const String errLayer6 = 'Anda sudah absen pada sesi ini';
}
