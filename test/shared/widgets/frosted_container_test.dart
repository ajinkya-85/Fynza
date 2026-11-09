import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/shared/widgets/frosted_container.dart';

void main() {
  group('FrostedContainer Widget Tests', () {
    testWidgets('renders child with BackdropFilter and ClipRRect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrostedContainer(
              blur: 15.0,
              borderRadius: 12.0,
              child: Text('Frosted Glass'),
            ),
          ),
        ),
      );

      expect(find.text('Frosted Glass'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, BorderRadius.circular(12.0));
    });
  });
}

