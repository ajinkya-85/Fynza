import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynza/features/categories/presentation/views/category_form_screen.dart';

void main() {
  group('CategoryFormScreen Widget Tests', () {
    testWidgets('renders all category form elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryFormScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Category'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Category Name'), findsOneWidget);
      expect(find.text('Select Icon'), findsOneWidget);
      expect(find.text('Select Color'), findsOneWidget);
      expect(find.text('Save Category'), findsOneWidget);
    });

    testWidgets('entering name and tapping save pops result', (tester) async {
      CategoryFormData? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<CategoryFormData>(
                    MaterialPageRoute(
                      builder: (_) => const CategoryFormScreen(),
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Subscriptions');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Category'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Subscriptions');
      expect(result!.isIncome, isFalse);
    });
  });
}

