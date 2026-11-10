import '../models/category.dart';

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
