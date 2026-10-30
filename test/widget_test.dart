// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:blood_bank_locator/main.dart';

void main() {
  testWidgets('opens quick overview before welcome', (WidgetTester tester) async {
    await tester.pumpWidget(const BloodBankApp());

    expect(find.text('Blood Bank Locator'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4500));
    await tester.pump();

    await tester.pumpAndSettle();
    expect(find.text('Find Blood. Connect Faster.'), findsOneWidget);

    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Find Blood\nWhen You Need It'), findsOneWidget);
  });
}
