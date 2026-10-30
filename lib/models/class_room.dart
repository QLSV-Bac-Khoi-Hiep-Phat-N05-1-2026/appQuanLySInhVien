import 'model_validation.dart';

class ClassRoom {
  final String id;
  final String name;
  final String major;
  final String cohort;
  final String? lecturerId;
  final String? lecturerName;

  ClassRoom({
    required this.id,
    required this.name,
    required this.major,
    required this.cohort,
    this.lecturerId,
    this.lecturerName,
  }) {
    ModelValidation.id(id, 'Mã lớp');
    ModelValidation.text(name, 'Tên lớp');
    ModelValidation.text(major, 'Ngành');
    ModelValidation.text(cohort, 'Khóa học', max: 30);
  }

  factory ClassRoom.fromMap(String id, Map<String, dynamic> data) => ClassRoom(
    id: id,
    name: ModelValidation.string(data, 'name'),
    major: ModelValidation.string(data, 'major'),
    cohort: ModelValidation.string(data, 'cohort'),
    lecturerId: data['lecturerId'] as String?,
    lecturerName: data['lecturerName'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'major': major,
    'cohort': cohort,
    if (lecturerId != null) 'lecturerId': lecturerId,
    if (lecturerName != null) 'lecturerName': lecturerName,
  };
}
