import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

/// An Apple-style date section header displaying the friendly date title
/// and the aggregated net total for that day.
class TransactionDateHeader extends ConsumerWidget {
  final DateTime date;
  final int netAmountCents;

  const TransactionDateHeader({
    super.key,
    required this.date,
    required this.netAmountCents,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(selectedCurrencyProvider);

    final isPositive = netAmountCents > 0;
    final isNegative = netAmountCents < 0;

    final totalColor = isPositive
        ? const Color(0xFF2E7A7D)
        : (isNegative
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant);

    final prefix = isPositive ? '+' : (isNegative ? '-' : '');

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormatter.groupHeader(date),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
            ),
          ),
          if (netAmountCents != 0)
            Text(
              '$prefix${CurrencyFormatter.formatCents(netAmountCents.abs(), currency)}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: totalColor,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
        ],
      ),
    );
  }
}

