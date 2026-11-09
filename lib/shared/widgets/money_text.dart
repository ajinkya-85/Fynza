import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/currency_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../models/transaction_type.dart';

class MoneyText extends ConsumerWidget {
  final int cents;
  final TextStyle? style;
  final TransactionType? type;
  final bool showSign;

  const MoneyText({
    super.key,
    required this.cents,
    this.style,
    this.type,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(selectedCurrencyProvider);
    final baseStyle = style ?? theme.textTheme.titleMedium;

    Color? textColor = baseStyle?.color;
    if (type != null) {
      if (type == TransactionType.income) {
        textColor = isDark ? const Color(0xFF81C784) : AppTheme.incomeAccent;
      } else {
        textColor = isDark ? const Color(0xFFFF8A80) : AppTheme.expenseAccent;
      }
    }

    String formatted = CurrencyFormatter.formatCents(cents, currency);
    if (showSign && type != null) {
      if (type == TransactionType.income) {
        formatted = '+$formatted';
      } else if (type == TransactionType.expense) {
        formatted = '-$formatted';
      }
    }

    return Text(formatted, style: baseStyle?.copyWith(color: textColor));
  }
}
