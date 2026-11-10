import 'package:fynza/core/utils/currency_formatter.dart';
import 'package:fynza/shared/models/app_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats cents with the selected currency', () {
      expect(
        CurrencyFormatter.formatCents(123456, AppCurrency.inr),
        '₹ 1,234.56',
      );
      expect(CurrencyFormatter.formatCents(-50, AppCurrency.eur), '-€ 0.50');
      expect(
        CurrencyFormatter.formatCents(1250, AppCurrency.custom),
        '? 12.50',
      );
      expect(
        CurrencyFormatter.formatCents(12345678, AppCurrency.usd),
        r'$ 123,456.78',
      );
      expect(
        CurrencyFormatter.formatCents(-123456789, AppCurrency.usd),
        r'-$ 1,234,567.89',
      );
    });

    test('formats custom currency with spacing after the symbol', () {
      const currency = CustomCurrencyDetails(
        symbol: 'kr',
        code: 'SEK',
        name: 'Swedish krona',
      );

      expect(currency.format(12345678), 'kr 123,456.78');
    });

    test('parses decimal input without floating point conversion', () {
      expect(CurrencyFormatter.parseToCents('12.34'), 1234);
      expect(CurrencyFormatter.parseToCents('₹ 500'), 50000);
      expect(CurrencyFormatter.parseToCents('-0.50'), -50);
    });

    test('rejects invalid precision and malformed input', () {
      expect(CurrencyFormatter.parseToCents('12.345'), 0);
      expect(CurrencyFormatter.parseToCents('1.2.3'), 0);
      expect(CurrencyFormatter.parseToCents('amount'), 0);
    });
  });
}
