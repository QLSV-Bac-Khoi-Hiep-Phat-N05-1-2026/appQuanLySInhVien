class Student {
  String name = "Nguyen Van Bac";
  String studentId = "23016960";
  String major = "Cong nghe thong tin";
  int age = 21;

  void setStudent(String name, String studentId, String major, int age) {
    this.name = name;
    this.studentId = studentId;
    this.major = major;
    this.age = age;
  }

  String getName() {
    return name;
  }

  String getStudentId() {
    return studentId;
  }

  String getMajor() {
    return major;
  }

  int getAge() {
    return age;
  }
}