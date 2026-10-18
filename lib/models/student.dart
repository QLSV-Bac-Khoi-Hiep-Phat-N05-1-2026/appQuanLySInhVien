import 'generic_class.dart';

class Student extends Genericclass<Object> {
  int age;

  Student({
    String name = 'Nguyen Van Bac',
    String studentId = '23016960',
    String major = 'Cong nghe thong tin',
    this.age = 21,
  }) : super(id: studentId, name: name, description: major);

  // Giữ cách truy cập thông tin của lớp Student có sẵn.
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
}
