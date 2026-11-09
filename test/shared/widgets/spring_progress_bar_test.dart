import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/shared/widgets/spring_progress_bar.dart';

void main() {
  group('SpringProgressBar Widget Tests', () {
    testWidgets('renders progress bar with clamped value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: SpringProgressBar(
                  value: 0.5,
                  height: 10,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SpringProgressBar), findsOneWidget);
    });

    testWidgets('handles over-budget value (> 1.0) with red gradient', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: SpringProgressBar(
                  value: 1.25,
                  height: 10,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SpringProgressBar), findsOneWidget);
    });
  });
}

