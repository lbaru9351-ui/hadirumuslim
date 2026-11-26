import 'dart:convert';
import 'package:crypto/crypto.dart';

enum AttendanceStatus {
  hadir,
  izin,
  sakit,
  alfa,
  perluVerifikasi; // Ditandai jika ada anomali untuk ditinjau (prinsip fairness)

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
      case AttendanceStatus.perluVerifikasi:
        return 'Perlu Verifikasi';
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
      case 'perluverifikasi':
      case 'perlu_verifikasi':
        return AttendanceStatus.perluVerifikasi;
      default:
        return AttendanceStatus.hadir;
    }
  }
}

enum AttendanceSource {
  qrScan, // Hasil pemindaian mandiri mahasiswa (7 lapis validasi)
  leaveRequest, // Pengajuan izin/sakit mandiri yang diverifikasi
  admin; // Koreksi resmi oleh Admin Prodi/BAA

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

enum DisputeStatus {
  none,
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case DisputeStatus.none:
        return 'Tidak Ada Sanggahan';
      case DisputeStatus.pending:
        return 'Sanggahan Menunggu Review';
      case DisputeStatus.approved:
        return 'Sanggahan Diterima';
      case DisputeStatus.rejected:
        return 'Sanggahan Ditolak';
    }
  }
}

/// Entri Jejak Audit Terantai Hash (Append-Only Hash-Chained Audit Log)
/// Setiap entri memiliki hash kriptografis yang merantai ke entri sebelumnya (blockchain-like).
class AuditLogEntry {
  final int sequence;
  final DateTime timestamp;
  final AttendanceStatus previousStatus;
  final AttendanceStatus newStatus;
  final String changedBy;
  final String reason;
  final String previousHash;
  final String entryHash;

  AuditLogEntry({
    required this.sequence,
    required this.timestamp,
    required this.previousStatus,
    required this.newStatus,
    required this.changedBy,
    required this.reason,
    required this.previousHash,
    required this.entryHash,
  });

  static const String genesisHash = '0000000000000000000000000000000000000000000000000000000000000000';

  static String computeHash({
    required String previousHash,
    required int sequence,
    required DateTime timestamp,
    required AttendanceStatus previousStatus,
    required AttendanceStatus newStatus,
    required String changedBy,
    required String reason,
  }) {
    final payload = '$previousHash|$sequence|${timestamp.toIso8601String()}|'
        '${previousStatus.name}|${newStatus.name}|$changedBy|$reason';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  bool verifyHash() {
    final recomputed = computeHash(
      previousHash: previousHash,
      sequence: sequence,
      timestamp: timestamp,
      previousStatus: previousStatus,
      newStatus: newStatus,
      changedBy: changedBy,
      reason: reason,
    );
    return recomputed == entryHash;
  }
}

class AttendanceModel {
  final String id; // Format: idSesi_uidMahasiswa
  final String sessionId;
  final String classId;
  final String studentId;
  final String studentName;
  final String studentNpm;
  
  // Status awal pemindaian QR tersimpan permanen (tidak pernah boleh dihapus/hilang)
  final AttendanceStatus initialStatus;
  
  // Status operasional saat ini (bisa disesuaikan dosen/admin dengan alasan wajib)
  AttendanceStatus status;
  final AttendanceSource source;
  final DateTime serverTimestamp;
  final double distanceMeters;
  final double studentLat;
  final double studentLon;
  final String deviceId;
  final int processDurationMs; // Pengukuran kinerja KF-14 (target <= 3000 ms)
  final bool isOnlineMode; // True jika sesi daring
  
  // Kode Bukti Digital Kriptografis (Digital Receipt)
  final String proofCode; // Format ringkas: ALM-XXXX-XXXX-XXXX untuk dicatat mahasiswa & diverifikasi prodi
  final String receiptHash; // Hash SHA-256 lengkap untuk integritas bukti
  
