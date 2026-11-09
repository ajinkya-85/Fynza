import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/services/currency_service.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_date_header.dart';

void main() {
  group('TransactionDateHeader Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('renders date title and positive net total', (tester) async {
      final now = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TransactionDateHeader(
                date: now,
                netAmountCents: 5000,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Today'), findsOneWidget);
      expect(find.text(r'+$50.00'), findsOneWidget);
    });

    testWidgets('renders negative net total formatted correctly', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TransactionDateHeader(
                date: yesterday,
                netAmountCents: -2550,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Yesterday'), findsOneWidget);
      expect(find.text(r'-$25.50'), findsOneWidget);
    });
  });
}
