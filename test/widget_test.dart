// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluunt_app/main.dart';

void main() {
  testWidgets('Wizard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FluuntApp());

    // Verify that we start at Step 1 (Atendimento)
    expect(find.text('Atendimento'), findsWidgets);
    expect(find.text('PRÓXIMO'), findsOneWidget);
  });
}
