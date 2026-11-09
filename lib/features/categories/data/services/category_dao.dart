import 'package:drift/drift.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/db/tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.attachedDatabase);

  Stream<List<Category>> watchAllCategories() {
    return (select(categories)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Stream<List<Category>> watchCategoriesByType({required bool isIncome}) {
    return (select(categories)
          ..where((t) => t.isIncome.equals(isIncome))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Category>> getAllCategories() {
    return (select(categories)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<Category?> getCategoryById(int id) {
    return (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertCategory(CategoriesCompanion companion) {
    return into(categories).insert(companion);
  }

  Future<bool> updateCategory(Category category) {
    return update(categories).replace(category);
  }

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }
}
