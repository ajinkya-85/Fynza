import 'package:flutter_test/flutter_test.dart';
import 'package:fynza/features/auto_capture/data/services/capture_dedupe.dart';
import 'package:fynza/shared/models/transaction_type.dart';

void main() {
  group('CaptureDedupe Tests', () {
    test(
      'same reference and transaction details deduplicate across sources',
      () {
        final key1 = CaptureDedupe.computeKey(
          amountCents: 15000,
          type: TransactionType.expense,
          reference: 'UPI12345678',
          accountLast4: '1111',
          sender: 'SBI',
          rawText: 'Paid Rs 150 at Shop 1 on 10 Oct',
          notificationKey: 'sbi-notification',
          packageName: 'com.bank.sbi',
          postTime: 1000,
        );

        final key2 = CaptureDedupe.computeKey(
          amountCents: 15000,
          type: TransactionType.expense,
          reference: 'UPI12345678',
          accountLast4: '1111',
          sender: 'HDFC',
          rawText: 'Payment of Rs 150 completed at Shop 1 on 11 Oct',
          notificationKey: 'hdfc-notification',
          packageName: 'com.phonepe.app',
          postTime: 2000,
        );

        expect(key1, equals(key2));
      },
    );

    test('same reference with different amount or account stays distinct', () {
      final base = CaptureDedupe.computeKey(
        amountCents: 15000,
        type: TransactionType.expense,
        reference: 'UPI12345678',
        accountLast4: '1111',
        sender: 'SBI',
        rawText: 'Paid Rs 150',
        notificationKey: 'a',
        packageName: 'com.bank.sbi',
        postTime: 1000,
      );
      final differentAmount = CaptureDedupe.computeKey(
        amountCents: 25000,
        type: TransactionType.expense,
        reference: 'UPI12345678',
        accountLast4: '1111',
        sender: 'SBI',
        rawText: 'Paid Rs 250',
        notificationKey: 'b',
        packageName: 'com.bank.sbi',
        postTime: 2000,
      );
      final differentAccount = CaptureDedupe.computeKey(
        amountCents: 15000,
        type: TransactionType.expense,
        reference: 'UPI12345678',
        accountLast4: '2222',
        sender: 'SBI',
        rawText: 'Paid Rs 150',
        notificationKey: 'c',
        packageName: 'com.bank.sbi',
        postTime: 3000,
      );

      expect(differentAmount, isNot(base));
      expect(differentAccount, isNot(base));
    });

    test('different reference yields different dedupe key', () {
      final key1 = CaptureDedupe.computeKey(
        amountCents: 15000,
        type: TransactionType.expense,
        reference: 'UPI12345678',
        sender: 'SBI',
        rawText: 'Paid Rs 150',
        notificationKey: 'a',
        packageName: 'com.bank.sbi',
        postTime: 1000,
      );

      final key2 = CaptureDedupe.computeKey(
        amountCents: 15000,
        type: TransactionType.expense,
        reference: 'UPI87654321',
        sender: 'SBI',
        rawText: 'Paid Rs 150',
        notificationKey: 'b',
        packageName: 'com.bank.sbi',
        postTime: 1000,
      );

      expect(key1, isNot(equals(key2)));
    });

    test('without reference, exact source event creates deterministic key', () {
      final key1 = CaptureDedupe.computeKey(
        amountCents: 25000,
        type: TransactionType.expense,
        reference: null,
        accountLast4: '4321',
        sender: 'VM-HDFCBK',
        rawText: 'Spent Rs. 250.00 at Starbucks',
        notificationKey: 'event-1',
        packageName: 'com.google.android.apps.messaging',
        postTime: 12345,
      );

      final key2 = CaptureDedupe.computeKey(
        amountCents: 25000,
        type: TransactionType.expense,
        reference: null,
        accountLast4: '4321',
        sender: 'vm-hdfcbk',
        rawText: 'Spent Rs. 250.00 at Starbucks',
        notificationKey: 'event-1',
        packageName: 'com.google.android.apps.messaging',
        postTime: 12345,
      );

      expect(key1, equals(key2));

      final separatePayment = CaptureDedupe.computeKey(
        amountCents: 25000,
        type: TransactionType.expense,
        reference: null,
        accountLast4: '4321',
        sender: 'VM-HDFCBK',
        rawText: 'Spent Rs. 250.00 at Starbucks',
        notificationKey: 'event-2',
        packageName: 'com.google.android.apps.messaging',
        postTime: 12346,
      );
      expect(separatePayment, isNot(key1));
    });
  });
}
