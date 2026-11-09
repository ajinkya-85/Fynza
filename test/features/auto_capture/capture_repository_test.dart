import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fynza/data/db/app_database.dart';
import 'package:fynza/features/auto_capture/data/services/capture_preferences_service.dart';
import 'package:fynza/features/auto_capture/domain/models/capture_status.dart';
import 'package:fynza/features/auto_capture/domain/models/raw_notification.dart';
import 'package:fynza/features/auto_capture/domain/repositories/capture_repository.dart';
import 'package:fynza/shared/models/transaction_type.dart';

void main() {
  late AppDatabase db;
  late CapturePreferencesService prefsService;
  late CaptureRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    prefsService = CapturePreferencesService(sp);
    await prefsService.setMasterEnabled(true);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CaptureRepositoryImpl(db: db, prefs: prefsService);
  });

  tearDown(() async {
    await db.close();
  });

  group('CaptureRepository Ingestion Tests', () {
    test('drops all notifications when auto-capture is turned off (isMasterEnabled is false)', () async {
      await prefsService.setMasterEnabled(false);
      await repo.ingest([
        RawNotification(
          key: '1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 500 debited from A/c XX1234 towards Cafe. UPI Ref: 123456.',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      final count = await repo.watchPendingCount().first;
      expect(count, 0);
    });

    test('drops non-SMS package notifications', () async {
      await repo.ingest([
        RawNotification(
          key: '1',
          packageName: 'com.whatsapp',
          title: 'HDFC Bank',
          text: 'Rs 500 debited from A/c XX1234',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      final count = await repo.watchPendingCount().first;
      expect(count, 0);
    });

    test('drops non-bank sender notifications', () async {
      await repo.ingest([
        RawNotification(
          key: '1',
          packageName: 'com.google.android.apps.messaging',
          title: '+919876543210',
          text: 'Rs 500 debited from A/c XX1234',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      final count = await repo.watchPendingCount().first;
      expect(count, 0);
    });

    test('drops ignored senders', () async {
      await prefsService.addIgnoredSender('VM-IGNORE');

      await repo.ingest([
        RawNotification(
          key: '1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-IGNORE',
          text: 'Rs 500 debited from A/c XX1234 towards Shop. UPI Ref: 12345678.',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      final count = await repo.watchPendingCount().first;
      expect(count, 0);
    });

    test('ingests valid bank notification into pending', () async {
      await repo.ingest([
        RawNotification(
          key: '1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Dear customer, Rs 1,450.00 debited from A/c XX1234 towards Swiggy. UPI Ref: 99887766.',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      final pending = await repo.watchPendingCaptures().first;
      expect(pending.length, 1);
      expect(pending.first.amountCents, 145000);
      expect(pending.first.type, TransactionType.expense);
      expect(pending.first.status, CaptureStatus.pending);
      expect(pending.first.reference, '99887766');
      expect(pending.first.accountLast4, '1234');
    });

    test('deduplicates identical notification with conflict ignore', () async {
      final notif = RawNotification(
        key: '1',
        packageName: 'com.google.android.apps.messaging',
        title: 'VM-HDFCBK',
        text: 'Rs 500 debited from A/c XX1234. UPI Ref: 11223344.',
        postTime: DateTime.now().millisecondsSinceEpoch,
      );

      await repo.ingest([notif]);
      await repo.ingest([notif]); // duplicate call

      final pending = await repo.watchPendingCaptures().first;
      expect(pending.length, 1);
    });

    test('auto-adds high confidence transaction when mode is addAutomatically and suggested category exists', () async {
      await prefsService.setMode(CaptureMode.addAutomatically);

      // Seed a rule for 'swiggy' -> category 1
      await db.captureDao.setSuggestedCategory('swiggy', 1);

      await repo.ingest([
        RawNotification(
          key: '1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 250 debited from A/c XX1234 towards Swiggy. UPI Ref: 55443322.',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      final pending = await repo.watchPendingCaptures().first;
      expect(pending.length, 0); // Not in pending

      final autoAdded = await repo.watchRecentlyAutoAdded().first;
      expect(autoAdded.length, 1);
      expect(autoAdded.first.status, CaptureStatus.confirmed);
      expect(autoAdded.first.transactionId, isNotNull);

      // Verify the transaction was inserted into transactions table
      final txs = await db.select(db.transactions).get();
      expect(txs.length, 1);
      expect(txs.first.amount, 25000);
      expect(txs.first.categoryId, 1);
    });

    test('ingests UPI notification from payment apps like Google Pay', () async {
      await repo.ingest([
        RawNotification(
          key: 'gpay_1',
          packageName: 'com.google.android.apps.nbu.paisa.user',
          title: 'Google Pay',
          text: 'Paid ₹350 to Starbucks using HDFC Bank •••• 1234. UPI Ref: 987654321098.',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      final pending = await repo.watchPendingCaptures().first;
      expect(pending.length, 1);
      expect(pending.first.amountCents, 35000);
      expect(pending.first.counterparty, 'Starbucks');
      expect(pending.first.accountLast4, '1234');
      expect(pending.first.reference, '987654321098');
    });

    test('deduplicates UPI app push notification against bank SMS with matching reference', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      // 1. Google Pay push notification
      await repo.ingest([
        RawNotification(
          key: 'gpay_2',
          packageName: 'com.google.android.apps.nbu.paisa.user',
          title: 'Google Pay',
          text: 'Paid ₹500 to Swiggy using State Bank •••• 9999. UPI Ref: 112233445566.',
          postTime: now,
        ),
      ]);

      // 2. Incoming Bank SMS for the same transaction
      await repo.ingest([
        RawNotification(
          key: 'sms_2',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-SBINB',
          text: 'Dear customer, Rs 500 debited from A/c XX9999 towards Swiggy. UPI Ref: 112233445566.',
          postTime: now + 500,
        ),
      ]);

      final pending = await repo.watchPendingCaptures().first;
      expect(pending.length, 1); // Deduplicated! Only 1 item in inbox
    });
  });

  group('CaptureRepository Confirm / Dismiss / Undo Tests', () {
    test('confirming pending capture creates transaction and sets confirmed atomically', () async {
      await repo.ingest([
        RawNotification(
          key: '1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 990 debited from A/c XX1234 towards Uber. UPI Ref: 10293847.',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      final pending = await repo.watchPendingCaptures().first;
      expect(pending.length, 1);
      final item = pending.first;

      await repo.confirmCapture(item.id, categoryId: 3); // Transport

      final pendingAfter = await repo.watchPendingCaptures().first;
      expect(pendingAfter.isEmpty, isTrue);

      final txs = await db.select(db.transactions).get();
      expect(txs.length, 1);
      expect(txs.first.amount, 99000);
      expect(txs.first.categoryId, 3);

      // Also verify suggested category was saved for 'uber'
      final suggested = await repo.getSuggestedCategory('Uber');
      expect(suggested, 3);
    });

    test('dismiss and undo dismiss work correctly', () async {
      await repo.ingest([
        RawNotification(
          key: '1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 300 debited from A/c XX1234. UPI Ref: 44332211.',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      final item = (await repo.watchPendingCaptures().first).first;

      await repo.dismissCapture(item.id);
      expect((await repo.watchPendingCaptures().first).isEmpty, isTrue);

      await repo.undoDismiss(item.id);
      expect((await repo.watchPendingCaptures().first).length, 1);
    });

    test('undo auto-add removes transaction and dismisses capture row', () async {
      await prefsService.setMode(CaptureMode.addAutomatically);
      await db.captureDao.setSuggestedCategory('zomato', 1);

      await repo.ingest([
        RawNotification(
          key: '1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 450 debited from A/c XX1234 towards Zomato. UPI Ref: 88776655.',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      final autoAdded = (await repo.watchRecentlyAutoAdded().first).first;
      expect(autoAdded.transactionId, isNotNull);

      await repo.undoAutoAdd(autoAdded.id);

      final txs = await db.select(db.transactions).get();
      expect(txs.isEmpty, isTrue);
    });
  });

  group('Pending Isolation Tests', () {
    test('pending captures NEVER affect transaction totals or budget calculations', () async {
      // Ingest 3 pending captured transactions worth Rs 5,000 total
      await repo.ingest([
        RawNotification(
          key: '1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 2,000 debited from A/c XX1234. UPI Ref: 11112222.',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
        RawNotification(
          key: '2',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 3,000 debited from A/c XX1234. UPI Ref: 33334444.',
          postTime: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);

      // Assert transactions table is empty
      final allTransactions = await db.select(db.transactions).get();
      expect(allTransactions.isEmpty, isTrue);

      // Assert total spend from transactionDao is 0
      final totalExpense = await db.transactionDao.watchTotalAmount(type: TransactionType.expense).first;
      expect(totalExpense, 0);

      // Assert total income from transactionDao is 0
      final totalIncome = await db.transactionDao.watchTotalAmount(type: TransactionType.income).first;
      expect(totalIncome, 0);
    });
  });

  group('Duplicate Detection Tests', () {
    test('flags pending item as possible duplicate when matching transaction exists in db', () async {
      final categories = await db.categoryDao.getAllCategories();
      final catId = categories.first.id;
      final now = DateTime.now();

      // Pre-existing transaction of Rs 500 (50000 cents)
      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amount: 50000,
          type: TransactionType.expense,
          categoryId: catId,
          date: now,
          note: const Value('Lunch at Cafe'),
        ),
      );

      // Ingest a pending capture with the same amount (Rs 500)
      await repo.ingest([
        RawNotification(
          key: 'dup_1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 500 debited from A/c XX1234 towards Cafe. UPI Ref: 99887711.',
          postTime: now.millisecondsSinceEpoch,
        ),
      ]);

      final pending = await repo.watchPendingCaptures().first;
      expect(pending.length, 1);
      expect(pending.first.isPossibleDuplicate, isTrue);
    });

    test('flags intra-batch duplicates when two notifications share same amount within 24 hours', () async {
      final now = DateTime.now();

      await repo.ingest([
        RawNotification(
          key: 'batch_1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 250 debited from A/c XX1234. UPI Ref: 11110001.',
          postTime: now.millisecondsSinceEpoch,
        ),
        RawNotification(
          key: 'batch_2',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 250 debited from A/c XX1234. UPI Ref: 22220002.',
          postTime: now.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
        ),
      ]);

      final pending = await repo.watchPendingCaptures().first;
      expect(pending.length, 2);
      expect(pending[0].isPossibleDuplicate, isTrue);
      expect(pending[1].isPossibleDuplicate, isTrue);
    });

    test('does NOT flag item when no duplicate exists', () async {
      final now = DateTime.now();

      await repo.ingest([
        RawNotification(
          key: 'unique_1',
          packageName: 'com.google.android.apps.messaging',
          title: 'VM-HDFCBK',
          text: 'Rs 799 debited from A/c XX1234. UPI Ref: 33330003.',
          postTime: now.millisecondsSinceEpoch,
        ),
      ]);

      final pending = await repo.watchPendingCaptures().first;
      expect(pending.length, 1);
      expect(pending.first.isPossibleDuplicate, isFalse);
    });
  });
}
