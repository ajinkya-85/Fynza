import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_search_bar.dart';

void main() {
  group('TransactionSearchBar Widget Tests', () {
    testWidgets('renders search icon and placeholder text', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionSearchBar(
              controller: controller,
              onChanged: (_) {},
              onClear: () {},
              hintText: 'Search here...',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('Search here...'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
    });

    testWidgets('shows clear button when text is entered and clears on tap', (tester) async {
      final controller = TextEditingController();
      String query = '';
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionSearchBar(
              controller: controller,
              onChanged: (val) => query = val,
              onClear: () {
                cleared = true;
                controller.clear();
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Groceries');
      await tester.pump();

      expect(query, 'Groceries');
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pump();

      expect(cleared, isTrue);
      expect(controller.text, isEmpty);
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
    });
  });
}