  // Deteksi Anomali (Fairness Principle: kasus meragukan ditandai "Perlu Verifikasi")
  final bool isFlagged;
  final String? flagReason;
  
  // Jejak Audit Terantai Hash (Append-Only)
  final List<AuditLogEntry> auditLogs;
  String? editReason;
  DateTime? editedAt;
  String? editedBy;

  // Mekanisme Sanggahan / Keberatan Mahasiswa (Dispute Resolution)
  DisputeStatus disputeStatus;
  String? disputeReason;
  DateTime? disputedAt;
  String? disputeResolvedBy;
  String? disputeResolutionNotes;

  AttendanceModel({
    required this.id,
    required this.sessionId,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.studentNpm,
    AttendanceStatus? initialStatus,
    AttendanceStatus? status,
    this.source = AttendanceSource.qrScan,
    required this.serverTimestamp,
    required this.distanceMeters,
    required this.studentLat,
    required this.studentLon,
    required this.deviceId,
    required this.processDurationMs,
    this.isOnlineMode = false,
    String? proofCode,
    String? receiptHash,
    this.isFlagged = false,
    this.flagReason,
    List<AuditLogEntry>? auditLogs,
    this.editReason,
    this.editedAt,
    this.editedBy,
    this.disputeStatus = DisputeStatus.none,
    this.disputeReason,
    this.disputedAt,
    this.disputeResolvedBy,
    this.disputeResolutionNotes,
  })  : initialStatus = initialStatus ?? (status ?? AttendanceStatus.hadir),
        status = status ?? (initialStatus ?? AttendanceStatus.hadir),
        proofCode = proofCode ?? generateProofCode(sessionId, studentNpm, serverTimestamp),
        receiptHash = receiptHash ?? generateReceiptHash(sessionId, studentNpm, serverTimestamp),
        auditLogs = auditLogs ?? [];

  /// Generator Kode Bukti Digital Sah (Format Pendek Mudah Disalin)
  static String generateProofCode(String sessionId, String npm, DateTime timestamp) {
    final raw = '$sessionId:$npm:${timestamp.millisecondsSinceEpoch}:ALMUSLIM_SALT_2026';
    final digest = sha256.convert(utf8.encode(raw)).toString().toUpperCase();
    return 'ALM-${digest.substring(0, 4)}-${digest.substring(4, 8)}-${digest.substring(8, 12)}';
  }

  /// Generator Hash Bukti Digital Lengkap SHA-256
  static String generateReceiptHash(String sessionId, String npm, DateTime timestamp) {
    final raw = '$sessionId|$npm|${timestamp.toIso8601String()}|UNIVERSITAS_ALMUSLIM_VERITAS';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Verifikasi Mandiri Rantai Hash Audit Log
  /// Mengembalikan true jika seluruh riwayat perubahan terbukti otentik tanpa manipulasi out-of-band di database
  bool verifyAuditChainIntegrity() {
    if (auditLogs.isEmpty) return true;

    String expectedPrevHash = AuditLogEntry.genesisHash;
    for (int i = 0; i < auditLogs.length; i++) {
      final entry = auditLogs[i];
      if (entry.sequence != i + 1) return false;
      if (entry.previousHash != expectedPrevHash) return false;
      if (!entry.verifyHash()) return false;
      expectedPrevHash = entry.entryHash;
    }
    return true;
  }

  /// Status apakah kehadiran pernah diubah oleh dosen dari status pemindaian awal
  bool get isModifiedByLecturer => status != initialStatus || auditLogs.isNotEmpty;

  /// Apakah mahasiswa berhak mengajukan sanggahan / keberatan
  bool get canSubmitDispute =>
      isModifiedByLecturer && (disputeStatus == DisputeStatus.none || disputeStatus == DisputeStatus.rejected);

  /// Indikator apakah kehadiran terverifikasi sah melalui pemindaian QR
  bool get isQrVerified => source == AttendanceSource.qrScan && initialStatus == AttendanceStatus.hadir;
}
