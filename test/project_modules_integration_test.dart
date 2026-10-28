import 'package:app_quan_ly_sinh_vien/screens/project_workspace.dart';
import 'package:app_quan_ly_sinh_vien/services/project_store.dart';
import 'package:app_quan_ly_sinh_vien/ui/project_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in [const Size(390, 844), const Size(1440, 1000)]) {
    testWidgets(
      'Main navigation saves subjects and grades and restores them at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = ProjectStore.demo();
        await store.initialize();
        await tester.pumpWidget(
          MaterialApp(
            theme: projectTheme(),
            home: ProjectWorkspace(store: store),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Generics'), findsNothing);
        expect(find.text('Pavlova'), findsNothing);
        await tester.tap(find.text('Môn & điểm').first);
        await tester.pumpAndSettle();
        expect(find.text('Danh sách môn học'), findsOneWidget);
        await tester.tap(find.text('Thêm môn'));
        await tester.pumpAndSettle();
        var fields = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(fields.at(0), 'NEW09');
        await tester.enterText(fields.at(1), 'Môn tích hợp');
        await tester.enterText(fields.at(2), '3');
        await tester.tap(find.text('Lưu môn'));
        await tester.pumpAndSettle();
        expect(
          store.subjects.singleWhere((s) => s.id == 'NEW09').name,
          'Môn tích hợp',
        );
        await tester.tap(
          find.descendant(
            of: find.byType(SegmentedButton<int>),
            matching: find.text('Bảng điểm'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nhập / cập nhật điểm'));
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(DropdownButtonFormField<String>),
              )
              .at(1),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Môn tích hợp · NEW09').last);
        await tester.tap(find.text('Môn tích hợp · NEW09').last);
        await tester.pumpAndSettle();
        fields = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(fields.at(0), '2026-1');
        await tester.enterText(fields.at(1), '8.5');
        await tester.tap(find.text('Lưu điểm'));
        await tester.pumpAndSettle();
        expect(
          store.grades.singleWhere((g) => g.id == 'SV001~NEW09~2026-1').score,
          8.5,
        );
        expect(find.text('Môn tích hợp'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        store.dispose();
        final reopened = ProjectStore.demo();
        await reopened.initialize();
        expect(reopened.subjects.any((s) => s.id == 'NEW09'), true);
        expect(
          reopened.grades
              .singleWhere((g) => g.id == 'SV001~NEW09~2026-1')
              .score,
          8.5,
        );
        reopened.dispose();
      },
    );
  }
}
