import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fynza/data/db/app_database.dart';
import 'package:fynza/core/theme/category_palette.dart';
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
      expect(categories.any((c) => c.name == 'Salary' && c.isIncome), isTrue);
      expect(
        CategoryPalette.colors.toSet(),
        hasLength(CategoryPalette.colors.length),
      );
      expect(
        categories
            .where((category) => category.name == 'Food & Dining')
            .single
            .color,
        CategoryPalette.colors[0],
      );
      expect(
        categories.where((category) => category.name == 'Salary').single.color,
        CategoryPalette.colors[8],
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

    test(
      'migrates colors on already-saved categories and preserves custom colors',
      () async {
        await db.customStatement(
          'UPDATE categories SET color = ? WHERE name = ?',
          [CategoryPalette.legacyColors[0], 'Food & Dining'],
        );
        final legacyCustomId = await db.categoryDao.insertCategory(
          CategoriesCompanion.insert(
            name: 'Legacy custom',
            icon: 'category',
            color: CategoryPalette.legacyColors[12],
          ),
        );
        final customColorId = await db.categoryDao.insertCategory(
          CategoriesCompanion.insert(
            name: 'My custom color',
            icon: 'category',
            color: 0xFF00E676,
          ),
        );

        await db.migrateLegacyCategoryColors();

        final categories = await db.categoryDao.getAllCategories();
        expect(
          categories
              .singleWhere((category) => category.name == 'Food & Dining')
              .color,
          CategoryPalette.colors[0],
        );
        expect(
          (await db.categoryDao.getCategoryById(legacyCustomId))!.color,
          CategoryPalette.colors[12],
        );
        expect(
          (await db.categoryDao.getCategoryById(customColorId))!.color,
          0xFF00E676,
        );
      },
    );
  });
}
