import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/currency_service.dart';
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
    final currency = ref.watch(selectedCurrencyProvider);
    final baseStyle = style ?? theme.textTheme.titleMedium;

    Color? textColor = baseStyle?.color;
    if (type != null) {
      if (type == TransactionType.income) {
        textColor = const Color.fromARGB(255, 46, 122, 125);
      } else {
        textColor = theme.colorScheme.error;
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
