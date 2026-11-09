import 'package:drift/drift.dart';
import '../../../../data/db/app_database.dart';
import '../../data/services/category_dao.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchAllCategories();
  Stream<List<Category>> watchCategoriesByType({required bool isIncome});
  Future<List<Category>> getAllCategories();
  Future<Category?> getCategoryById(int id);
  Future<int> addCategory({
    required String name,
    required String icon,
    required int color,
    required bool isIncome,
  });
  Future<bool> updateCategory(Category category);
  Future<int> deleteCategory(int id);
}

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryDao _dao;

  CategoryRepositoryImpl(this._dao);

  @override
  Stream<List<Category>> watchAllCategories() => _dao.watchAllCategories();

  @override
  Stream<List<Category>> watchCategoriesByType({required bool isIncome}) =>
      _dao.watchCategoriesByType(isIncome: isIncome);

  @override
  Future<List<Category>> getAllCategories() => _dao.getAllCategories();

  @override
  Future<Category?> getCategoryById(int id) => _dao.getCategoryById(id);

  @override
  Future<int> addCategory({
    required String name,
    required String icon,
    required int color,
    required bool isIncome,
  }) {
    return _dao.insertCategory(
      CategoriesCompanion.insert(
        name: name,
        icon: icon,
        color: color,
        isIncome: Value(isIncome),
      ),
    );
  }

  @override
  Future<bool> updateCategory(Category category) => _dao.updateCategory(category);

  @override
  Future<int> deleteCategory(int id) => _dao.deleteCategory(id);
}
