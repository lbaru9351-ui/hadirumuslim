import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceHelper {
  DeviceHelper._();

  static const String _prefKeyFallbackDeviceId = 'fallback_device_unique_id';

  /// Mendapatkan ID Perangkat unik untuk pengikatan akun (Lapis 2 validasi).
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Gunakan androidId (SSAID) bila tersedia
        if (androidInfo.id.isNotEmpty) {
          return 'android_${androidInfo.id}';
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final identifier = iosInfo.identifierForVendor;
        if (identifier != null && identifier.isNotEmpty) {
          return 'ios_$identifier';
        }
      }
    } catch (_) {
      // Fallback untuk web/desktop atau bila akses dibatasi
    }

    // Fallback: UUID tersimpan di SharedPreferences lokal
    final prefs = await SharedPreferences.getInstance();
    var fallbackId = prefs.getString(_prefKeyFallbackDeviceId);
    if (fallbackId == null || fallbackId.isEmpty) {
      fallbackId = 'dev_${const Uuid().v4()}';
      await prefs.setString(_prefKeyFallbackDeviceId, fallbackId);
    }
    return fallbackId;
  }

  /// Mendapatkan nama model perangkat untuk audit penelitian
  static Future<String> getDeviceModel() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return '${info.manufacturer} ${info.model} (Android ${info.version.release})';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return '${info.name} ${info.systemName} ${info.systemVersion}';
      }
    } catch (_) {}
    return 'Unknown Device';
  }
}

