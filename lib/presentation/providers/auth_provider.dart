import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../core/utils/device_helper.dart';

class AuthProvider extends ChangeNotifier {
  final AttendanceRepository _repository;

  UserModel? _currentUser;
  String _currentDeviceId = '';
  String _deviceModel = '';
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._repository) {
    _initDeviceInfo();
  }

  UserModel? get currentUser => _currentUser;
  String get currentDeviceId => _currentDeviceId;
  String get deviceModel => _deviceModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _initDeviceInfo() async {
    _currentDeviceId = await DeviceHelper.getDeviceId();
    _deviceModel = await DeviceHelper.getDeviceModel();
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.login(
        identifier: identifier,
        password: password,
        currentDeviceId: _currentDeviceId,
      );

      if (user == null) {
        _errorMessage = 'NPM/NIP atau kata sandi tidak valid';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Validasi Lapis 2 pada login jika mahasiswa memakai perangkat berbeda
      if (user.role == UserRole.mahasiswa &&
          user.boundDeviceIds.isNotEmpty &&
          !user.boundDeviceIds.contains(_currentDeviceId)) {
        _errorMessage = 'Akun ini terikat pada 1 perangkat lain. Silakan hubungi Admin untuk reset.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setTestUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
}

