import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laban_pwa/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test - Login View renders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const SipLabanApp());
    await tester.pumpAndSettle();

    // Verify Login page renders
    expect(find.text('WASLASOFT'), findsOneWidget);
    expect(find.text('Sign In to Terminal'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });
}
