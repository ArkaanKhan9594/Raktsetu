// Basic smoke test for RaktSetu: verifies the app boots to the splash
// screen and shows the app name, without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raktsetu/main.dart';

void main() {
  testWidgets('RaktSetu boots and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RaktSetuApp());

    // Splash screen shows the app name and tagline immediately.
    expect(find.text('RaktSetu'), findsOneWidget);
    expect(find.text('Every donor, every drop, connected.'), findsOneWidget);
    expect(find.byIcon(Icons.bloodtype), findsOneWidget);

    // Let the splash timer fire and transition to login screen
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Enter your mobile number'), findsOneWidget);
  });
}
