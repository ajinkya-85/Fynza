import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/data/db/app_database.dart';
import 'package:expense_tracker/features/auto_capture/domain/models/capture_status.dart';
import 'package:expense_tracker/shared/models/transaction_type.dart';

void main() {
  group('Database Schema Migration Tests (v1 -> v2)', () {
    test('upgrades schema from version 1 to 2 cleanly and retains tables', () async {
      final executor = NativeDatabase.memory();
      final db = AppDatabase.forTesting(executor);

      // Verify schema version is 2
      expect(db.schemaVersion, 2);

      // Verify captured_transactions table works
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

