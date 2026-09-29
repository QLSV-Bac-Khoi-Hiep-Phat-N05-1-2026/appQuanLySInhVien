import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_quan_ly_sinh_vien/main.dart';

void main() {
  testWidgets('Student info button toggles details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hiển thị thông tin'), findsOneWidget);
    expect(find.text('Thông tin sinh viên'), findsNothing);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Ẩn thông tin'), findsOneWidget);
    expect(find.text('Thông tin sinh viên'), findsOneWidget);
  });
}
