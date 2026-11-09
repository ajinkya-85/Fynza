import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fynza/core/di/database_provider.dart';
import 'package:fynza/core/services/currency_service.dart';
import 'package:fynza/data/db/app_database.dart';
import 'package:fynza/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
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
        child: const FynzaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Dashboard tab is displayed initially
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Net Balance'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);

    // Scroll to Budgets card from dashboard and tap it
    await tester.ensureVisible(find.text('Budgets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();

    expect(find.text('No Budgets Set'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Scroll to Categories card from dashboard and tap it
    await tester.ensureVisible(find.text('Categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Switch to Transactions tab via NavigationBar
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.receipt_long_outlined),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transactions'), findsWidgets);

    // Switch to Settings tab via NavigationBar
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.settings_outlined),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);

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
        child: const FynzaApp(),
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
        child: const FynzaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Capture Inbox button is NOT rendered on the dashboard
    expect(find.byTooltip('Capture Inbox'), findsNothing);

    await testDb.close();
  });
}
