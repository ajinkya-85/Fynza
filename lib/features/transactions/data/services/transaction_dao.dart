import 'package:drift/drift.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/db/tables/categories_table.dart';
import '../../../../data/db/tables/transactions_table.dart';
import '../../../../shared/models/category_spending.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/models/transaction_with_category.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.attachedDatabase);

  Stream<List<TransactionWithCategory>> watchTransactionsWithCategory({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    TransactionType? type,
  }) {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ]);

    if (startDate != null) {
      query.where(transactions.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(transactions.date.isSmallerOrEqualValue(endDate));
    }
    if (categoryId != null) {
      query.where(transactions.categoryId.equals(categoryId));
    }
    if (type != null) {
      query.where(transactions.type.equals(type.name));
    }

    query.orderBy([
      OrderingTerm.desc(transactions.date),
      OrderingTerm.desc(transactions.id),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          transaction: row.readTable(transactions),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Stream<List<TransactionWithCategory>> watchRecentTransactions({int limit = 5}) {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..orderBy([
        OrderingTerm.desc(transactions.date),
        OrderingTerm.desc(transactions.id),
      ])
      ..limit(limit);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          transaction: row.readTable(transactions),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Future<TransactionWithCategory?> getTransactionWithCategory(int id) {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])..where(transactions.id.equals(id));

    return query.getSingleOrNull().then((row) {
      if (row == null) return null;
      return TransactionWithCategory(
        transaction: row.readTable(transactions),
        category: row.readTable(categories),
      );
    });
  }

  Future<int> insertTransaction(TransactionsCompanion companion) {
    return into(transactions).insert(companion);
  }

  Future<bool> updateTransaction(TransactionsCompanion companion) {
    return (update(transactions)..where((t) => t.id.equals(companion.id.value)))
        .write(companion)
        .then((rows) => rows > 0);
  }

  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Stream<int> watchTotalAmount({
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final amountSum = transactions.amount.sum();
    final query = selectOnly(transactions)..addColumns([amountSum]);

    query.where(transactions.type.equals(type.name));

    if (startDate != null) {
      query.where(transactions.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(transactions.date.isSmallerOrEqualValue(endDate));
    }

    return query.watchSingle().map((row) => row.read(amountSum) ?? 0);
  }

  Stream<List<CategorySpending>> watchCategorySpending({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final totalSpent = transactions.amount.sum();
    final count = transactions.id.count();

    final query = select(categories).join([
      innerJoin(transactions, transactions.categoryId.equalsExp(categories.id)),
    ])
      ..where(transactions.type.equals(TransactionType.expense.name))
      ..where(transactions.date.isBiggerOrEqualValue(startDate))
      ..where(transactions.date.isSmallerOrEqualValue(endDate))
      ..groupBy([categories.id])
      ..addColumns([totalSpent, count])
      ..orderBy([OrderingTerm.desc(totalSpent)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CategorySpending(
          category: row.readTable(categories),
          totalCents: row.read(totalSpent) ?? 0,
          transactionCount: row.read(count) ?? 0,
        );
      }).toList();
    });
  }
}
