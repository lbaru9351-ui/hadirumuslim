import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/course_model.dart';
import '../../data/models/session_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../core/constants/dimensions.dart';

class LecturerSessionProvider extends ChangeNotifier {
  final AttendanceRepository _repository;

  SessionModel? _activeSession;
  Timer? _countdownTimer;
  int _tokenSecondsLeft = AppDimensions.qrTokenIntervalSeconds;
  List<AttendanceModel> _currentSessionAttendances = [];
  List<LeaveRequestModel> _sessionLeaveRequests = [];

  LecturerSessionProvider(this._repository);

  SessionModel? get activeSession => _activeSession;
  int get tokenSecondsLeft => _tokenSecondsLeft;
  List<AttendanceModel> get currentSessionAttendances => _currentSessionAttendances;
  List<LeaveRequestModel> get sessionLeaveRequests => _sessionLeaveRequests;

  List<CourseClassModel> getClasses(String lecturerId) {
    return _repository.getClassesForLecturer(lecturerId);
  }

  Future<void> startSession({
    required String classId,
    required int meetingNumber,
    DateTime? sessionDate,
    int timeoutMinutes = AppDimensions.sessionTimeoutMinutes,
    SessionMode mode = SessionMode.luring,
  }) async {
    _activeSession = await _repository.openSession(
      classId: classId,
      meetingNumber: meetingNumber,
      sessionDate: sessionDate,
      timeoutMinutes: timeoutMinutes,
      mode: mode,
    );
    _tokenSecondsLeft = AppDimensions.qrTokenIntervalSeconds;
    _refreshAttendances();
    _startTimers();
    notifyListeners();
  }

  void _startTimers() {
    _stopTimers();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeSession == null || _activeSession!.status == SessionStatus.tutup) {
        _stopTimers();
        return;
      }

      if (_activeSession!.isExpired) {
        closeCurrentSession();
        return;
      }

      if (_tokenSecondsLeft > 1) {
        _tokenSecondsLeft--;
      } else {
        _tokenSecondsLeft = AppDimensions.qrTokenIntervalSeconds;
        if (_activeSession != null) {
          _repository.rotateSessionToken(_activeSession!.id);
        }
      }
      _refreshAttendances();
      notifyListeners();
    });
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _refreshAttendances() {
    if (_activeSession != null) {
      _currentSessionAttendances = _repository.getAttendancesForSession(_activeSession!.id);
      _sessionLeaveRequests = _repository.getLeaveRequestsForSession(_activeSession!.id);
      _activeSession!.attendedCount = _currentSessionAttendances.length;
    }
  }

  void loadSessionAttendances(String sessionId) {
    _currentSessionAttendances = _repository.getAttendancesForSession(sessionId);
    _sessionLeaveRequests = _repository.getLeaveRequestsForSession(sessionId);
    notifyListeners();
  }

  void closeCurrentSession() {
    if (_activeSession != null) {
      _repository.closeSession(_activeSession!.id);
      _activeSession!.status = SessionStatus.tutup;
      _stopTimers();
      _refreshAttendances();
      notifyListeners();
    }
  }

  bool updateStudentStatus({
    required String attendanceId,
    required AttendanceStatus newStatus,
    required String reason,
    required String lecturerName,
  }) {
    final success = _repository.updateAttendanceStatus(
      attendanceId: attendanceId,
      newStatus: newStatus,
      reason: reason,
      lecturerName: lecturerName,
    );
    _refreshAttendances();
    notifyListeners();
    return success;
  }

  void reviewLeaveRequest({
    required String requestId,
    required bool isApproved,
    required String lecturerName,
    String? note,
  }) {
    _repository.reviewLeaveRequest(
      requestId: requestId,
      isApproved: isApproved,
      lecturerName: lecturerName,
      note: note,
    );
    _refreshAttendances();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
