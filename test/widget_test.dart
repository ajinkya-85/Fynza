import 'package:drift/native.dart';
import 'package:expense_tracker/core/di/database_provider.dart';
import 'package:expense_tracker/core/services/currency_service.dart';
import 'package:expense_tracker/data/db/app_database.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders main scaffold and switches navigation tabs',
      (tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ExpenseTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Dashboard tab is displayed initially
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Net Balance'), findsOneWidget);

    // Switch to Transactions tab
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Transactions'), findsWidgets);

    // Switch to Budgets tab
    await tester.tap(find.byIcon(Icons.pie_chart_outline));
    await tester.pumpAndSettle();

    expect(find.text('Budgets'), findsWidgets);

    // Switch to Categories tab
    await tester.tap(find.byIcon(Icons.category_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Categories'), findsWidgets);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);

    await testDb.close();
  });

  testWidgets('Clicking floating action button opens TransactionFormScreen',
      (tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ExpenseTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();

    expect(find.text('New Transaction'), findsOneWidget);

    await testDb.close();
  });

  testWidgets('Capture Inbox button is hidden when auto-capture is disabled',
      (tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ExpenseTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Capture Inbox button is NOT rendered on the dashboard
    expect(find.byTooltip('Capture Inbox'), findsNothing);

    await testDb.close();
  });
}
