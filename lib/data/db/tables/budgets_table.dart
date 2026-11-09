import 'package:drift/drift.dart';
import 'categories_table.dart';

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(
        Categories,
        #id,
        onDelete: KeyAction.cascade,
      )();
  IntColumn get amountLimit => integer()(); // Stored in cents
  IntColumn get month => integer()(); // 1 - 12
  IntColumn get year => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId, month, year},
      ];
}
