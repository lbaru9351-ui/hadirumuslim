class AppDimensions {
  AppDimensions._();

  // Padding & Spacing
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 20.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 32.0;

  // Border Radius (12 - 16 px sesuai spesifikasi)
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;

  // Button Heights & Touch Target
  static const double buttonHeight = 52.0; // Standar tombol 52 px
  static const double minTouchTarget = 44.0; // Target sentuh minimal 44 px

  // Parameter Default Sistem Penelitian
  static const int qrTokenIntervalSeconds = 30; // 30 detik per pergantian token
  static const int sessionTimeoutMinutes = 15; // 15 menit batas waktu sesi default
  static const double defaultRoomRadiusMeters = 30.0; // Radius ruang 30 meter
  static const int targetScanDurationSeconds = 3; // Target <= 3 detik (KF-14)
}

