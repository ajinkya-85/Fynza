import 'package:flutter_test/flutter_test.dart';
import 'package:fynza/features/backup/data/services/backup_validator.dart';
import 'package:fynza/features/backup/domain/models/backup_failure.dart';

void main() {
  group('BackupValidator Tests', () {
    late BackupValidator validator;

    setUp(() {
      validator = BackupValidator();
    });

    Map<String, dynamic> createValidMap() {
      return {
        'formatVersion': 1,
        'appVersion': '1.0.0',
        'dbSchemaVersion': 1,
        'createdAt': 1700000000000,
        'data': {
          'categories': [
            {'id': 1, 'name': 'Groceries', 'icon': 'shopping_cart', 'color': 0xFF00FF00, 'isIncome': false},
            {'id': 2, 'name': 'Salary', 'icon': 'payments', 'color': 0xFF0000FF, 'isIncome': true},
          ],
          'transactions': [
            {'id': 101, 'amount': 5000, 'type': 'expense', 'categoryId': 1, 'date': 1700000000000, 'note': 'Food', 'createdAt': 1700000000000},
          ],
          'budgets': [
            {'id': 201, 'categoryId': 1, 'amountLimit': 20000, 'month': 10, 'year': 2026},
          ],
          'preferences': {'currency_code': 'USD'},
        },
      };
    }

    test('Validates successfully with valid map', () {
      final envelope = validator.validate(createValidMap());
      expect(envelope.formatVersion, 1);
      expect(envelope.data.categories.length, 2);
      expect(envelope.data.transactions.length, 1);
      expect(envelope.data.budgets.length, 1);
    });

    test('Throws UnsupportedVersionFailure on newer formatVersion', () {
      final map = createValidMap()..['formatVersion'] = 99;
      expect(() => validator.validate(map), throwsA(isA<UnsupportedVersionFailure>()));
    });

    test('Throws CorruptDataFailure on missing envelope fields', () {
      final map = createValidMap()..remove('createdAt');
      expect(() => validator.validate(map), throwsA(isA<CorruptDataFailure>()));
    });

    test('Throws CorruptDataFailure on missing data section', () {
      final map = createValidMap()..remove('data');
      expect(() => validator.validate(map), throwsA(isA<CorruptDataFailure>()));
    });

    test('Throws CorruptDataFailure on duplicate category IDs', () {
      final map = createValidMap();
      (map['data'] as Map<String, dynamic>)['categories'] = [
        {'id': 1, 'name': 'Cat 1', 'icon': 'icon', 'color': 0, 'isIncome': false},
        {'id': 1, 'name': 'Cat 2', 'icon': 'icon', 'color': 0, 'isIncome': false},
      ];
      expect(() => validator.validate(map), throwsA(isA<CorruptDataFailure>()));
    });

    test('Throws CorruptDataFailure on orphan transaction foreign key', () {
      final map = createValidMap();
      (map['data'] as Map<String, dynamic>)['transactions'] = [
        {'id': 101, 'amount': 100, 'type': 'expense', 'categoryId': 999, 'date': 1700000000000, 'createdAt': 1700000000000},
      ];
      expect(() => validator.validate(map), throwsA(isA<CorruptDataFailure>()));
    });

    test('Throws CorruptDataFailure on orphan budget foreign key', () {
      final map = createValidMap();
      (map['data'] as Map<String, dynamic>)['budgets'] = [
        {'id': 201, 'categoryId': 999, 'amountLimit': 1000, 'month': 10, 'year': 2026},
      ];
      expect(() => validator.validate(map), throwsA(isA<CorruptDataFailure>()));
    });

    test('Throws CorruptDataFailure on duplicate budget unique constraint', () {
      final map = createValidMap();
      (map['data'] as Map<String, dynamic>)['budgets'] = [
        {'id': 201, 'categoryId': 1, 'amountLimit': 1000, 'month': 10, 'year': 2026},
        {'id': 202, 'categoryId': 1, 'amountLimit': 2000, 'month': 10, 'year': 2026},
      ];
      expect(() => validator.validate(map), throwsA(isA<CorruptDataFailure>()));
    });

    test('Throws CorruptDataFailure on negative amounts or invalid months', () {
      final mapInvalidAmount = createValidMap();
      (mapInvalidAmount['data'] as Map<String, dynamic>)['transactions'] = [
        {'id': 101, 'amount': -500, 'type': 'expense', 'categoryId': 1, 'date': 1700000000000, 'createdAt': 1700000000000},
      ];
      expect(() => validator.validate(mapInvalidAmount), throwsA(isA<CorruptDataFailure>()));

      final mapInvalidMonth = createValidMap();
      (mapInvalidMonth['data'] as Map<String, dynamic>)['budgets'] = [
        {'id': 201, 'categoryId': 1, 'amountLimit': 1000, 'month': 13, 'year': 2026},
      ];
      expect(() => validator.validate(mapInvalidMonth), throwsA(isA<CorruptDataFailure>()));
    });
  });
}
