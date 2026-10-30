import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/student.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:app_quan_ly_sinh_vien/screens/student_portal_screen.dart';
import 'package:app_quan_ly_sinh_vien/ui/project_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final student = Student(
    studentId: 'SV001',
    name: 'Nguyễn An',
    major: 'Công nghệ thông tin',
    age: 20,
    classId: 'CNTT01',
  );
  final classRoom = ClassRoom(
    id: 'CNTT01',
    name: 'Công nghệ thông tin 01',
    major: 'Công nghệ thông tin',
    cohort: 'K17',
  );
  final subjects = [
    Subject(id: 'MOB01', name: 'Lập trình di động', credits: 3),
    Subject(id: 'WEB01', name: 'Lập trình Web', credits: 3),
  ];
  final grades = [
    Grade(
      studentId: 'SV001',
      subjectId: 'MOB01',
      semester: '2026-1',
      score: 8.5,
    ),
    Grade(studentId: 'SV002', subjectId: 'WEB01', semester: '2026-1', score: 2),
  ];

  Future<void> showPortal(
    WidgetTester tester, {
    Future<void> Function(String, String, String)? onSaveContact,
    Future<void> Function()? onReset,
    Future<void> Function()? onSignOut,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: projectTheme(),
        home: StudentPortalScreen(
          student: student,
          classRoom: classRoom,
          grades: grades,
          subjects: subjects,
          loginEmail: 'sv001@login.example',
          phone: '0900000000',
          contactEmail: 'contact@example.com',
          address: '1 Đường Mẫu',
          onSaveContact: onSaveContact ?? (_, _, _) async {},
          onRequestPasswordReset: onReset ?? () async {},
          onSignOut: onSignOut ?? () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Shows official profile and only grades for the signed-in student',
    (tester) async {
      await showPortal(tester);

      expect(find.text('SV001'), findsOneWidget);
      expect(find.text('Nguyễn An'), findsNWidgets(2));
      expect(find.text('Công nghệ thông tin'), findsOneWidget);
      expect(find.text('Công nghệ thông tin 01'), findsOneWidget);
      expect(find.text('K17'), findsOneWidget);
      expect(find.text('Lập trình di động'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('Lập trình Web'), findsNothing);
      expect(find.text('2'), findsNothing);
      expect(find.text('Thêm sinh viên'), findsNothing);
      expect(find.text('Sửa sinh viên'), findsNothing);
      expect(find.text('Xóa sinh viên'), findsNothing);
      expect(find.text('Sửa điểm'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Contact form validates and saves contact email separately', (
    tester,
  ) async {
    String? savedPhone;
    String? savedEmail;
    String? savedAddress;
    var saveCalls = 0;
    await showPortal(
      tester,
      onSaveContact: (phone, email, address) async {
        saveCalls++;
        savedPhone = phone;
        savedEmail = email;
        savedAddress = address;
      },
    );

    await tester.scrollUntilVisible(
      find.text('Lưu thông tin liên hệ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final fields = find.byType(TextFormField);
    expect(
      (tester.widget<TextFormField>(fields.at(1)).controller!).text,
      'contact@example.com',
    );
    await tester.enterText(fields.at(0), '123');
    await tester.enterText(fields.at(1), 'khong-phai-email');
    await tester.tap(find.text('Lưu thông tin liên hệ'));
    await tester.pumpAndSettle();
    expect(find.text('Số điện thoại chưa đúng định dạng.'), findsOneWidget);
    expect(find.text('Email liên hệ chưa đúng định dạng.'), findsOneWidget);
    expect(saveCalls, 0);

    await tester.enterText(fields.at(0), '+84 900 000 000');
    await tester.enterText(fields.at(1), 'an.private@example.com');
    await tester.enterText(fields.at(2), '12 Đường Mới');
    await tester.tap(find.text('Lưu thông tin liên hệ'));
    await tester.pumpAndSettle();
    expect(saveCalls, 1);
    expect(savedPhone, '+84 900 000 000');
    expect(savedEmail, 'an.private@example.com');
    expect(savedAddress, '12 Đường Mới');
    expect(find.text('Đã lưu thông tin liên hệ.'), findsOneWidget);
    expect(find.text('sv001@login.example'), findsOneWidget);
  });

  testWidgets('Failed contact save keeps entered values in the form', (
    tester,
  ) async {
    await showPortal(
      tester,
      onSaveContact: (_, _, _) async => throw StateError('offline'),
    );

    await tester.scrollUntilVisible(
      find.text('Lưu thông tin liên hệ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0912345678');
    await tester.enterText(fields.at(1), 'new-contact@example.com');
    await tester.enterText(fields.at(2), '99 Đường Đang Nhập');
    await tester.tap(find.text('Lưu thông tin liên hệ'));
    await tester.pumpAndSettle();

    expect(
      find.text('Không lưu được thông tin. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(
      (tester.widget<TextFormField>(fields.at(0)).controller!).text,
      '0912345678',
    );
    expect(
      (tester.widget<TextFormField>(fields.at(1)).controller!).text,
      'new-contact@example.com',
    );
    expect(
      (tester.widget<TextFormField>(fields.at(2)).controller!).text,
      '99 Đường Đang Nhập',
    );
  });

  testWidgets(
    'Password reset explicitly targets login email and sign out calls back',
    (tester) async {
      var resetCalls = 0;
      var signOutCalls = 0;
      await showPortal(
        tester,
        onReset: () async {
          resetCalls++;
        },
        onSignOut: () async {
          signOutCalls++;
        },
      );

      await tester.scrollUntilVisible(
        find.text('Gửi email đặt lại mật khẩu'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Email đăng nhập'), findsOneWidget);
      expect(find.text('sv001@login.example'), findsOneWidget);
      expect(
        find.textContaining('sẽ được gửi đến email đăng nhập này'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Gửi email đặt lại mật khẩu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi email đặt lại mật khẩu'));
      await tester.pumpAndSettle();
      expect(resetCalls, 1);
      expect(
        find.text('Đã gửi yêu cầu đặt lại mật khẩu đến sv001@login.example.'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Đăng xuất').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất').last);
      await tester.pumpAndSettle();
      expect(signOutCalls, 1);
    },
  );

  testWidgets('Phone layout scrolls without overflow', (tester) async {
    await showPortal(tester, size: const Size(360, 780));
    expect(find.text('Cổng sinh viên'), findsOneWidget);
    expect(find.text('Hồ sơ học vụ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
