import 'package:flutter_test/flutter_test.dart';
import 'package:fynza/features/auto_capture/data/services/capture_dedupe.dart';
import 'package:fynza/shared/models/transaction_type.dart';

void main() {
  group('CaptureDedupe Tests', () {
    test('same reference yields identical dedupe key regardless of other fields', () {
      final key1 = CaptureDedupe.computeKey(
        amountCents: 15000,
        type: TransactionType.expense,
        reference: 'UPI12345678',
        accountLast4: '1111',
        sender: 'SBI',
        rawText: 'Paid Rs 150 at Shop 1 on 10 Oct',
      );

      final key2 = CaptureDedupe.computeKey(
        amountCents: 15000,
        type: TransactionType.expense,
        reference: 'UPI12345678',
        accountLast4: '9999',
        sender: 'HDFC',
        rawText: 'Payment of Rs 150 completed at Shop 1 on 11 Oct',
      );

      expect(key1, equals(key2));
    });

    test('different reference yields different dedupe key', () {
      final key1 = CaptureDedupe.computeKey(
        amountCents: 15000,
        type: TransactionType.expense,
        reference: 'UPI12345678',
        sender: 'SBI',
        rawText: 'Paid Rs 150',
      );

      final key2 = CaptureDedupe.computeKey(
        amountCents: 15000,
        type: TransactionType.expense,
        reference: 'UPI87654321',
        sender: 'SBI',
        rawText: 'Paid Rs 150',
      );

      expect(key1, isNot(equals(key2)));
    });

    test('without reference, normalized text + amount + sender creates deterministic key', () {
      final key1 = CaptureDedupe.computeKey(
        amountCents: 25000,
        type: TransactionType.expense,
        reference: null,
        accountLast4: '4321',
        sender: 'VM-HDFCBK',
        rawText: 'Spent Rs. 250.00 at Starbucks',
      );

      final key2 = CaptureDedupe.computeKey(
        amountCents: 25000,
        type: TransactionType.expense,
        reference: null,
        accountLast4: '4321',
        sender: 'vm-hdfcbk',
        rawText: 'Spent Rs 25000 at Starbucks', // stripped punctuation matches
      );

      expect(key1, equals(key2));
    });
  });
}
