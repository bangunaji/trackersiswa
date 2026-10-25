import 'package:flutter_test/flutter_test.dart';
import 'package:smanda_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmandaApp());
    expect(find.text('SMANDA Activity'), findsOneWidget);
  });
}
