import 'package:app_quan_ly_sinh_vien/models/app_user.dart';
import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/student.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:app_quan_ly_sinh_vien/screens/role_session_screen.dart';
import 'package:app_quan_ly_sinh_vien/services/project_store.dart';
import 'package:app_quan_ly_sinh_vien/ui/project_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Only three roles are accepted and student identity is mandatory', () {
    expect(
      () => AppUser(
        uid: 'u',
        email: 'u@example.test',
        displayName: 'U',
        role: 'manager',
      ),
      throwsFormatException,
    );
    expect(
      () => AppUser(
        uid: 'u',
        email: 'u@example.test',
        displayName: 'U',
        role: 'student',
      ),
      throwsFormatException,
    );
    expect(
      () => Grade(studentId: 'S', subjectId: 'M', semester: '2026-3', score: 8),
      throwsFormatException,
    );
  });
  test('Lecturer scope includes assigned class only and rejects cross-class writes', () async {
    final s = ProjectStore.demo(role: 'lecturer', persist: false);
    await s.initialize();
    expect(s.profile.role, 'lecturer');
    expect(s.classes.map((c) => c.id), ['CNTT01']);
    expect(s.students.every((v) => v.classId == 'CNTT01'), true);
    expect(
      s.grades.every((g) => s.students.any((v) => v.studentId == g.studentId)),
      true,
    );
    await expectLater(
      s.saveStudent(Student(studentId: 'NEW', classId: 'CNTT02')),
      throwsStateError,
    );
    await expectLater(
      s.saveGrade(
        Grade(
          studentId: 'SV005',
          subjectId: 'MOB01',
          semester: '2026-1',
          score: 9,
        ),
      ),
      throwsStateError,
    );
    await expectLater(
      s.saveClass(
        ClassRoom(id: 'NEW', name: 'N', major: 'CNTT', cohort: 'K17'),
      ),
      throwsStateError,
    );
    await expectLater(
      s.saveSubject(Subject(id: 'NEW', name: 'N', credits: 3)),
      throwsStateError,
    );
    await s.saveStudent(Student(studentId: 'NEW', classId: 'CNTT01'));
    expect(s.students.any((v) => v.studentId == 'NEW'), true);
    s.dispose();
  });
  test(
    'Student edits own contacts but cannot write academic data or roles',
    () async {
      final s = ProjectStore.demo(role: 'student');
      await s.initialize();
      expect(s.students.map((v) => v.studentId), ['SV001']);
      expect(s.grades.every((g) => g.studentId == 'SV001'), true);
      await expectLater(
        s.saveStudent(
          Student(studentId: 'SV001', name: 'Giả mạo', classId: 'CNTT01'),
          editing: true,
        ),
        throwsStateError,
      );
      await expectLater(
        s.saveGrade(
          Grade(
            studentId: 'SV001',
            subjectId: 'MOB01',
            semester: '2026-1',
            score: 10,
          ),
        ),
        throwsStateError,
      );
      await expectLater(s.updateName('Giả mạo'), throwsStateError);
      await expectLater(
        s.decideLecturer('demo-pending', true),
        throwsStateError,
      );
      await s.updateContact('0912345678', 'personal@example.test', 'Hà Nội');
      final reopened = ProjectStore.demo(role: 'student');
      await reopened.initialize();
      expect(reopened.profile.phone, '0912345678');
      expect(reopened.profile.contactEmail, 'personal@example.test');
      expect(reopened.myStudent!.name, 'Sinh viên Mẫu 01');
      expect(reopened.myStudent!.classId, 'CNTT01');
      s.dispose();
      reopened.dispose();
    },
  );
  test('Admin approves lecturer and assigns class; lecturer can provision student in scope', () async {
    final admin = ProjectStore.demo();
    await admin.initialize();
    await admin.decideLecturer('demo-pending', true);
    await admin.assignLecturer('KT01', 'demo-pending');
    expect(
      admin.classes.singleWhere((c) => c.id == 'KT01').lecturerId,
      'demo-pending',
    );
    final lecturer = ProjectStore.demo(role: 'lecturer');
    await lecturer.initialize();
    final message = await lecturer.provisionStudent(
      'SV002',
      'new.student@example.test',
    );
    expect(message, contains('demo'));
    final uid = lecturer.students
        .singleWhere((s) => s.studentId == 'SV002')
        .accountUid;
    expect(uid, isNotNull);
    final check = ProjectStore.demo();
    await check.initialize();
    expect(check.users.singleWhere((u) => u.uid == uid).studentId, 'SV002');
    expect(check.users.singleWhere((u) => u.uid == uid).role, 'student');
    await expectLater(
      lecturer.provisionStudent('SV007', 'outside@example.test'),
      throwsStateError,
    );
    admin.dispose();
    lecturer.dispose();
    check.dispose();
  });
  testWidgets(
    'Student session has no academic mutation actions and only own grades',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = ProjectStore.demo(role: 'student', persist: false);
      await s.initialize();
      await tester.pumpWidget(
        MaterialApp(
          theme: projectTheme(),
          home: StudentSessionScreen(store: s, onSignOut: () async {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thêm sinh viên'), findsNothing);
      expect(find.text('Nhập / cập nhật điểm'), findsNothing);
      expect(find.text('Sinh viên Mẫu 02'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
}
