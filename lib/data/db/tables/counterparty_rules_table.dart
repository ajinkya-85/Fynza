import 'package:drift/drift.dart';
import 'categories_table.dart';

class CounterpartyRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get normalizedCounterparty => text().unique()();
  IntColumn get categoryId => integer().references(
        Categories,
        #id,
        onDelete: KeyAction.cascade,
      )();
  DateTimeColumn get updatedAt => dateTime()();
}
