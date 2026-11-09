import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/di/database_provider.dart';
import 'package:expense_tracker/core/services/currency_service.dart';
import 'package:expense_tracker/data/db/app_database.dart';
import 'package:expense_tracker/features/transactions/presentation/views/transaction_form_screen.dart';

void main() {
  group('TransactionFormScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('renders all form elements with optical typography', (tester) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: TransactionFormScreen(),
          ),
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

    testWidgets('tapping quick amount chips increments the amount value', (tester) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: TransactionFormScreen(),
          ),
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

    testWidgets('switching between Expense and Income updates segment', (tester) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: TransactionFormScreen(),
          ),
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
  });
}
