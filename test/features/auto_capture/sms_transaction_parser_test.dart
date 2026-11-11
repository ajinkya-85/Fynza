import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynza/features/auto_capture/domain/models/parsed_transaction.dart';
import 'package:fynza/features/auto_capture/domain/parsing/sms_transaction_parser.dart';
import 'package:fynza/shared/models/transaction_type.dart';

void main() {
  group('SmsTransactionParser Tests', () {
    const parser = SmsTransactionParser();
    final now = DateTime(2024, 10, 10, 12, 0);

    group('Amount String to Cents Math (no double)', () {
      test('correctly parses integer and decimal strings', () {
        expect(
          SmsTransactionParser.parseAmountStringToCents('1,234.5'),
          123450,
        );
        expect(
          SmsTransactionParser.parseAmountStringToCents('5,00,000'),
          50000000,
        );
        expect(
          SmsTransactionParser.parseAmountStringToCents('5,00,000.00'),
          50000000,
        );
        expect(SmsTransactionParser.parseAmountStringToCents('0.99'), 99);
        expect(SmsTransactionParser.parseAmountStringToCents('45'), 4500);
        expect(SmsTransactionParser.parseAmountStringToCents('10.5'), 1050);
        expect(SmsTransactionParser.parseAmountStringToCents('10.05'), 1005);
        expect(SmsTransactionParser.parseAmountStringToCents(''), isNull);
        expect(SmsTransactionParser.parseAmountStringToCents('abc'), isNull);
      });
    });

    group('Table-driven fixture test suite (sms_samples.txt)', () {
      test('evaluates all test samples in fixture file', () {
        final fixtureFile = File('test/fixtures/sms_samples.txt');
        expect(
          fixtureFile.existsSync(),
          isTrue,
          reason: 'Fixture file test/fixtures/sms_samples.txt must exist',
        );

        final lines = fixtureFile.readAsLinesSync();
        int testedCount = 0;

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

          final json = jsonDecode(trimmed) as Map<String, dynamic>;
          final text = json['text'] as String;
          final expected = json['expected'] as String;

          final result = parser.parse(text, now);

          if (expected == 'parsed') {
            expect(
              result,
              isA<ParsedTransaction>(),
              reason: 'Expected "$text" to parse successfully',
            );

            final parsed = result as ParsedTransaction;
            final expectedAmount = json['amountCents'] as int;
            final expectedType = json['type'] == 'expense'
                ? TransactionType.expense
                : TransactionType.income;

            expect(
              parsed.amountCents,
              expectedAmount,
              reason: 'Amount mismatch for: $text',
            );
            expect(
              parsed.type,
              expectedType,
              reason: 'TransactionType mismatch for: $text',
            );

            if (json.containsKey('ref')) {
              expect(
                parsed.reference,
                json['ref'],
                reason: 'Reference mismatch for: $text',
              );
            }
            if (json.containsKey('acc')) {
              expect(
                parsed.accountLast4,
                json['acc'],
                reason: 'Account last 4 mismatch for: $text',
              );
            }
            if (json.containsKey('isHigh')) {
              final expectedConfidence = json['isHigh'] == true
                  ? ParseConfidence.high
                  : ParseConfidence.medium;
              expect(
                parsed.confidence,
                expectedConfidence,
                reason: 'Confidence mismatch for: $text',
              );
            }
          } else {
            expect(
              result,
              isA<NotATransaction>(),
              reason: 'Expected "$text" to be rejected',
            );
          }

          testedCount++;
        }

        expect(
          testedCount,
          greaterThanOrEqualTo(25),
          reason: 'Must test at least 25 fixture cases',
        );
      });
    });
  });
}
