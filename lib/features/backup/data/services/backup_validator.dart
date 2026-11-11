import '../../domain/models/backup_failure.dart';
import '../models/backup_dto.dart';
import 'backup_serializer.dart';

class BackupValidator {
  /// Validates the raw JSON map, checking schema version, required sections,
  /// field types, duplicate IDs, and foreign key integrity.
  ///
  /// Returns a parsed and verified [BackupEnvelopeDto] if valid.
  /// Throws [UnsupportedVersionFailure] or [CorruptDataFailure] if invalid.
  BackupEnvelopeDto validate(Map<String, dynamic> json) {
    // 1. Envelope validation
    final formatVersion = json['formatVersion'];
    if (formatVersion == null || formatVersion is! int) {
      throw const CorruptDataFailure(
        'Backup envelope is missing a valid formatVersion.',
      );
    }

    if (formatVersion > BackupSerializer.currentFormatVersion) {
      throw UnsupportedVersionFailure(formatVersion);
    }

    final createdAt = json['createdAt'];
    if (createdAt == null || createdAt is! int) {
      throw const CorruptDataFailure(
        'Backup envelope is missing a valid createdAt timestamp.',
      );
    }

    final rawData = json['data'];
    if (rawData == null || rawData is! Map<String, dynamic>) {
      throw const CorruptDataFailure(
        'Backup file is missing the data section.',
      );
    }

    // 2. Data sections presence
    if (rawData['categories'] is! List) {
      throw const CorruptDataFailure(
        'Missing or invalid categories section in backup.',
      );
    }
    if (rawData['transactions'] is! List) {
      throw const CorruptDataFailure(
        'Missing or invalid transactions section in backup.',
      );
    }
    if (rawData['budgets'] is! List) {
      throw const CorruptDataFailure(
        'Missing or invalid budgets section in backup.',
      );
    }

    final rawCategories = rawData['categories'] as List<dynamic>;
    final rawTransactions = rawData['transactions'] as List<dynamic>;
    final rawBudgets = rawData['budgets'] as List<dynamic>;
    final rawPreferences = rawData['preferences'];
    if (rawPreferences != null && rawPreferences is! Map) {
      throw const CorruptDataFailure('Invalid preferences format in backup.');
    }

    // 3. Categories validation
    final categoryIds = <int>{};
    final categories = <CategoryDto>[];

    for (var i = 0; i < rawCategories.length; i++) {
      final item = rawCategories[i];
      if (item is! Map<String, dynamic>) {
        throw CorruptDataFailure('Category at index $i is not a valid object.');
      }

      final id = item['id'];
      final name = item['name'];
      final icon = item['icon'];
      final color = item['color'];
      final isIncome = item['isIncome'];

      if (id is! int) {
        throw CorruptDataFailure('Category at index $i has an invalid id.');
      }
      if (categoryIds.contains(id)) {
        throw CorruptDataFailure(
          'Duplicate category ID ($id) found in backup.',
        );
      }
      categoryIds.add(id);

      if (name is! String || name.trim().isEmpty) {
        throw CorruptDataFailure('Category $id has an empty or invalid name.');
      }
      if (icon is! String) {
        throw CorruptDataFailure('Category $id has an invalid icon.');
      }
      if (color is! int) {
        throw CorruptDataFailure('Category $id has an invalid color value.');
      }
      if (isIncome != null && isIncome is! bool) {
        throw CorruptDataFailure('Category $id has an invalid isIncome flag.');
      }

      categories.add(
        CategoryDto(
          id: id,
          name: name.trim(),
          icon: icon,
          color: color,
          isIncome: isIncome as bool? ?? false,
        ),
      );
    }

    // 4. Transactions validation
    final transactionIds = <int>{};
    final transactions = <TransactionDto>[];

    for (var i = 0; i < rawTransactions.length; i++) {
      final item = rawTransactions[i];
      if (item is! Map<String, dynamic>) {
        throw CorruptDataFailure(
          'Transaction at index $i is not a valid object.',
        );
      }

      final id = item['id'];
      final amount = item['amount'];
      final type = item['type'];
      final categoryId = item['categoryId'];
      final date = item['date'];
      final note = item['note'];
      final txCreatedAt = item['createdAt'];

      if (id is! int) {
        throw CorruptDataFailure('Transaction at index $i has an invalid id.');
      }
      if (transactionIds.contains(id)) {
        throw CorruptDataFailure(
          'Duplicate transaction ID ($id) found in backup.',
        );
      }
      transactionIds.add(id);

      if (amount is! int || amount < 0) {
        throw CorruptDataFailure(
          'Transaction $id has an invalid amount ($amount).',
        );
      }
      if (type is! String || (type != 'income' && type != 'expense')) {
        throw CorruptDataFailure(
          'Transaction $id has an invalid type ($type).',
        );
      }
      if (categoryId is! int) {
        throw CorruptDataFailure('Transaction $id has an invalid categoryId.');
      }
      if (!categoryIds.contains(categoryId)) {
        throw CorruptDataFailure(
          'Transaction $id references non-existent category $categoryId.',
        );
      }
      if (date is! int) {
        throw CorruptDataFailure(
          'Transaction $id has an invalid date timestamp.',
        );
      }
      if (note != null && note is! String) {
        throw CorruptDataFailure('Transaction $id has an invalid note format.');
      }
      if (txCreatedAt != null && txCreatedAt is! int) {
        throw CorruptDataFailure(
          'Transaction $id has an invalid createdAt timestamp.',
        );
      }

      transactions.add(
        TransactionDto(
          id: id,
          amount: amount,
          type: type,
          categoryId: categoryId,
          date: date,
          note: note as String?,
          createdAt: (txCreatedAt as int?) ?? date,
        ),
      );
    }

    // 5. Budgets validation
    final budgetIds = <int>{};
    final budgetUniqueKeys = <String>{};
    final budgets = <BudgetDto>[];

    for (var i = 0; i < rawBudgets.length; i++) {
      final item = rawBudgets[i];
      if (item is! Map<String, dynamic>) {
        throw CorruptDataFailure('Budget at index $i is not a valid object.');
      }

      final id = item['id'];
      final categoryId = item['categoryId'];
      final amountLimit = item['amountLimit'];
      final month = item['month'];
      final year = item['year'];

      if (id is! int) {
        throw CorruptDataFailure('Budget at index $i has an invalid id.');
      }
      if (budgetIds.contains(id)) {
        throw CorruptDataFailure('Duplicate budget ID ($id) found in backup.');
      }
      budgetIds.add(id);

      if (categoryId is! int) {
        throw CorruptDataFailure('Budget $id has an invalid categoryId.');
      }
      if (!categoryIds.contains(categoryId)) {
        throw CorruptDataFailure(
          'Budget $id references non-existent category $categoryId.',
        );
      }
      if (amountLimit is! int || amountLimit < 0) {
        throw CorruptDataFailure(
          'Budget $id has an invalid amount limit ($amountLimit).',
        );
      }
      if (month is! int || month < 1 || month > 12) {
        throw CorruptDataFailure('Budget $id has an invalid month ($month).');
      }
      if (year is! int || year < 1900) {
        throw CorruptDataFailure('Budget $id has an invalid year ($year).');
      }

      final uniqueKey = '$categoryId-$month-$year';
      if (budgetUniqueKeys.contains(uniqueKey)) {
        throw CorruptDataFailure(
          'Duplicate budget for category $categoryId in $month/$year.',
        );
      }
      budgetUniqueKeys.add(uniqueKey);

      budgets.add(
        BudgetDto(
          id: id,
          categoryId: categoryId,
          amountLimit: amountLimit,
          month: month,
          year: year,
        ),
      );
    }

    // 6. Captured transactions validation (optional section)
    final capturedTransactions = <CapturedTransactionDto>[];
    final rawCaptures = rawData['capturedTransactions'];
    if (rawCaptures != null) {
      if (rawCaptures is! List) {
        throw const CorruptDataFailure(
          'Invalid capturedTransactions section in backup.',
        );
      }
      final captureIds = <int>{};
      for (var i = 0; i < rawCaptures.length; i++) {
        final item = rawCaptures[i];
        if (item is! Map<String, dynamic>) {
          throw CorruptDataFailure(
            'Captured transaction at index $i is not a valid object.',
          );
        }

        final id = item['id'];
        final amountCents = item['amountCents'];
        final type = item['type'];
        final occurredAt = item['occurredAt'];
        final capturedAt = item['capturedAt'];
        final sourcePackage = item['sourcePackage'];
        final sender = item['sender'];
        final dedupeKey = item['dedupeKey'];
        final status = item['status'];
        final duplicateCount = item['duplicateCount'];
        final txId = item['transactionId'];
        final catId = item['suggestedCategoryId'];

        if (id is! int || captureIds.contains(id)) {
          throw CorruptDataFailure(
            'Captured transaction at index $i has invalid or duplicate id.',
          );
        }
        captureIds.add(id);

        if (amountCents is! int || amountCents <= 0) {
          throw CorruptDataFailure(
            'Captured transaction $id has invalid amountCents.',
          );
        }
        if (type != 'expense' && type != 'income') {
          throw CorruptDataFailure(
            'Captured transaction $id has invalid type.',
          );
        }
        if (occurredAt is! int || capturedAt is! int) {
          throw CorruptDataFailure(
            'Captured transaction $id has invalid timestamps.',
          );
        }
        if (sourcePackage is! String ||
            sender is! String ||
            dedupeKey is! String ||
            status is! String) {
          throw CorruptDataFailure(
            'Captured transaction $id has invalid string fields.',
          );
        }
        if (duplicateCount != null &&
            (duplicateCount is! int || duplicateCount < 0)) {
          throw CorruptDataFailure(
            'Captured transaction $id has invalid duplicateCount.',
          );
        }
        if (txId != null && (txId is! int || !transactionIds.contains(txId))) {
          throw CorruptDataFailure(
            'Captured transaction $id references non-existent transactionId ($txId).',
          );
        }
        if (catId != null && (catId is! int || !categoryIds.contains(catId))) {
          throw CorruptDataFailure(
            'Captured transaction $id references non-existent suggestedCategoryId ($catId).',
          );
        }

        capturedTransactions.add(CapturedTransactionDto.fromJson(item));
      }
    }

    return BackupEnvelopeDto(
      formatVersion: formatVersion,
      appVersion: json['appVersion'] as String? ?? '1.0.0',
      dbSchemaVersion: json['dbSchemaVersion'] as int? ?? 1,
      createdAt: createdAt,
      data: BackupDataDto(
        categories: categories,
        transactions: transactions,
        budgets: budgets,
        preferences: rawPreferences != null
            ? Map<String, dynamic>.from(rawPreferences as Map)
            : {},
        capturedTransactions: capturedTransactions,
      ),
    );
  }
}
