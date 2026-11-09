import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:expense_tracker/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryDao tests', () {
    test('Initial seeding creates default categories', () async {
      final categories = await db.categoryDao.getAllCategories();
      expect(categories.isNotEmpty, isTrue);
      // Food & Dining should exist
      expect(
        categories.any((c) => c.name == 'Food & Dining' && !c.isIncome),
        isTrue,
      );
      // Salary should exist
      expect(
        categories.any((c) => c.name == 'Salary' && c.isIncome),
        isTrue,
      );
    });

    test('Insert and fetch new category', () async {
      final id = await db.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: 'Cryptocurrency',
          icon: 'trending_up',
          color: 0xFF00E676,
          isIncome: const Value(true),
        ),
      );

      final fetched = await db.categoryDao.getCategoryById(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Cryptocurrency');
      expect(fetched.isIncome, isTrue);
    });

    test('Delete category removes it from database', () async {
      final id = await db.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: 'Temporary Category',
          icon: 'category',
          color: 0xFF9E9E9E,
          isIncome: const Value(false),
        ),
      );

      final deletedCount = await db.categoryDao.deleteCategory(id);
      expect(deletedCount, 1);

      final fetched = await db.categoryDao.getCategoryById(id);
      expect(fetched, isNull);
    });
  });
}
