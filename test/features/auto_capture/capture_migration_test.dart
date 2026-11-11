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

      expect(db.schemaVersion, 5);

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
      expect(rows.first.duplicateCount, 0);

      await db.close();
    });

    test('adds the duplicate count column to schema v4 databases', () async {
      final executor = NativeDatabase.memory(
        setup: (database) {
          database.execute('''
            CREATE TABLE captured_transactions (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              amount_cents INTEGER NOT NULL,
              type TEXT NOT NULL,
              counterparty TEXT,
              account_last4 TEXT,
              reference TEXT,
              occurred_at INTEGER NOT NULL,
              captured_at INTEGER NOT NULL,
              source_package TEXT NOT NULL,
              sender TEXT NOT NULL,
              dedupe_key TEXT NOT NULL UNIQUE,
              status TEXT NOT NULL,
              transaction_id INTEGER REFERENCES transactions(id)
                ON DELETE SET NULL,
              suggested_category_id INTEGER REFERENCES categories(id)
                ON DELETE SET NULL
            )
          ''');
          database.execute('PRAGMA user_version = 4');
        },
      );
      final db = AppDatabase.forTesting(executor);

      final id = await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          amountCents: 15000,
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          capturedAt: DateTime.now(),
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'VM-HDFCBK',
          dedupeKey: 'test_key_schema_v4',
          status: CaptureStatus.pending,
        ),
      );

      final row = await db.captureDao.getCaptureById(id);
      expect(row?.duplicateCount, 0);

      await db.close();
    });
  });
}
