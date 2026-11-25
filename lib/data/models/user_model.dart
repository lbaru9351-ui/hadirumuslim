enum UserRole {
  mahasiswa,
  dosen,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.mahasiswa:
        return 'Mahasiswa';
      case UserRole.dosen:
        return 'Dosen';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'dosen':
        return UserRole.dosen;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.mahasiswa;
    }
  }
}

/// Hirarki Administrasi Akademik di Universitas Almuslim:
/// 1. Universitas: Biro Administrasi Akademik (BAA) / Rektorat (Membawahi seluruh fakultas & kalender akademik master).
/// 2. Fakultas: Dekanat / Tata Usaha Fakultas (Membawahi beberapa prodi di bawahnya & ruang kuliah/lab fakultas).
/// 3. Prodi: Ketua/Sekretaris/Operator Program Studi (Mata kuliah, kelas 16 pertemuan, KRS, & reset HP mahasiswa).
enum AdminScope {
  universitas,
  fakultas,
  prodi;

  String get displayName {
    switch (this) {
      case AdminScope.universitas:
        return 'Admin Universitas (BAA)';
      case AdminScope.fakultas:
        return 'Admin Fakultas';
      case AdminScope.prodi:
        return 'Admin Program Studi';
    }
  }

  String get badgeLabel {
    switch (this) {
      case AdminScope.universitas:
        return 'Tingkat Universitas (BAA)';
      case AdminScope.fakultas:
        return 'Tingkat Fakultas';
      case AdminScope.prodi:
        return 'Tingkat Program Studi';
    }
  }

  static AdminScope fromString(String val) {
    switch (val.toLowerCase()) {
      case 'universitas':
        return AdminScope.universitas;
      case 'fakultas':
        return AdminScope.fakultas;
      default:
        return AdminScope.prodi;
    }
  }
}

class UserModel {
  final String id;
  final String identifier; // NPM untuk mahasiswa, NIP/NIDN untuk dosen, username untuk admin
  final String name;
  final UserRole role;
  final String email;
  final List<String> boundDeviceIds; // Mahasiswa: maks 1 perangkat; Dosen: maks 2 perangkat
  final String prodi;
  final String fakultas;
  final AdminScope? adminScope;

  UserModel({
    required this.id,
    required this.identifier,
    required this.name,
    required this.role,
    required this.email,
    List<String>? boundDeviceIds,
    this.prodi = 'Informatika',
    this.fakultas = 'Fakultas Ilmu Komputer',
    this.adminScope,
  }) : boundDeviceIds = boundDeviceIds ?? [];

  // Mendapatkan ID perangkat utama
  String? get boundDeviceId => boundDeviceIds.isNotEmpty ? boundDeviceIds.first : null;

  bool get isDeviceBound => boundDeviceIds.isNotEmpty;

  // Helper getters peran & hirarki
  bool get isAdmin => role == UserRole.admin;
  bool get isAdminUniversitas => role == UserRole.admin && adminScope == AdminScope.universitas;
  bool get isAdminFakultas => role == UserRole.admin && adminScope == AdminScope.fakultas;
  bool get isAdminProdi => role == UserRole.admin && (adminScope == AdminScope.prodi || adminScope == null);

  // Batas maksimal perangkat sesuai aturan: Mahasiswa = 1, Dosen = 2, Admin = tidak terbatas
  int get maxAllowedDevices {
    switch (role) {
      case UserRole.mahasiswa:
        return 1;
      case UserRole.dosen:
        return 2;
      case UserRole.admin:
        return 999;
    }
  }

  bool isDeviceAllowed(String deviceId) {
    if (role == UserRole.admin) return true;
    if (boundDeviceIds.contains(deviceId)) return true;
    // Jika belum mencapai batas perangkat, izinkan pengikatan
    return boundDeviceIds.length < maxAllowedDevices;
  }

  UserModel copyWith({
    List<String>? boundDeviceIds,
    String? boundDeviceId,
    String? name,
    String? email,
    String? prodi,
    String? fakultas,
    AdminScope? adminScope,
  }) {
    List<String> devices = boundDeviceIds ?? List.from(this.boundDeviceIds);
    if (boundDeviceId != null) {
      if (boundDeviceId.isEmpty) {
        devices = [];
      } else if (!devices.contains(boundDeviceId)) {
        devices.add(boundDeviceId);
      }
    }

    return UserModel(
      id: id,
      identifier: identifier,
      name: name ?? this.name,
      role: role,
      email: email ?? this.email,
      boundDeviceIds: devices,
      prodi: prodi ?? this.prodi,
      fakultas: fakultas ?? this.fakultas,
      adminScope: adminScope ?? this.adminScope,
    );
  }
}
