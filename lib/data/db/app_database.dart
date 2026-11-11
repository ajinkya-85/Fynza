import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../../core/theme/category_palette.dart';
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
  tables: [
    Categories,
    Transactions,
    Budgets,
    CapturedTransactions,
    CounterpartyRules,
  ],
  daos: [CategoryDao, TransactionDao, BudgetDao, CaptureDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

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
      if (from < 4 && to >= 4) {
        await migrateLegacyCategoryColors();
      }
      if (from >= 2 && from < 5 && to >= 5) {
        await m.addColumn(
          capturedTransactions,
          capturedTransactions.duplicateCount,
        );
      }
    },
  );

  Future<void> migrateLegacyCategoryColors() async {
    for (var i = 0; i < CategoryPalette.legacyColors.length; i++) {
      await customStatement('UPDATE categories SET color = ? WHERE color = ?', [
        CategoryPalette.colors[i],
        CategoryPalette.legacyColors[i],
      ]);
    }
  }

  Future<void> _seedDefaultCategories() async {
    final defaultCategories = [
      // Expense Categories
      CategoriesCompanion.insert(
        name: 'Food & Dining',
        icon: 'restaurant',
        color: CategoryPalette.colors[0],
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Groceries',
        icon: 'shopping_cart',
        color: CategoryPalette.colors[1],
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Transport',
        icon: 'directions_car',
        color: CategoryPalette.colors[2],
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Entertainment',
        icon: 'movie',
        color: CategoryPalette.colors[3],
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Bills & Utilities',
        icon: 'receipt_long',
        color: CategoryPalette.colors[4],
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Shopping',
        icon: 'shopping_bag',
        color: CategoryPalette.colors[5],
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Health',
        icon: 'medical_services',
        color: CategoryPalette.colors[6],
        isIncome: const Value(false),
      ),
      CategoriesCompanion.insert(
        name: 'Education',
        icon: 'school',
        color: CategoryPalette.colors[7],
        isIncome: const Value(false),
      ),

      // Income Categories
      CategoriesCompanion.insert(
        name: 'Salary',
        icon: 'payments',
        color: CategoryPalette.colors[8],
        isIncome: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Freelance',
        icon: 'laptop_mac',
        color: CategoryPalette.colors[9],
        isIncome: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Investments',
        icon: 'trending_up',
        color: CategoryPalette.colors[10],
        isIncome: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Gifts & Other',
        icon: 'card_giftcard',
        color: CategoryPalette.colors[11],
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
