import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fynza/core/services/currency_service.dart';
import 'package:fynza/features/categories/domain/models/category.dart';
import 'package:fynza/features/dashboard/presentation/views/spending_breakdown_screen.dart';
import 'package:fynza/features/dashboard/presentation/widgets/spending_pie_chart.dart';
import 'package:fynza/shared/models/category_spending.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  final spendings = [
    CategorySpending(
      category: const Category(
        id: 1,
        name: 'Food',
        icon: 'restaurant',
        color: 0xFFF49E8C,
        isIncome: false,
      ),
      totalCents: 7250,
      transactionCount: 3,
    ),
    CategorySpending(
      category: const Category(
        id: 2,
        name: 'Transport',
        icon: 'directions_car',
        color: 0xFF7DBCE6,
        isIncome: false,
      ),
      totalCents: 2750,
      transactionCount: 2,
    ),
  ];

  Widget app(Widget child) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('overview Detail action opens the full breakdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        SpendingOverviewCard(
          spendings: spendings,
          totalExpenseCents: 10000,
          onDetails: () {
            Navigator.of(tester.element(find.text('Spending Overview'))).push(
              MaterialPageRoute<void>(
                builder: (_) => SpendingBreakdownScreen(
                  spendings: spendings,
                  totalExpenseCents: 10000,
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spending Overview'), findsOneWidget);
    await tester.tap(find.text('Detail'));
    await tester.pumpAndSettle();

    expect(find.text('Spending Breakdown'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Total Spent'), findsOneWidget);
  });

  testWidgets('breakdown chart and legend do not respond to taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(SpendingPieChart(spendings: spendings, totalExpenseCents: 10000)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reset'), findsNothing);
    expect(find.text('Total Spent'), findsOneWidget);
    await tester.tap(find.text('Food'));
    await tester.tapAt(tester.getCenter(find.text('Total Spent')));
    await tester.pumpAndSettle();

    expect(find.text('Total Spent'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);
  });
}
