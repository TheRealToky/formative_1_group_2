import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sla_tracker/data/models/enums.dart';
import 'package:sla_tracker/screens/sign_in_screen.dart';
import 'package:sla_tracker/widgets/priority_chip.dart';
import 'package:sla_tracker/widgets/status_chip.dart';

void main() {
  testWidgets('SignInScreen renders brand, inputs, and actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));

    expect(find.text('TASKTRACK'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('PriorityChip renders appropriate text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PriorityChip(priority: TaskPriority.high),
        ),
      ),
    );

    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('StatusChip renders appropriate status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusChip(status: TaskStatus.inProgress),
        ),
      ),
    );

    expect(find.text('In progress'), findsOneWidget);
  });
}
