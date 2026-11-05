import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octobot/app/octobot_app.dart';

void main() {
  testWidgets('renders the controller without fabricating live readings',
      (tester) async {
    await tester.pumpWidget(const OctoBotApp());
    expect(find.text('OCTOBOT'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('STOP MOTION'), findsOneWidget);
    expect(find.text('Connect to OctoBot to enable the joystick'), findsOneWidget);
  });

  testWidgets('can navigate to connection settings while offline',
      (tester) async {
    await tester.pumpWidget(const OctoBotApp());
    await tester.tap(find.text('Connect').last);
    await tester.pumpAndSettle();
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('Connect to OctoBot'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
