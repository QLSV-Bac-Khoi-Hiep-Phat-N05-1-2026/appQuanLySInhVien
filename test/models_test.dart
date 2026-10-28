import 'package:app_quan_ly_sinh_vien/models/app_user.dart';
import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/student.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('All five models round-trip with document IDs separate from data', () {
    final user = AppUser(
      uid: 'uid-1',
      email: 'manager@example.com',
      displayName: 'Bắc',
    );
    expect(AppUser.fromMap(user.uid, user.toMap()).displayName, 'Bắc');
    final room = ClassRoom(
      id: 'CNTT01',
      name: 'CNTT 01',
      major: 'CNTT',
      cohort: 'K17',
    );
    expect(ClassRoom.fromMap(room.id, room.toMap()).cohort, 'K17');
    final student = Student(classId: room.id, email: 'student@example.com');
    final restored = Student.fromMap(student.studentId, student.toMap());
    expect(restored.studentId, student.studentId);
    expect(restored.classId, room.id);
    expect(restored.name, student.name);
    expect(student.toMap().containsKey('id'), false);
    final subject = Subject(id: 'MOB01', name: 'Lập trình di động', credits: 3);
    expect(Subject.fromMap(subject.id, subject.toMap()).credits, 3);
    final grade = Grade(
      studentId: student.studentId,
      subjectId: subject.id,
      semester: '2026-1',
      score: 8.5,
    );
    expect(Grade.fromMap(grade.id, grade.toMap()).score, 8.5);
  });

  test('Student rejects invalid values before creating a document', () {
    expect(() => Student(age: -1), throwsFormatException);
    expect(() => Student(studentId: 'invalid/id'), throwsFormatException);
    expect(() => Student(name: '   '), throwsFormatException);
    final original = Student(name: 'Sinh viên mẫu', classId: 'CNTT01');
    final restored = Student.fromMap(original.studentId, original.toMap());
    expect(restored.name, original.name);
    expect(restored.classId, original.classId);
  });

  test('Models reject malformed or incomplete Firestore documents', () {
    expect(() => Student.fromMap('SV1', {'name': 'A'}), throwsFormatException);
    expect(
      () => ClassRoom(id: 'bad/id', name: 'A', major: 'CNTT', cohort: 'K17'),
      throwsFormatException,
    );
    expect(
      () => Subject(id: 'S1', name: 'A', credits: 0),
      throwsFormatException,
    );
    expect(
      () => Subject(id: 'S1', name: '   ', credits: 3),
      throwsFormatException,
    );
    expect(
      () => AppUser(uid: 'u1', email: 'invalid', displayName: 'A'),
      throwsFormatException,
    );
    expect(() => Student(classId: ''), throwsFormatException);
  });

  for (final score in [-0.1, 10.1, double.nan, double.infinity]) {
    test('Grade rejects score $score', () {
      expect(
        () => Grade(
          studentId: 'SV1',
          subjectId: 'M1',
          semester: '2026-1',
          score: score,
        ),
        throwsFormatException,
      );
    });
  }
  test('Grade allows both boundaries and rejects mismatched document IDs', () {
    for (final score in [0.0, 10.0]) {
      final grade = Grade(
        studentId: 'SV1',
        subjectId: 'M1',
        semester: '2026-1',
        score: score,
      );
      expect(Grade.fromMap(grade.id, grade.toMap()).score, score);
      expect(
        () => Grade.fromMap('wrong', grade.toMap()),
        throwsFormatException,
      );
    }
  });
}
