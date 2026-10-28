import 'package:app_quan_ly_sinh_vien/screens/learning_sample_screen.dart';
import 'package:app_quan_ly_sinh_vien/screens/project_workspace.dart';
import 'package:app_quan_ly_sinh_vien/services/project_store.dart';
import 'package:app_quan_ly_sinh_vien/ui/project_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1440, 960)]) {
    testWidgets('Dashboard and sample layout fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = ProjectStore.demo(persist: false);
      await store.initialize();
      await tester.pumpWidget(
        MaterialApp(
          theme: projectTheme(),
          home: ProjectWorkspace(store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('TRÌNH DIỄN'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(theme: projectTheme(), home: const LearningSampleScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('HỘP QUÀ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }

  testWidgets('Student form keeps invalid input and saves valid student', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = ProjectStore.demo(persist: false);
    await store.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: projectTheme(),
        home: ProjectWorkspace(store: store),
      ),
    );
    await tester.tap(find.text('Thêm sinh viên').first);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'NEWTEST');
    await tester.enterText(fields.at(1), 'Sinh viên kiểm thử');
    await tester.enterText(fields.at(3), '20.5');
    await tester.tap(find.text('Lưu thông tin'));
    await tester.pumpAndSettle();
    expect(find.text('Tuổi phải là số nguyên từ 1 đến 120.'), findsOneWidget);
    expect(store.students.any((v) => v.studentId == 'NEWTEST'), false);
    await tester.enterText(fields.at(3), '20');
    await tester.tap(find.text('Lưu thông tin'));
    await tester.pumpAndSettle();
    expect(
      store.students.singleWhere((v) => v.studentId == 'NEWTEST').getName(),
      'Sinh viên kiểm thử',
    );
    expect(find.text('Lưu thông tin'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
