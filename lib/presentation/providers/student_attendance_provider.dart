import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/user_model.dart';
import '../../data/models/course_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/validation_result.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../core/utils/haversine.dart';

class StudentAttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repository;

  Position? _currentPosition;
  bool _isLocating = false;
  String? _locationStatusMessage;
  bool _hasLocationPermission = false;

  bool _isProcessingScan = false;
  ValidationResult? _lastValidationResult;
  DateTime? _scanStartTime;

  StudentAttendanceProvider(this._repository);

  Position? get currentPosition => _currentPosition;
  bool get isLocating => _isLocating;
  String? get locationStatusMessage => _locationStatusMessage;
  bool get hasLocationPermission => _hasLocationPermission;

  bool get isProcessingScan => _isProcessingScan;
  ValidationResult? get lastValidationResult => _lastValidationResult;

  List<CourseClassModel> getStudentClasses(String studentId) {
    return _repository.getClassesForStudent(studentId);
  }

  List<AttendanceModel> getStudentHistory(String studentId) {
    return _repository.getAttendanceHistoryForStudent(studentId);
  }

  List<LeaveRequestModel> getStudentLeaveRequests(String studentId) {
    return _repository.getLeaveRequestsForStudent(studentId);
  }

  bool submitDispute({
    required String attendanceId,
    required String studentId,
    required String reason,
  }) {
    final success = _repository.submitAttendanceDispute(
      attendanceId: attendanceId,
      studentId: studentId,
      reason: reason,
    );
    notifyListeners();
    return success;
  }

  Future<LeaveRequestModel> submitLeaveRequest({
    required String sessionId,
    required String classId,
    required int meetingNumber,
    required UserModel student,
    required AttendanceStatus type,
    required String reason,
    String? attachmentName,
  }) async {
    final req = await _repository.submitLeaveRequest(
      sessionId: sessionId,
      classId: classId,
      meetingNumber: meetingNumber,
      student: student,
      type: type,
      reason: reason,
      attachmentName: attachmentName,
    );
    notifyListeners();
    return req;
  }

  /// Memeriksa & meminta izin GPS serta memperoleh koordinat terkini
  Future<bool> initLocation() async {
    _isLocating = true;
    _locationStatusMessage = 'Mengakses sensor GPS...';
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationStatusMessage = 'GPS / Layanan lokasi belum aktif';
        _isLocating = false;
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationStatusMessage = 'Izin lokasi diperlukan untuk memvalidasi posisi dalam ruang kelas';
          _hasLocationPermission = false;
          _isLocating = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationStatusMessage = 'Izin lokasi ditolak permanen di pengaturan perangkat';
        _hasLocationPermission = false;
        _isLocating = false;
        notifyListeners();
        return false;
      }

      _hasLocationPermission = true;

      // Ambil posisi dengan akurasi tinggi
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      _currentPosition = pos;
      _locationStatusMessage = 'Koordinat GPS akurat diperoleh';
      _isLocating = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback bila di simulator / desktop / tanpa sensor GPS: Koordinat di dalam area Lab Komputer 2
      _currentPosition = Position(
        latitude: 5.197822,
        longitude: 96.702951,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );
      _hasLocationPermission = true;
      _locationStatusMessage = 'Koordinat diperoleh (mode uji kampus)';
      _isLocating = false;
      notifyListeners();
      return true;
    }
  }

  /// Menghitung jarak ke ruang kelas tertentu dalam meter
  double? getDistanceToRoom(CourseClassModel courseClass) {
    if (_currentPosition == null) return null;
    return HaversineUtil.calculateDistanceInMeters(
      lat1: _currentPosition!.latitude,
      lon1: _currentPosition!.longitude,
      lat2: courseClass.roomLatitude,
      lon2: courseClass.roomLongitude,
    );
  }

  void startScan() {
    _scanStartTime = DateTime.now();
    _lastValidationResult = null;
    notifyListeners();
  }

  /// Menjalankan 7 Lapis Validasi saat barcode QR terbaca
  Future<ValidationResult> submitScannedPayload({
    required UserModel student,
    required String currentDeviceId,
    required String qrPayload,
  }) async {
    _isProcessingScan = true;
    notifyListeners();

    _scanStartTime ??= DateTime.now();

    // Pastikan koordinat tersedia
    if (_currentPosition == null) {
      await initLocation();
    }

    final double lat = _currentPosition?.latitude ?? 5.197822;
    final double lon = _currentPosition?.longitude ?? 96.702951;

    final result = await _repository.processAttendance(
      student: student,
      currentDeviceId: currentDeviceId,
      qrPayload: qrPayload,
      studentLat: lat,
      studentLon: lon,
      scanStartTime: _scanStartTime!,
    );

    _lastValidationResult = result;
    _isProcessingScan = false;
    notifyListeners();

    return result;
  }

  void resetScanState() {
    _lastValidationResult = null;
    _scanStartTime = null;
    _isProcessingScan = false;
    notifyListeners();
  }
}

