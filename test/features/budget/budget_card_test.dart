import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fynza/core/services/currency_service.dart';
import 'package:fynza/features/budget/domain/models/budget.dart';
import 'package:fynza/features/categories/domain/models/category.dart';
import 'package:fynza/features/budget/presentation/widgets/budget_card.dart';
import 'package:fynza/shared/models/budget_overview.dart';

void main() {
  group('BudgetCard Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('renders budget info, category name, and progress status', (
      tester,
    ) async {
      final category = Category(
        id: 1,
        name: 'Dining',
        icon: 'restaurant',
        color: 0xFFE65100,
        isIncome: false,
      );
      final budget = Budget(
        id: 1,
        categoryId: 1,
        month: 11,
        year: 2026,
        amountLimit: 10000, // $100.00
      );
      final overview = BudgetOverview(
        budget: budget,
        category: category,
        spentCents: 4500, // $45.00
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(body: BudgetCard(overview: overview)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dining'), findsOneWidget);
      expect(find.text(r'Spent: $45.00'), findsOneWidget);
      expect(find.text(r'Limit: $100.00'), findsOneWidget);
      expect(find.text(r'$55.00 remaining'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('renders over budget status badge when spent exceeds limit', (
      tester,
    ) async {
      final category = Category(
        id: 1,
        name: 'Groceries',
        icon: 'shopping_cart',
        color: 0xFF2E7D32,
        isIncome: false,
      );
      final budget = Budget(
        id: 2,
        categoryId: 1,
        month: 11,
        year: 2026,
        amountLimit: 5000, // $50.00
      );
      final overview = BudgetOverview(
        budget: budget,
        category: category,
        spentCents: 6500, // $65.00
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(body: BudgetCard(overview: overview)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Over Limit'), findsOneWidget);
      expect(find.textContaining('Over budget by'), findsOneWidget);
    });
  });
}
