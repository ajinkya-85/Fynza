import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fynza/data/db/app_database.dart';
import 'package:fynza/features/auto_capture/domain/models/capture_status.dart';
import 'package:fynza/shared/models/transaction_type.dart';

void main() {
  group('Database Schema Tests', () {
    test('current schema retains captured transaction tables', () async {
      final executor = NativeDatabase.memory();
      final db = AppDatabase.forTesting(executor);

      expect(db.schemaVersion, 4);

      final id = await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          amountCents: 15000,
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          capturedAt: DateTime.now(),
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'VM-HDFCBK',
          dedupeKey: 'test_key_migration',
          status: CaptureStatus.pending,
        ),
      );

      expect(id, greaterThan(0));

      final rows = await db.captureDao.getAllCaptures();
      expect(rows.length, 1);
      expect(rows.first.amountCents, 15000);

      await db.close();
    });
  });
}
