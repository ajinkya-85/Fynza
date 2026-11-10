enum AppCurrency {
  usd(symbol: r'$', code: 'USD', name: 'US Dollar'),
  inr(symbol: '₹', code: 'INR', name: 'Indian Rupee'),
  eur(symbol: '€', code: 'EUR', name: 'Euro'),
  gbp(symbol: '£', code: 'GBP', name: 'British Pound'),
  jpy(symbol: '¥', code: 'JPY', name: 'Japanese Yen'),
  cad(symbol: r'C$', code: 'CAD', name: 'Canadian Dollar'),
  aud(symbol: r'A$', code: 'AUD', name: 'Australian Dollar'),
  sgd(symbol: r'S$', code: 'SGD', name: 'Singapore Dollar'),
  custom(symbol: '?', code: 'CUSTOM', name: 'Custom Currency');

  const AppCurrency({
    required this.symbol,
    required this.code,
    required this.name,
  });

  final String symbol;
  final String code;
  final String name;

  String format(int cents) {
    final absoluteCents = cents.abs();
    final wholeAmount = absoluteCents ~/ 100;
    final fractionalAmount = (absoluteCents % 100).toString().padLeft(2, '0');
    final formatted =
        '$symbol ${_formatWholeAmount(wholeAmount, indian: this == AppCurrency.inr)}.$fractionalAmount';
    if (cents < 0) return '-$formatted';
    return formatted;
  }

  String get displayLabel =>
      this == AppCurrency.custom ? 'Other (Custom)' : '$symbol  $code – $name';

  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => AppCurrency.usd,
    );
  }
}

/// Holds the user-defined symbol/code/name when [AppCurrency.custom] is active.
class CustomCurrencyDetails {
  final String symbol;
  final String code;
  final String name;

  const CustomCurrencyDetails({
    required this.symbol,
    required this.code,
    required this.name,
  });

  String format(int cents) {
    final abs = cents.abs();
    final whole = abs ~/ 100;
    final frac = (abs % 100).toString().padLeft(2, '0');
    final formatted = '$symbol ${_formatWholeAmount(whole)}.$frac';
    return cents < 0 ? '-$formatted' : formatted;
  }
}

String _formatWholeAmount(int amount, {bool indian = false}) {
  final digits = amount.toString();
  if (!indian || digits.length <= 3) {
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  final lastThreeDigits = digits.substring(digits.length - 3);
  var leadingDigits = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (leadingDigits.length > 2) {
    groups.insert(0, leadingDigits.substring(leadingDigits.length - 2));
    leadingDigits = leadingDigits.substring(0, leadingDigits.length - 2);
  }
  groups.insert(0, leadingDigits);

  return '${groups.join(',')},$lastThreeDigits';
}
