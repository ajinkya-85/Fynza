import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fynza/core/services/currency_service.dart';
import 'package:fynza/features/budget/presentation/widgets/budget_form_dialog.dart';
import 'package:fynza/features/categories/domain/models/category.dart';
import 'package:fynza/shared/models/transaction_type.dart';
import 'package:fynza/features/transactions/presentation/view_models/transaction_form_notifier.dart';

void main() {
  testWidgets('shows recent budget categories with expandable search', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const categoryNames = ['Bills', 'Groceries', 'Transport', 'Dining'];

    final categories = List.generate(
      categoryNames.length,
      (index) => Category(
        id: index + 1,
        name: categoryNames[index],
        icon: 'restaurant',
        color: 0xFFE65100,
        isIncome: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          recentTransactionCategoriesProvider(
            TransactionType.expense,
          ).overrideWith((ref) => Stream.value([4, 3, 2])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      BudgetFormDialog(availableCategories: categories),
                ),
                child: const Text('Open budget'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open budget'));
    await tester.pumpAndSettle();

    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Bills'), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    final moreButton = find.text('More (1)');
    await tester.ensureVisible(moreButton);
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('budget_category_search_field')),
      findsOneWidget,
    );
    expect(find.text('Bills'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('budget_category_search_field')),
      'Bills',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(Wrap).last, matching: find.text('Bills')),
      findsOneWidget,
    );
    expect(find.text('Groceries'), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(Wrap).last, matching: find.text('Bills')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('budget_category_search_field')), findsNothing);
    expect(
      find.descendant(
        of: find.byType(Wrap).first,
        matching: find.text('Bills'),
      ),
      findsOneWidget,
    );
    expect(find.text('Dining'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
