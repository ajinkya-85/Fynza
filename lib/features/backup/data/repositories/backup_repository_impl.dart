import 'dart:io';
import 'package:drift/drift.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../data/db/app_database.dart';
import '../../../../shared/models/app_currency.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../auto_capture/domain/models/capture_status.dart';
import '../../data/models/backup_dto.dart';
import '../../data/services/backup_file_service.dart';
import '../../data/services/backup_migrator.dart';
import '../../data/services/backup_serializer.dart';
import '../../data/services/backup_validator.dart';
import '../../domain/models/backup_failure.dart';
import '../../domain/models/backup_file_info.dart';
import '../../domain/models/backup_summary.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  final AppDatabase _database;
  final BackupSerializer _serializer;
  final BackupValidator _validator;
  final BackupMigrator _migrator;
  final BackupFileService _fileService;
  final CurrencyService _currencyService;

  BackupRepositoryImpl(
    this._database,
    this._currencyService, {
    BackupSerializer? serializer,
    BackupValidator? validator,
    BackupMigrator? migrator,
    BackupFileService? fileService,
  }) : _serializer = serializer ?? BackupSerializer(),
       _validator = validator ?? BackupValidator(),
       _migrator = migrator ?? BackupMigrator(),
       _fileService = fileService ?? BackupFileService();

  @override
  Future<BackupSummary> inspectBackup(Uint8List bytes) async {
    final rawMap = _serializer.decode(bytes);
    final migratedMap = _migrator.migrate(rawMap);
    final envelope = _validator.validate(migratedMap);

    return BackupSummary(
      formatVersion: envelope.formatVersion,
      appVersion: envelope.appVersion,
      dbSchemaVersion: envelope.dbSchemaVersion,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        envelope.createdAt,
        isUtc: true,
      ),
      categoryCount: envelope.data.categories.length,
      transactionCount: envelope.data.transactions.length,
      budgetCount: envelope.data.budgets.length,
    );
  }

  @override
  Future<Uint8List> createBackupBytes({String appVersion = '1.0.0'}) async {
    // 1. Read all tables inside ONE atomic transaction for consistent snapshot
    late List<Category> allCategories;
    late List<Transaction> allTransactions;
    late List<Budget> allBudgets;
    late List<CapturedTransaction> allCaptures;

    await _database.transaction(() async {
      allCategories = await _database.select(_database.categories).get();
      allTransactions = await _database.select(_database.transactions).get();
      allBudgets = await _database.select(_database.budgets).get();
      allCaptures = await _database
          .select(_database.capturedTransactions)
          .get();
    });

    // 2. Read whitelisted preferences
    final currency = _currencyService.getCurrency();
    final customDetails = _currencyService.getCustomDetails();

    final preferences = <String, dynamic>{
      'currency_code': currency.code,
      if (customDetails != null)
        'custom_currency': {
          'symbol': customDetails.symbol,
          'code': customDetails.code,
          'name': customDetails.name,
        },
    };

    // 3. Map to DTOs
    final categoryDtos = allCategories
        .map(
          (c) => CategoryDto(
            id: c.id,
            name: c.name,
            icon: c.icon,
            color: c.color,
            isIncome: c.isIncome,
          ),
        )
        .toList();

    final transactionDtos = allTransactions
        .map(
          (t) => TransactionDto(
            id: t.id,
            amount: t.amount,
            type: t.type.name,
            categoryId: t.categoryId,
            date: t.date.millisecondsSinceEpoch,
            note: t.note,
            createdAt: t.createdAt.millisecondsSinceEpoch,
          ),
        )
        .toList();

    final budgetDtos = allBudgets
        .map(
          (b) => BudgetDto(
            id: b.id,
            categoryId: b.categoryId,
            amountLimit: b.amountLimit,
            month: b.month,
            year: b.year,
          ),
        )
        .toList();

    final captureDtos = allCaptures
        .map(
          (ct) => CapturedTransactionDto(
            id: ct.id,
            amountCents: ct.amountCents,
            type: ct.type.name,
            counterparty: ct.counterparty,
            accountLast4: ct.accountLast4,
            reference: ct.reference,
            occurredAt: ct.occurredAt.millisecondsSinceEpoch,
            capturedAt: ct.capturedAt.millisecondsSinceEpoch,
            sourcePackage: ct.sourcePackage,
            sender: ct.sender,
            dedupeKey: ct.dedupeKey,
            status: ct.status.name,
            duplicateCount: ct.duplicateCount,
            transactionId: ct.transactionId,
            suggestedCategoryId: ct.suggestedCategoryId,
          ),
        )
        .toList();

    final envelope = BackupEnvelopeDto(
      formatVersion: BackupSerializer.currentFormatVersion,
      appVersion: appVersion,
      dbSchemaVersion: _database.schemaVersion,
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      data: BackupDataDto(
        categories: categoryDtos,
        transactions: transactionDtos,
        budgets: budgetDtos,
        preferences: preferences,
        capturedTransactions: captureDtos,
      ),
    );

    return _serializer.encode(envelope);
  }

  @override
  Future<void> createAutoBackup({String appVersion = '1.0.0'}) async {
    final bytes = await createBackupBytes(appVersion: appVersion);
    await _fileService.saveAutoBackup(bytes);
  }

  @override
  Future<void> restoreBackup(Uint8List bytes) async {
    // 1. Decode & Migrate
    final rawMap = _serializer.decode(bytes);
    final migratedMap = _migrator.migrate(rawMap);

    // 2. Strict Validation (DB remains untouched on any failure)
    final envelope = _validator.validate(migratedMap);

    // 3. Create Safety Copy before touching database
    try {
      final currentBytes = await createBackupBytes();
      await _fileService.savePreRestoreBackup(currentBytes);
    } catch (e) {
      throw StorageErrorFailure(
        'Failed to create pre-restore safety backup: $e',
      );
    }

    // 4. Apply atomically in ONE transaction
    await _database.transaction(() async {
      // Delete child tables first, then parents
      await _database.delete(_database.capturedTransactions).go();
      await _database.delete(_database.transactions).go();
      await _database.delete(_database.budgets).go();
      await _database.delete(_database.categories).go();

      // Insert parents first, then children, then captured items
      await _database.batch((batch) {
        // Insert Categories with explicit IDs
        batch.insertAll(
          _database.categories,
          envelope.data.categories.map(
            (c) => CategoriesCompanion.insert(
              id: Value(c.id),
              name: c.name,
              icon: c.icon,
              color: c.color,
              isIncome: Value(c.isIncome),
            ),
          ),
        );

        // Insert Budgets with explicit IDs
        batch.insertAll(
          _database.budgets,
          envelope.data.budgets.map(
            (b) => BudgetsCompanion.insert(
              id: Value(b.id),
              categoryId: b.categoryId,
              amountLimit: b.amountLimit,
              month: b.month,
              year: b.year,
            ),
          ),
        );

        // Insert Transactions with explicit IDs
        batch.insertAll(
          _database.transactions,
          envelope.data.transactions.map(
            (t) => TransactionsCompanion.insert(
              id: Value(t.id),
              amount: t.amount,
              type: TransactionType.values.byName(t.type),
              categoryId: t.categoryId,
              date: DateTime.fromMillisecondsSinceEpoch(t.date, isUtc: true),
              note: Value(t.note),
              createdAt: Value(
                DateTime.fromMillisecondsSinceEpoch(t.createdAt, isUtc: true),
              ),
            ),
          ),
        );

        // Insert CapturedTransactions if present
        if (envelope.data.capturedTransactions.isNotEmpty) {
          batch.insertAll(
            _database.capturedTransactions,
            envelope.data.capturedTransactions.map(
              (ct) => CapturedTransactionsCompanion.insert(
                id: Value(ct.id),
                amountCents: ct.amountCents,
                type: TransactionType.values.byName(ct.type),
                counterparty: Value(ct.counterparty),
                accountLast4: Value(ct.accountLast4),
                reference: Value(ct.reference),
                occurredAt: DateTime.fromMillisecondsSinceEpoch(
                  ct.occurredAt,
                  isUtc: true,
                ),
                capturedAt: DateTime.fromMillisecondsSinceEpoch(
                  ct.capturedAt,
                  isUtc: true,
                ),
                sourcePackage: ct.sourcePackage,
                sender: ct.sender,
                dedupeKey: ct.dedupeKey,
                status: CaptureStatus.values.byName(ct.status),
                duplicateCount: Value(ct.duplicateCount),
                transactionId: Value(ct.transactionId),
                suggestedCategoryId: Value(ct.suggestedCategoryId),
              ),
            ),
          );
        }
      });
    });

    // 5. Apply whitelisted preferences AFTER transaction commits successfully
    final prefs = envelope.data.preferences;
    if (prefs.containsKey('currency_code')) {
      final code = prefs['currency_code'] as String?;
      if (code != null) {
        final cur = AppCurrency.fromCode(code);
        await _currencyService.setCurrency(cur);
      }
    }
    if (prefs.containsKey('custom_currency')) {
      final custom = prefs['custom_currency'] as Map<String, dynamic>?;
      if (custom != null) {
        final symbol = custom['symbol'] as String?;
        final code = custom['code'] as String?;
        final name = custom['name'] as String?;
        if (symbol != null && code != null && name != null) {
          await _currencyService.setCustomDetails(
            CustomCurrencyDetails(symbol: symbol, code: code, name: name),
          );
        }
      }
    }
  }

  @override
  Future<List<BackupFileInfo>> listAutoBackups() =>
      _fileService.listAutoBackups();

  @override
  Future<void> deleteBackupFile(String path) =>
      _fileService.deleteBackupFile(File(path));

  @override
  Future<({int fileCount, int totalSizeBytes})> getStorageUsage() =>
      _fileService.getStorageUsage();

  @override
  Future<String> getBackupDirectoryPath() async {
    final dir = await _fileService.getBackupDirectory();
    return dir.path;
  }
}
