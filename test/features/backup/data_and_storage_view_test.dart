import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fynza/core/services/currency_service.dart';
import 'package:fynza/features/backup/domain/models/auto_backup_frequency.dart';
import 'package:fynza/core/di/database_provider.dart';
import 'package:fynza/features/backup/presentation/views/data_and_storage_view.dart';
import 'backup_view_model_test.dart';

void main() {
  group('DataAndStorageView Widget Tests', () {
    late FakeBackupRepository fakeRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      fakeRepo = FakeBackupRepository();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          backupRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: DataAndStorageView()),
      );
    }

    testWidgets(
      'Renders all sections, pill buttons, storage location, and storage usage',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Data and storage'), findsOneWidget);
        expect(find.text('Storage location'), findsOneWidget);
        expect(find.text('/mock/backups'), findsOneWidget);
        expect(find.text('BACKUP AND RESTORE'), findsOneWidget);
        expect(find.text('Create backup'), findsOneWidget);
        expect(find.text('Restore backup'), findsOneWidget);
        expect(find.text('Automatic backup frequency'), findsOneWidget);
        expect(find.text('STORAGE USAGE'), findsOneWidget);
        expect(find.text('Automatic backups'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping frequency tile opens FrequencyDialog and updates selection',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final freqFinder = find.text('Automatic backup frequency');
        await tester.ensureVisible(freqFinder);
        await tester.tap(freqFinder);
        await tester.pumpAndSettle();

        final dailyOption = find.text(AutoBackupFrequency.daily.label);
        await tester.ensureVisible(dailyOption);
        await tester.tap(dailyOption);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('Daily', skipOffstage: false), findsOneWidget);
      },
    );

    testWidgets('Tapping help icon opens BackupInfoDialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();

      expect(find.text('About Data & Storage'), findsOneWidget);
      expect(find.text('What is backed up?'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text('About Data & Storage'), findsNothing);
    });
  });
}
