import 'package:flutter_test/flutter_test.dart';
import 'package:sla_tracker/main.dart';

void main() {
  testWidgets('App smoke test - displays sign in screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
