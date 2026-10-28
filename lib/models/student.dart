import 'model_validation.dart';

/// Student document. The identifier is immutable and stored in the document path.
class Student {
  final String studentId;
  final String name;
  final String major;
  final int age;
  final String? classId;
  final String email;

  Student({
    this.name = 'Nguyen Van Bac',
    this.studentId = '23016960',
    this.major = 'Cong nghe thong tin',
    this.age = 21,
    this.classId,
    this.email = '',
  }) {
    validate();
  }

  void validate() {
    ModelValidation.id(studentId, 'Mã sinh viên');
    ModelValidation.text(name, 'Họ tên');
    ModelValidation.text(major, 'Ngành');
    ModelValidation.email(email, optional: true);
    if (age < 1 || age > 120) {
      throw const FormatException('Tuổi phải từ 1 đến 120.');
    }
    if (classId != null) ModelValidation.id(classId!, 'Mã lớp');
  }

  factory Student.fromMap(String id, Map<String, dynamic> data) => Student(
    studentId: id,
    name: ModelValidation.string(data, 'name'),
    major: ModelValidation.string(data, 'major'),
    age: ModelValidation.integer(data, 'age'),
    classId: data['classId'] == null
        ? null
        : ModelValidation.string(data, 'classId'),
    email: ModelValidation.string(data, 'email'),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'major': major,
    'age': age,
    'classId': classId,
    'email': email,
  };
}
