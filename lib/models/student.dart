import 'generic_class.dart';
import 'model_validation.dart';

/// Keeps the existing Generics exercise API while adding Firestore mapping.
class Student extends Genericclass<Object> {
  int age;
  String? classId;
  String email;

  Student({
    String name = 'Nguyen Van Bac',
    String studentId = '23016960',
    String major = 'Cong nghe thong tin',
    this.age = 21,
    this.classId,
    this.email = '',
  }) : super(id: studentId, name: name, description: major) {
    validate();
  }

  String get studentId => getId() as String;
  set studentId(String value) => setId(value);
  String get major => getDescription() as String;
  set major(String value) => setDescription(value);

  void setStudent(String name, String studentId, String major, int age) {
    setName(name);
    setId(studentId);
    setDescription(major);
    this.age = age;
  }

  @override
  String getName() => super.getName() as String;
  String getStudentId() => studentId;
  String getMajor() => major;
  int getAge() => age;

  void validate() {
    ModelValidation.id(studentId, 'Mã sinh viên');
    ModelValidation.text(getName(), 'Họ tên');
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

  Map<String, dynamic> toMap() {
    // Revalidate because the legacy Generics API allows mutation.
    validate();
    return {
      'name': getName(),
      'major': major,
      'age': age,
      'classId': classId,
      'email': email,
    };
  }
}
