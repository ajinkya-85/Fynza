import '../../shared/models/app_currency.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats an integer amount in cents using the given [AppCurrency].
  static String formatCents(int cents, [AppCurrency currency = AppCurrency.usd]) {
    return currency.format(cents);
  }

  /// Parses a user input string (e.g., "12.34", "$12.50", "12") to integer cents.
  /// Returns 0 if invalid.
  static int parseToCents(String input) {
    if (input.trim().isEmpty) return 0;
    final isNegative = input.contains('-');
    final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
    final parts = cleaned.split('.');
    if (parts.length > 2 || parts.first.isEmpty && parts.length == 1) {
      return 0;
    }
    final whole = int.tryParse(parts.first.isEmpty ? '0' : parts.first);
    if (whole == null) return 0;
    final fraction = parts.length == 2 ? parts[1] : '';
    if (fraction.length > 2 || (fraction.isNotEmpty && int.tryParse(fraction) == null)) {
      return 0;
    }
    final fractionalCents = int.tryParse(fraction.padRight(2, '0')) ?? 0;
    final cents = whole * 100 + fractionalCents;
    return isNegative ? -cents : cents;
  }

  /// Converts cents to a standard decimal string for text input (e.g. 1250 -> "12.50").
  static String centsToDecimalString(int cents) {
    if (cents == 0) return '';
    final absoluteCents = cents.abs();
    final formatted = '${absoluteCents ~/ 100}.${(absoluteCents % 100).toString().padLeft(2, '0')}';
    return cents.isNegative ? '-$formatted' : formatted;
  }
}
