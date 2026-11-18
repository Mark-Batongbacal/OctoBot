import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octobot/app/octobot_app.dart';

void main() {
  testWidgets('offline robot locks four directions and has no STOP button',
      (tester) async {
    await tester.pumpWidget(const OctoBotApp());
    expect(find.text('OCTOBOT'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('STOP MOTION'), findsNothing);
    expect(find.text('FORWARD'), findsOneWidget);
    expect(find.text('BACKWARD'), findsOneWidget);
    expect(find.text('LOCKED'), findsOneWidget);\n    expect(find.text('LEFT'), findsOneWidget);
    expect(find.text('RIGHT'), findsOneWidget);
    expect(find.text('Autonomy'), findsNothing);
    expect(find.text('OCTOPOD / TOP VIEW'), findsNothing);
    expect(find.text('Connect to OctoBot to enable controls'), findsOneWidget);
  });

  testWidgets('monitor shows unavailable sensor data while offline',
      (tester) async {
    await tester.pumpWidget(const OctoBotApp());
    await tester.tap(find.text('Monitor').last);
    await tester.pumpAndSettle();
    expect(find.text('Sensor data unavailable'), findsOneWidget);
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
