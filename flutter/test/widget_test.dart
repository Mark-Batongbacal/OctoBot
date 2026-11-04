import 'package:flutter_test/flutter_test.dart';
import 'package:octobot/main.dart';

void main() {
  testWidgets('displays the app name', (tester) async {
    await tester.pumpWidget(const OctoBotApp());
    expect(find.text('OctoBot'), findsOneWidget);
  });
}
