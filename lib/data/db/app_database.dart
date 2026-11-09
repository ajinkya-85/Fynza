import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../../features/auto_capture/data/services/capture_dao.dart';
import '../../features/auto_capture/domain/models/capture_status.dart';
import '../../features/budget/data/services/budget_dao.dart';
import '../../features/categories/data/services/category_dao.dart';
import '../../features/transactions/data/services/transaction_dao.dart';
import '../../shared/models/transaction_type.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/captured_transactions_table.dart';
import 'tables/counterparty_rules_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions, Budgets, CapturedTransactions, CounterpartyRules],
  daos: [CategoryDao, TransactionDao, BudgetDao, CaptureDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from == 1) {
            await m.createTable(capturedTransactions);
            await m.createTable(counterpartyRules);
          }
        },
      );

  Future<void> _seedDefaultCategories() async {
    final defaultCategories = [
      // Expense Categories
      CategoriesCompanion.insert(
        name: 'Food & Dining',
        icon: 'restaurant',
        color: 0xFFE65100,
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Groceries',
        icon: 'shopping_cart',
        color: 0xFF2E7D32,
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Transport',
        icon: 'directions_car',
        color: 0xFF0277BD,
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Entertainment',
        icon: 'movie',
        color: 0xFF7B1FA2,
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Bills & Utilities',
        icon: 'receipt_long',
        color: 0xFFC62828,
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Shopping',
        icon: 'shopping_bag',
        color: 0xFFAD1457,
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Health',
        icon: 'medical_services',
        color: 0xFF00695C,
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Education',
        icon: 'school',
        color: 0xFFF57F17,
        isIncome: const Value(false),
      ),

      // Income Categories
      CategoriesCompanion.insert(
        name: 'Salary',
        icon: 'payments',
        color: 0xFF1B5E20,
        isIncome: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Freelance',
        icon: 'laptop_mac',
        color: 0xFF283593,
        isIncome: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Investments',
        icon: 'trending_up',
        color: 0xFF00838F,
        isIncome: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Gifts & Other',
        icon: 'card_giftcard',
        color: 0xFFD84315,
        isIncome: const Value(true),
      ),
    ];

    await batch((batch) {
      batch.insertAll(categories, defaultCategories);
    });
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'expense_tracker_db');
  }
}
