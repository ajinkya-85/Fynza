import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/backup/data/models/backup_dto.dart';
import 'package:expense_tracker/features/backup/data/services/backup_serializer.dart';
import 'package:expense_tracker/features/backup/domain/models/backup_failure.dart';

void main() {
  group('BackupSerializer Tests', () {
    late BackupSerializer serializer;

    setUp(() {
      serializer = BackupSerializer();
    });

    final sampleEnvelope = BackupEnvelopeDto(
      formatVersion: 1,
      appVersion: '1.0.0',
      dbSchemaVersion: 1,
      createdAt: 1700000000000,
      data: BackupDataDto(
        categories: [
          const CategoryDto(id: 1, name: 'Food', icon: 'restaurant', color: 0xFF0000, isIncome: false),
        ],
        transactions: [
          const TransactionDto(id: 10, amount: 2500, type: 'expense', categoryId: 1, date: 1700000000000, note: 'Lunch', createdAt: 1700000000000),
        ],
        budgets: [
          const BudgetDto(id: 100, categoryId: 1, amountLimit: 50000, month: 10, year: 2026),
        ],
        preferences: {'currency_code': 'USD'},
      ),
    );

    test('Encodes to valid gzipped bytes and decodes back to map', () {
      final bytes = serializer.encode(sampleEnvelope);
      expect(bytes.length, greaterThan(2));
      expect(bytes[0], 0x1F);
      expect(bytes[1], 0x8B);

      final decoded = serializer.decode(bytes);
      expect(decoded['formatVersion'], 1);
      expect(decoded['appVersion'], '1.0.0');
      expect(decoded['data']['categories'].length, 1);
      expect(decoded['data']['transactions'].length, 1);
      expect(decoded['data']['budgets'].length, 1);
    });

    test('Throws InvalidFileFailure for empty or short bytes', () {
      expect(() => serializer.decode(Uint8List(0)), throwsA(isA<InvalidFileFailure>()));
      expect(() => serializer.decode(Uint8List.fromList([0x1F])), throwsA(isA<InvalidFileFailure>()));
    });

    test('Throws InvalidFileFailure for non-gzip magic bytes', () {
      final nonGzip = utf8.encode('{"formatVersion": 1}');
      expect(() => serializer.decode(Uint8List.fromList(nonGzip)), throwsA(isA<InvalidFileFailure>()));
    });

    test('Throws InvalidFileFailure for truncated or corrupted gzip', () {
      final bytes = serializer.encode(sampleEnvelope);
      final corrupted = Uint8List.fromList(bytes.sublist(0, bytes.length - 10));
      expect(() => serializer.decode(corrupted), throwsA(isA<InvalidFileFailure>()));
    });

    test('Throws InvalidFileFailure for valid gzip containing non-JSON', () {
      final invalidJsonGzip = gzip.encode(utf8.encode('not a json string'));
      expect(() => serializer.decode(Uint8List.fromList(invalidJsonGzip)), throwsA(isA<InvalidFileFailure>()));
    });
  });
}
