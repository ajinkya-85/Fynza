import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker/core/services/currency_service.dart';
import 'package:expense_tracker/data/db/app_database.dart';
import 'package:expense_tracker/features/backup/data/services/backup_file_service.dart';
import 'package:expense_tracker/features/backup/domain/models/backup_failure.dart';
import 'package:expense_tracker/features/backup/domain/repositories/backup_repository.dart';
import 'package:expense_tracker/shared/models/app_currency.dart';
import 'package:expense_tracker/shared/models/transaction_type.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('BackupRepository Tests', () {
    late AppDatabase db;
    late CurrencyService currencyService;
    late Directory tempDir;
    late BackupFileService fileService;
    late BackupRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      currencyService = CurrencyService(prefs);
      db = AppDatabase.forTesting(NativeDatabase.memory());
      tempDir = await Directory.systemTemp.createTemp('backup_repo_test_');
      fileService = BackupFileService(customBaseDir: tempDir);
      repository = BackupRepositoryImpl(
        db,
        currencyService,
        fileService: fileService,
      );
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Full Round-Trip: Creates backup and restores into a fresh database with identical data', () async {
      // 1. Insert custom category, transactions (including unicode and null notes), budget
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Gaming 🎮',
              icon: 'sports_esports',
              color: 0xFF123456,
              isIncome: const Value(false),
            ),
          );

      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              amount: 5999,
              type: TransactionType.expense,
              categoryId: catId,
              date: DateTime.utc(2026, 10, 10, 12, 0),
              note: const Value('Steam sale purchase 🚀'),
            ),
          );

      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              amount: 0,
              type: TransactionType.income,
              categoryId: catId,
              date: DateTime.utc(2026, 10, 10, 14, 0),
              note: const Value(null),
            ),
          );

      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              categoryId: catId,
              amountLimit: 10000,
              month: 10,
              year: 2026,
            ),
          );

      await currencyService.setCurrency(AppCurrency.eur);

      // 2. Create backup bytes
      final backupBytes = await repository.createBackupBytes();
      expect(backupBytes, isNotEmpty);

      // 3. Inspect backup summary
      final summary = await repository.inspectBackup(backupBytes);
      expect(summary.formatVersion, 1);
      // DB has default 12 categories + 1 custom = 13
      expect(summary.categoryCount, 13);
      expect(summary.transactionCount, 2);
      expect(summary.budgetCount, 1);

      // 4. Restore into a fresh in-memory database
      final freshDb = AppDatabase.forTesting(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({});
      final freshPrefs = await SharedPreferences.getInstance();
      final freshCurrencyService = CurrencyService(freshPrefs);
      final freshRepo = BackupRepositoryImpl(
        freshDb,
        freshCurrencyService,
        fileService: BackupFileService(customBaseDir: tempDir),
      );

      await freshRepo.restoreBackup(backupBytes, currencyService: freshCurrencyService);

      // 5. Verify restored data
      final restoredCats = await freshDb.select(freshDb.categories).get();
      final restoredTxs = await freshDb.select(freshDb.transactions).get();
      final restoredBudgets = await freshDb.select(freshDb.budgets).get();

      expect(restoredCats.length, 13);
      expect(restoredCats.any((c) => c.name == 'Gaming 🎮' && c.color == 0xFF123456), isTrue);

      expect(restoredTxs.length, 2);
      final tx1 = restoredTxs.firstWhere((t) => t.amount == 5999);
      expect(tx1.note, 'Steam sale purchase 🚀');
      expect(tx1.categoryId, catId);

      final tx2 = restoredTxs.firstWhere((t) => t.amount == 0);
      expect(tx2.note, isNull);

      expect(restoredBudgets.length, 1);
      expect(restoredBudgets.first.amountLimit, 10000);
      expect(freshCurrencyService.getCurrency(), AppCurrency.eur);

      // 6. Test ID collision safety on fresh insert after restore
      final newCatId = await freshDb.into(freshDb.categories).insert(
            CategoriesCompanion.insert(
              name: 'New Post-Restore Category',
              icon: 'star',
              color: 0xFFFFFFFF,
            ),
          );
      expect(newCatId, greaterThan(0));
      expect(restoredCats.any((c) => c.id == newCatId), isFalse);

      await freshDb.close();
    });

    test('Restore fails validation and leaves current database completely untouched', () async {
      final initialCategories = await db.select(db.categories).get();
      final initialCount = initialCategories.length;

      // Invalid bytes (not gzip)
      final invalidBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      expect(
        () => repository.restoreBackup(invalidBytes, currencyService: currencyService),
        throwsA(isA<InvalidFileFailure>()),
      );

      // Ensure database was not changed
      final postCheckCategories = await db.select(db.categories).get();
      expect(postCheckCategories.length, initialCount);
    });

    test('Creates safety backup before restoring', () async {
      final backupBytes = await repository.createBackupBytes();
      await repository.restoreBackup(backupBytes, currencyService: currencyService);

      final preDir = await fileService.getPreRestoreDirectory();
      final preFiles = await preDir.list().toList();
      expect(preFiles.any((f) => f.path.contains('pre_restore_')), isTrue);
    });
  });
}
