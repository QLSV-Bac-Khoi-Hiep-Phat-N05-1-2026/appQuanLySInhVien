import 'package:app_quan_ly_sinh_vien/main.dart';
import 'package:app_quan_ly_sinh_vien/screens/practice_one_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Review accepts a rating and counts the user only once', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(width: 360, child: Review())),
      ),
    );
    expect(find.text('170 Reviews'), findsOneWidget);

    await tester.tap(find.byTooltip('Đánh giá 3 sao'));
    await tester.pump();
    expect(find.text('Bạn đã đánh giá 3/5 sao'), findsOneWidget);
    expect(find.text('171 Reviews'), findsOneWidget);

    await tester.tap(find.byTooltip('Đánh giá 5 sao'));
    await tester.pump();
    expect(find.text('Bạn đã đánh giá 5/5 sao'), findsOneWidget);
    expect(find.text('171 Reviews'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reviews text accepts a tap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(width: 360, child: Review())),
      ),
    );
    await tester.tap(find.text('170 Reviews'));
    await tester.pump();
    expect(find.text('171 Reviews'), findsOneWidget);
    expect(find.text('Bạn đã đánh giá 5/5 sao'), findsOneWidget);
  });

  testWidgets('Home opens practice one on a phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Phần thực hành số 1'));
    await tester.tap(find.text('Phần thực hành số 1'));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeOneScreen), findsOneWidget);
    expect(find.text('Strawberry Pavlova'), findsOneWidget);
    expect(find.byType(RecipePanel), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
