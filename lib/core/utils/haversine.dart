import 'dart:math' as math;

class HaversineUtil {
  HaversineUtil._();

  /// Menghitung jarak antara dua koordinat (latitude, longitude) dalam satuan meter.
  /// Sesuai fungsi haversine_m pada database dan Bab 3 skripsi.
  static double calculateDistanceInMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusMeters = 6371000; // Radius bumi dalam meter

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  static double _toRadians(double degree) {
    return degree * math.pi / 180.0;
  }
}

