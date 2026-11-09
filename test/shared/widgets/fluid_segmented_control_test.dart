import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/shared/widgets/fluid_segmented_control.dart';

void main() {
  group('FluidSegmentedControl Widget Tests', () {
    testWidgets('renders all segment labels and icons', (tester) async {
      final items = ['All', 'Expenses', 'Income'];
      String selected = 'All';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluidSegmentedControl<String>(
              items: items,
              selectedItem: selected,
              onSelectedItemChanged: (val) => selected = val,
              labelBuilder: (item) => item,
              iconBuilder: (item) => item == 'Expenses'
                  ? Icons.arrow_upward
                  : (item == 'Income' ? Icons.arrow_downward : null),
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('tapping unselected item triggers onSelectedItemChanged', (tester) async {
      final items = ['All', 'Expenses', 'Income'];
      String selected = 'All';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FluidSegmentedControl<String>(
                  items: items,
                  selectedItem: selected,
                  onSelectedItemChanged: (val) {
                    setState(() {
                      selected = val;
                    });
                  },
                  labelBuilder: (item) => item,
                );
              },
            ),
          ),
        ),
      );

      expect(selected, 'All');

      // Tap 'Expenses'
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      expect(selected, 'Expenses');
    });
  });
}

