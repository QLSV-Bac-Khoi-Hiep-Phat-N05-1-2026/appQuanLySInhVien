import 'package:flutter_test/flutter_test.dart';

import 'package:app_quan_ly_sinh_vien/main.dart';

void main() {
  testWidgets('Home opens the Generics assignment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.ensureVisible(find.text('Thực hành Generics'));
    await tester.tap(find.text('Thực hành Generics'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Student extends Genericclass<Object>'),
      findsOneWidget,
    );
    expect(find.textContaining('Type (runtimeType): Student'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
