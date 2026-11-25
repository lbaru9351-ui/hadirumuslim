class AcademicEventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String category; // 'kuliah', 'uts', 'uas', 'krs', 'libur'

  AcademicEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.category,
  });
}

