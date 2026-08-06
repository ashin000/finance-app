// This is a basic Flutter widget test for PayVoice AI.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: PayVoiceApp(),
      ),
    );

    // Verify that the app title or a key login element is present.
    // Since the app starts at /auth by default (due to GoRouter redirect if not logged in),
    // we should see the AuthScreen elements.
    expect(find.text('PayVoice AI'), findsWidgets);
    expect(find.text('Sign In to Continue'), findsOneWidget);
  });
}
