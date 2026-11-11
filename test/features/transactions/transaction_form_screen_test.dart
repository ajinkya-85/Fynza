import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fynza/core/di/database_provider.dart';
import 'package:fynza/core/services/currency_service.dart';
import 'package:fynza/data/db/app_database.dart';
import 'package:fynza/features/transactions/presentation/views/transaction_form_screen.dart';
import 'package:fynza/shared/models/transaction_type.dart';

void main() {
  group('TransactionFormScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('renders all form elements with optical typography', (
      tester,
    ) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: TransactionFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Transaction'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('+50'), findsOneWidget);
      expect(find.text('+100'), findsOneWidget);
      expect(find.text('+500'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Add Transaction'), findsOneWidget);

      await testDb.close();
      await tester.pump();
    });

    testWidgets('tapping quick amount chips increments the amount value', (
      tester,
    ) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: TransactionFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap +100
      await tester.tap(find.text('+100'));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.controller?.text, '100.00');

      // Tap +50
      await tester.tap(find.text('+50'));
      await tester.pumpAndSettle();

      expect(textField.controller?.text, '150.00');

      await testDb.close();
      await tester.pump();
    });

    testWidgets('switching between Expense and Income updates segment', (
      tester,
    ) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: TransactionFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Income
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(find.text('Income'), findsOneWidget);

      await testDb.close();
      await tester.pump();
    });

    testWidgets('prefilled income capture offers only income categories', (
      tester,
    ) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: TransactionFormScreen(
              prefilledAmountCents: 25000,
              prefilledType: TransactionType.income,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Food & Dining'), findsNothing);
      final moreButton = find.text('More (1)');
      await tester.ensureVisible(moreButton);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Food & Dining'), findsNothing);

      await testDb.close();
      await tester.pump();
    });

    testWidgets('shows three recent categories with searchable More list', (
      tester,
    ) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());
      final categories = await testDb.select(testDb.categories).get();
      final recentNames = [
        'Food & Dining',
        'Groceries',
        'Transport',
        'Entertainment',
      ];
      final now = DateTime.now();
      for (var index = 0; index < recentNames.length; index++) {
        final category = categories.firstWhere(
          (item) => item.name == recentNames[index],
        );
        await testDb
            .into(testDb.transactions)
            .insert(
              TransactionsCompanion.insert(
                amount: 1000 + index,
                type: TransactionType.expense,
                categoryId: category.id,
                date: now.add(Duration(days: index)),
              ),
            );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: TransactionFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entertainment'), findsOneWidget);
      expect(find.text('Food & Dining'), findsNothing);
      final moreButton = find.text('More (5)');
      await tester.ensureVisible(moreButton);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category_search_field')), findsOneWidget);
      expect(find.text('Food & Dining'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('category_search_field')),
        'Bills',
      );
      await tester.pumpAndSettle();

      expect(find.text('Bills & Utilities'), findsOneWidget);
      expect(find.text('Food & Dining'), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(Wrap).last,
          matching: find.text('Bills & Utilities'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category_search_field')), findsNothing);
      expect(find.text('Bills & Utilities'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);

      await testDb.close();
      await tester.pump();
    });
  });
}
