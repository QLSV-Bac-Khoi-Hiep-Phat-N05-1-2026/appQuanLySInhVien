import 'package:app_quan_ly_sinh_vien/widgets/firebase_app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Startup failure offers a working retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      FirebaseAppLoader(
        initialize: () async {
          if (++attempts == 1) throw StateError('Configuration unavailable');
        },
        child: const MaterialApp(home: Text('App ready')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('App ready'), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('App ready'), findsOneWidget);
    expect(attempts, 2);
  });
}
