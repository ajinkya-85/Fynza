import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/shared/models/app_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats cents with the selected currency', () {
      expect(CurrencyFormatter.formatCents(123456, AppCurrency.inr), '₹1234.56');
      expect(CurrencyFormatter.formatCents(-50, AppCurrency.eur), '-€0.50');
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
