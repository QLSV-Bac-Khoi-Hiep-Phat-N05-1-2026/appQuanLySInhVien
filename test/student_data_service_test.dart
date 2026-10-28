import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/student.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:app_quan_ly_sinh_vien/services/student_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late StudentDataService data;
  setUp(() {
    firestore = FakeFirebaseFirestore();
    data = StudentDataService(firestore);
  });
  Future<void> seed() async {
    await data.classes.create(
      ClassRoom(id: 'CNTT01', name: 'CNTT 01', major: 'CNTT', cohort: 'K17'),
    );
    await data.createStudent(Student(classId: 'CNTT01'));
    await data.subjects.create(
      Subject(id: 'MOB01', name: 'Di động', credits: 3),
    );
  }

  test('Duplicate insertion does not overwrite existing data', () async {
    await seed();
    await expectLater(
      data.createStudent(Student(name: 'Không được ghi đè')),
      throwsStateError,
    );
    expect((await data.students.getById('23016960'))!.name, 'Nguyen Van Bac');
    await expectLater(
      data.classes.create(
        ClassRoom(id: 'CNTT01', name: 'Khác', major: 'CNTT', cohort: 'K17'),
      ),
      throwsStateError,
    );
  });
  test('Missing references fail before student/grade writes', () async {
    await expectLater(
      data.createStudent(Student(classId: 'MISSING')),
      throwsStateError,
    );
    expect(await data.students.getById('23016960'), isNull);
    await expectLater(
      data.saveGrade(
        Grade(studentId: 'SV1', subjectId: 'M1', semester: '2026-1', score: 8),
      ),
      throwsStateError,
    );
    expect((await firestore.collection('grades').get()).docs, isEmpty);
  });
  test(
    'Grade upsert preserves one record per student, subject and semester',
    () async {
      await seed();
      for (final score in [8.0, 9.0]) {
        await data.saveGrade(
          Grade(
            studentId: '23016960',
            subjectId: 'MOB01',
            semester: '2026-1',
            score: score,
          ),
        );
      }
      expect((await firestore.collection('grades').get()).docs.length, 1);
      expect(
        (await data.watchGradesForStudent('23016960').first).single.score,
        9,
      );
    },
  );
  test('Update, typed snapshots and class filtering work', () async {
    await seed();
    await data.createStudent(Student(studentId: 'SV2'));
    final student = (await data.students.getById('23016960'))!;
    await data.students.update(
      Student(
        studentId: student.studentId,
        name: 'Nguyễn Văn Bắc',
        major: student.major,
        age: student.age,
        email: student.email,
        classId: student.classId,
      ),
    );
    expect((await data.students.getById('23016960'))!.name, 'Nguyễn Văn Bắc');
    expect(
      (await data.watchStudentsInClass('CNTT01').first).single.studentId,
      '23016960',
    );
    expect((await data.students.watchAll().first).length, 2);
    await expectLater(
      data.subjects.update(Subject(id: 'MISSING', name: 'A', credits: 3)),
      throwsA(anything),
    );
    expect(await data.subjects.getById('MISSING'), isNull);
  });
}
