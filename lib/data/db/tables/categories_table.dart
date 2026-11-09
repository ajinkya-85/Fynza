import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();
}
