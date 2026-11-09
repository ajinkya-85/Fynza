import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/shared/widgets/pressable_scale.dart';

void main() {
  group('PressableScale Widget Tests', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PressableScale(
              child: Text('Press Me'),
            ),
          ),
        ),
      );

      expect(find.text('Press Me'), findsOneWidget);
    });

    testWidgets('fires onPressed callback on tap release', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressableScale(
              onPressed: () => pressed = true,
              child: const Text('Tap Target'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Target'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('scales down on tap down and rebounds on tap up', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressableScale(
              targetScale: 0.95,
              onPressed: () {},
              child: const SizedBox(
                width: 100,
                height: 100,
                child: Text('Box'),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Box')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final state = tester.state<PressableScaleState>(find.byType(PressableScale));
      expect(state.scaleAnimation.value, lessThan(1.0));

      // Release gesture
      await gesture.up();
      await tester.pumpAndSettle();

      expect(state.scaleAnimation.value, closeTo(1.0, 0.001));
    });

    testWidgets('cancels press when gesture is cancelled', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressableScale(
              onPressed: () => pressed = true,
              child: const Text('Cancel Target'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Cancel Target')));
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(pressed, isFalse);
    });
  });
}
