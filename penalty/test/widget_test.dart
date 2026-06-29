import 'package:flutter_test/flutter_test.dart';

import 'package:penalty/main.dart';

void main() {
  testWidgets('App renders game screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PenaltyApp());
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('ROUND'), findsOneWidget);
  });
}
