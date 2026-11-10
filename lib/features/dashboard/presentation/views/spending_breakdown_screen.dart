import 'package:flutter/material.dart';

import '../../../../shared/models/category_spending.dart';
import '../widgets/spending_pie_chart.dart';

class SpendingBreakdownScreen extends StatelessWidget {
  final List<CategorySpending> spendings;
  final int totalExpenseCents;

  const SpendingBreakdownScreen({
    super.key,
    required this.spendings,
    required this.totalExpenseCents,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spending Overview')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SpendingPieChart(
          spendings: spendings,
          totalExpenseCents: totalExpenseCents,
        ),
      ),
    );
  }
}
