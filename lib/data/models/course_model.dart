class CourseClassModel {
  final String id;
  final String courseCode;
  final String courseName;
  final String className;
  final int sks;
  String lecturerId;
  String lecturerName;
  final String roomName;
  final double roomLatitude;
  final double roomLongitude;
  final double roomRadiusMeters;
  final String scheduleDay;
  final String scheduleTime;
  final List<String> enrolledStudentIds; // Daftar Mahasiswa peserta KRS
  final String prodi;
  final String fakultas;

  CourseClassModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.className,
    required this.sks,
    required this.lecturerId,
    required this.lecturerName,
    required this.roomName,
    required this.roomLatitude,
    required this.roomLongitude,
    this.roomRadiusMeters = 30.0,
    required this.scheduleDay,
    required this.scheduleTime,
    required this.enrolledStudentIds,
    this.prodi = 'Informatika',
    this.fakultas = 'Fakultas Ilmu Komputer',
  });

  CourseClassModel copyWith({
    String? lecturerId,
    String? lecturerName,
    List<String>? enrolledStudentIds,
    String? prodi,
    String? fakultas,
  }) {
    return CourseClassModel(
      id: id,
      courseCode: courseCode,
      courseName: courseName,
      className: className,
      sks: sks,
      lecturerId: lecturerId ?? this.lecturerId,
      lecturerName: lecturerName ?? this.lecturerName,
      roomName: roomName,
      roomLatitude: roomLatitude,
      roomLongitude: roomLongitude,
      roomRadiusMeters: roomRadiusMeters,
      scheduleDay: scheduleDay,
      scheduleTime: scheduleTime,
      enrolledStudentIds: enrolledStudentIds ?? List.from(this.enrolledStudentIds),
      prodi: prodi ?? this.prodi,
      fakultas: fakultas ?? this.fakultas,
    );
  }
}
