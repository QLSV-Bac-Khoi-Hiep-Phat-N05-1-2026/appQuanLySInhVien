import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/student.dart';
import 'package:app_quan_ly_sinh_vien/services/project_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Demo CRUD survives reopening without overwriting on duplicate',
    () async {
      final store = ProjectStore.demo();
      await store.initialize();
      await store.saveStudent(
        Student(studentId: 'NEW01', name: 'Sinh viên mới', classId: 'CNTT01'),
      );
      await expectLater(
        store.saveStudent(Student(studentId: 'NEW01')),
        throwsStateError,
      );
      await store.saveStudent(
        Student(studentId: 'NEW01', name: 'Tên đã sửa', classId: 'CNTT02'),
        editing: true,
      );
      await store.updateName('Quản lý thử');
      final reopened = ProjectStore.demo();
      await reopened.initialize();
      expect(
        reopened.students.where((v) => v.studentId == 'NEW01').single.getName(),
        'Tên đã sửa',
      );
      expect(
        reopened.students.where((v) => v.studentId == 'NEW01').single.classId,
        'CNTT02',
      );
      expect(reopened.profile.displayName, 'Quản lý thử');
      await reopened.deleteStudent('NEW01');
      expect(reopened.students.any((v) => v.studentId == 'NEW01'), false);
      store.dispose();
      reopened.dispose();
    },
  );

  test(
    'References and grade invariant prevent invalid student deletion',
    () async {
      final store = ProjectStore.demo(persist: false);
      await store.initialize();
      await expectLater(
        store.saveStudent(Student(studentId: 'NEW', classId: 'MISSING')),
        throwsStateError,
      );
      await expectLater(store.deleteStudent('SV001'), throwsStateError);
      expect(store.students.any((v) => v.studentId == 'SV001'), true);
      expect(store.students.any((v) => v.studentId == 'NEW'), false);
      await expectLater(
        store.saveStudent(Student(studentId: 'MISSING'), editing: true),
        throwsStateError,
      );
      store.dispose();
    },
  );

  test(
    'Class edit keeps student membership and refuses duplicate class',
    () async {
      final store = ProjectStore.demo(persist: false);
      await store.initialize();
      final c = ClassRoom(
        id: 'CNTT01',
        name: 'Tên mới',
        major: 'CNTT',
        cohort: 'K18',
      );
      await expectLater(store.saveClass(c), throwsStateError);
      await store.saveClass(c, editing: true);
      expect(store.className('CNTT01'), 'Tên mới');
      expect(store.students.where((v) => v.classId == 'CNTT01').length, 4);
      store.dispose();
    },
  );

  test(
    'Grade upsert preserves tuple identity and different semesters',
    () async {
      final store = ProjectStore.demo(persist: false);
      await store.initialize();
      final count = store.grades.length;
      await store.saveGrade(
        Grade(
          studentId: 'SV001',
          subjectId: 'MOB01',
          semester: '2026-1',
          score: 10,
        ),
      );
      expect(store.grades.length, count);
      expect(
        store.grades.singleWhere((v) => v.id == 'SV001~MOB01~2026-1').score,
        10,
      );
      await store.saveGrade(
        Grade(
          studentId: 'SV001',
          subjectId: 'MOB01',
          semester: '2026-2',
          score: 4,
        ),
      );
      expect(store.grades.length, count + 1);
      await expectLater(
        store.saveGrade(
          Grade(
            studentId: 'MISSING',
            subjectId: 'MOB01',
            semester: '2026-1',
            score: 8,
          ),
        ),
        throwsStateError,
      );
      store.dispose();
    },
  );
}
