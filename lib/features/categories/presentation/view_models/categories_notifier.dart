import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/database_provider.dart';
import '../../../../data/db/app_database.dart';
import '../../domain/repositories/category_repository.dart';

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchAllCategories();
});

class CategoriesNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository _repository;
  StreamSubscription<List<Category>>? _subscription;

  CategoriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _subscription = _repository.watchAllCategories().listen(
      (categories) {
        state = AsyncValue.data(categories);
      },
      onError: (err, st) {
        state = AsyncValue.error(err, st);
      },
    );
  }

  Future<void> addCategory({
    required String name,
    required String icon,
    required int color,
    required bool isIncome,
  }) async {
    await _repository.addCategory(
      name: name,
      icon: icon,
      color: color,
      isIncome: isIncome,
    );
  }

  Future<void> updateCategory(Category category) async {
    await _repository.updateCategory(category);
  }

  Future<void> deleteCategory(int id) async {
    await _repository.deleteCategory(id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final categoriesNotifierProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<List<Category>>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoriesNotifier(repository);
});
