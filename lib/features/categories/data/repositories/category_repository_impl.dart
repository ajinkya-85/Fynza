import 'package:drift/drift.dart';

import '../../../../data/db/app_database.dart' as db;
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../services/category_dao.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryDao _dao;

  CategoryRepositoryImpl(this._dao);

  Category _toDomain(db.Category category) => Category(
    id: category.id,
    name: category.name,
    icon: category.icon,
    color: category.color,
    isIncome: category.isIncome,
  );

  @override
  Stream<List<Category>> watchAllCategories() =>
      _dao.watchAllCategories().map((items) => items.map(_toDomain).toList());

  @override
  Stream<List<Category>> watchCategoriesByType({required bool isIncome}) => _dao
      .watchCategoriesByType(isIncome: isIncome)
      .map((items) => items.map(_toDomain).toList());

  @override
  Future<List<Category>> getAllCategories() async =>
      (await _dao.getAllCategories()).map(_toDomain).toList();

  @override
  Future<Category?> getCategoryById(int id) async {
    final category = await _dao.getCategoryById(id);
    return category == null ? null : _toDomain(category);
  }

  @override
  Future<int> addCategory({
    required String name,
    required String icon,
    required int color,
    required bool isIncome,
  }) {
    return _dao.insertCategory(
      db.CategoriesCompanion.insert(
        name: name,
        icon: icon,
        color: color,
        isIncome: Value(isIncome),
      ),
    );
  }

  @override
  Future<bool> updateCategory(Category category) {
    return _dao.updateCategory(
      db.Category(
        id: category.id,
        name: category.name,
        icon: category.icon,
        color: category.color,
        isIncome: category.isIncome,
      ),
    );
  }

  @override
  Future<int> deleteCategory(int id) => _dao.deleteCategory(id);
}
