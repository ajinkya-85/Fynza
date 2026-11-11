import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fynza/core/di/database_provider.dart';
import 'package:fynza/core/services/currency_service.dart';
import 'package:fynza/core/theme/category_palette.dart';
import 'package:fynza/data/db/app_database.dart';
import 'package:fynza/features/auto_capture/data/repositories/capture_repository_impl.dart';
import 'package:fynza/features/auto_capture/data/services/capture_preferences_service.dart';
import 'package:fynza/features/auto_capture/data/services/notification_capture_service.dart';
import 'package:fynza/features/auto_capture/domain/models/capture_status.dart';
import 'package:fynza/features/auto_capture/domain/models/parsed_transaction.dart';
import 'package:fynza/features/auto_capture/domain/models/raw_notification.dart';
import 'package:fynza/features/auto_capture/domain/parsing/sms_transaction_parser.dart';
import 'package:fynza/shared/models/transaction_type.dart';
import 'package:fynza/main.dart' as fynza_app show FynzaApp;

const _cleanupOnly = bool.fromEnvironment('CLEANUP_MANUAL_TEST_DATA');
const _verifyOnly = bool.fromEnvironment('VERIFY_MANUAL_TEST_SEED');
const _seedSender = 'QA-SEED';
const _categoryPrefix = 'QA Test ';
const _notePrefix = 'QA Seed: ';
const _captureNotePrefix = 'QASeed';
const _masterEnabledKey = 'auto_capture_master_enabled';
const _modeKey = 'auto_capture_mode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final db = _verifyOnly
      ? AppDatabase.forTesting(NativeDatabase.memory())
      : AppDatabase();

  if (_cleanupOnly) {
    await _cleanup(db);
    debugPrint(
      'Removed QA seed data. No app data outside the QA markers was changed.',
    );
  } else if (_verifyOnly) {
    try {
      await _seed(db, prefs);
      debugPrint(
        'Manual test seed verification completed using an in-memory database.',
      );
      await db.close();
      exit(0);
    } catch (error, stackTrace) {
      debugPrint('Manual test seed verification failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await db.close();
      exit(1);
    }
  } else {
    await _seed(db, prefs);
    debugPrint(
      'QA data is ready. Browse Dashboard, Transactions, Categories, Budgets, '
      'then open Capture Inbox from the inbox icon.',
    );
  }

  final capturePreferences = CapturePreferencesService(prefs);
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        capturePreferencesServiceProvider.overrideWithValue(capturePreferences),
        notificationCaptureServiceProvider.overrideWithValue(
          _NoopNotificationCaptureService(),
        ),
        autoCaptureEnabledProvider.overrideWith(
          (_) => _ManualCaptureEnabledNotifier(capturePreferences),
        ),
      ],
      child: const fynza_app.FynzaApp(),
    ),
  );
}

Future<void> _seed(AppDatabase db, SharedPreferences prefs) async {
  await _cleanup(db);

  final now = DateTime.now();
  final categories = _seedCategories();
  final categoryIds = <String, int>{};
  for (final category in categories) {
    categoryIds[category.name] = await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: '$_categoryPrefix${category.name}',
            icon: category.icon,
            color: category.color,
            isIncome: Value(category.isIncome),
          ),
        );
  }

  var transactionCount = 0;
  for (final category in categories) {
    final categoryId = categoryIds[category.name]!;
    for (final sample in category.transactions) {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              amount: sample.amountCents,
              type: category.isIncome
                  ? TransactionType.income
                  : TransactionType.expense,
              categoryId: categoryId,
              date: _dateForSample(now, sample.monthsAgo, sample.dayInMonth),
              note: Value('$_notePrefix${sample.note}'),
            ),
          );
      transactionCount++;
    }
  }

  var budgetCount = 0;
  for (final category in categories.where(
    (category) => !category.isIncome && category.monthlyBudgetCents != null,
  )) {
    await db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            categoryId: categoryIds[category.name]!,
            amountLimit: category.monthlyBudgetCents!,
            month: now.month,
            year: now.year,
          ),
        );
    budgetCount++;
  }

  final capturePreferences = CapturePreferencesService(prefs);
  final previousMaster = prefs.getBool(_masterEnabledKey);
  final previousMode = prefs.getString(_modeKey);
  try {
    await capturePreferences.setMasterEnabled(true);
    await capturePreferences.setMode(CaptureMode.reviewFirst);
    final repository = CaptureRepositoryImpl(db: db, prefs: capturePreferences);
    final postedAt = DateTime.now().millisecondsSinceEpoch;

    await repository.ingest([
      _notification(
        'repeat_original',
        'Rs 250 debited from A/c XX1111 towards QASeed Corner Cafe. UPI Ref: 90000001.',
        postedAt,
      ),
      _notification(
        'repeat_replay',
        'Rs 250 debited from A/c XX1111 towards QASeed Corner Cafe. UPI Ref: 90000001.',
        postedAt + 1,
      ),
      _notification(
        'repeat_other_source',
        'Paid ₹250 to QASeed Corner Cafe using HDFC Bank •••• 1111. UPI Ref: 90000001.',
        postedAt + 2,
        packageName: 'com.google.android.apps.nbu.paisa.user',
        title: 'Google Pay',
        isSmsApp: false,
      ),
      _notification(
        'same_amount_one',
        'Rs 250 debited from A/c XX1111 towards QASeed Shop A. UPI Ref: 90000002.',
        postedAt + 3,
      ),
      _notification(
        'same_amount_two',
        'Rs 250 debited from A/c XX1111 towards QASeed Shop B. UPI Ref: 90000003.',
        postedAt + 4,
      ),
      _notification(
        'different_account_one',
        'Rs 500 debited from A/c XX1111. UPI Ref: 90000004.',
        postedAt + 5,
      ),
      _notification(
        'different_account_two',
        'Rs 500 debited from A/c XX2222. UPI Ref: 90000004.',
        postedAt + 6,
      ),
      _notification(
        'different_amount_one',
        'Rs 500 debited from A/c XX1111. UPI Ref: 90000005.',
        postedAt + 7,
      ),
      _notification(
        'different_amount_two',
        'Rs 501 debited from A/c XX1111. UPI Ref: 90000005.',
        postedAt + 8,
      ),
      _notification(
        'different_type_expense',
        'Rs 100 debited from A/c XX1111. UPI Ref: 90000006.',
        postedAt + 9,
      ),
      _notification(
        'different_type_income',
        'Rs 100 credited to your account. UPI Ref: 90000006.',
        postedAt + 10,
      ),
      _notification(
        'no_reference_one',
        'Rs 75 debited from A/c XX1111 towards QASeed Test Shop.',
        postedAt + 11,
      ),
      _notification(
        'no_reference_two',
        'Rs 75 debited from A/c XX1111 towards QASeed Test Shop.',
        postedAt + 12,
      ),
      _notification(
        'income_review',
        'Rs 1200 credited to your account from QASeed Client. UPI Ref: 90000007.',
        postedAt + 13,
      ),
    ]);

    final diningCategoryId = categoryIds['Food & Dining']!;
    await db.captureDao.setSuggestedCategory(
      'qaseed autocafe',
      diningCategoryId,
    );
    await capturePreferences.setMode(CaptureMode.addAutomatically);
    await repository.ingest([
      _notification(
        'auto_added',
        'Rs 325 debited from A/c XX1111 towards QASeed AutoCafe. UPI Ref: 90000008.',
        postedAt + 14,
      ),
    ]);
    await capturePreferences.setMode(CaptureMode.reviewFirst);

    final parser = const SmsTransactionParser();
    final parserCases = <(String, String, bool)>[
      (
        'valid expense',
        'Rs 50 debited from A/c XX1111. UPI Ref: 91000001.',
        true,
      ),
      (
        'valid income',
        'Rs 50 credited to your account. UPI Ref: 91000002.',
        true,
      ),
      (
        'refund as income',
        'Rs 50 refunded to your account. UPI Ref: 91000003.',
        true,
      ),
      ('OTP rejection', 'OTP 123456 for Rs 50. Do not share.', false),
      (
        'promotion rejection',
        'Recharge now for Rs 50 and get free data.',
        false,
      ),
      ('failed payment rejection', 'Rs 50 payment failed.', false),
      ('foreign currency rejection', 'USD 50 paid to Test Shop.', false),
      (
        'ambiguous debit/credit rejection',
        'Rs 50 debited and credited to your account.',
        false,
      ),
      ('balance-only rejection', 'Your available balance is Rs 50.', false),
    ];
    final rejectedMessages = <RawNotification>[];
    for (final (label, text, shouldParse) in parserCases) {
      final result = parser.parse(text, DateTime.now());
      final didParse = result is ParsedTransaction;
      if (didParse != shouldParse) {
        throw StateError(
          'Parser seed case "$label" did not match expectation.',
        );
      }
      debugPrint(
        'Parser seed: $label -> ${didParse ? 'transaction' : 'rejected'}',
      );
      if (!shouldParse) {
        rejectedMessages.add(
          _notification(
            'reject_${rejectedMessages.length}',
            text,
            postedAt + 20,
          ),
        );
      }
    }

    final pendingBeforeRejected = await repository.watchPendingCaptures().first;
    await repository.ingest(rejectedMessages);
    final pendingAfterRejected = await repository.watchPendingCaptures().first;
    if (pendingAfterRejected.length != pendingBeforeRejected.length) {
      throw StateError(
        'A rejected parser case was added to the capture inbox.',
      );
    }

    final pending = await repository.watchPendingCaptures().first;
    final repeats = pending.where((item) => item.duplicateCount > 0).toList();
    if (repeats.length != 1 || repeats.single.duplicateCount != 2) {
      throw StateError('Expected one cross-source replayed inbox item.');
    }
    if (pending.length != 12) {
      throw StateError(
        'Expected 12 independently reviewable capture items, got ${pending.length}.',
      );
    }
    debugPrint(
      'Capture seed identities: ${pending.map((item) => '${item.reference ?? 'none'}:${item.amountCents}:${item.type.name}:${item.accountLast4}').toList()}',
    );
    const expectedReferenceCounts = {
      '90000002': 1,
      '90000003': 1,
      '90000004': 2,
      '90000005': 2,
      '90000006': 2,
    };
    for (final entry in expectedReferenceCounts.entries) {
      final matches = pending
          .where((item) => item.reference == entry.key)
          .toList();
      if (matches.length != entry.value) {
        throw StateError(
          'Reference ${entry.key} should have ${entry.value} independent '
          'capture(s), got ${matches.map((item) => '${item.amountCents}/${item.type.name}/${item.accountLast4}').toList()}.',
        );
      }
    }
    final autoAdded = await repository.watchRecentlyAutoAdded().first;
    if (autoAdded.isEmpty) {
      throw StateError('Expected one auto-added transaction in the seed data.');
    }
    final actualCategories = await (db.select(
      db.categories,
    )..where((category) => category.name.like('$_categoryPrefix%'))).get();
    final actualBudgets =
        await (db.select(db.budgets)..where(
              (budget) => budget.categoryId.isIn(categoryIds.values.toList()),
            ))
            .get();
    final incomeCategoryCount = categories
        .where((category) => category.isIncome)
        .length;
    final expenseCategoryCount = categories.length - incomeCategoryCount;
    if (actualCategories.length != categories.length ||
        actualBudgets.length != budgetCount ||
        expenseCategoryCount < 15 ||
        incomeCategoryCount < 7 ||
        transactionCount < 70) {
      throw StateError('The full-app seed dataset is incomplete.');
    }
    debugPrint(
      'Seeded $transactionCount transactions across ${categories.length} categories, '
      '($expenseCategoryCount expense, $incomeCategoryCount income), '
      '$budgetCount budgets, '
      '${pending.length} pending captures, and ${autoAdded.length} auto-added capture.',
    );
  } finally {
    await _restorePreference(prefs, _masterEnabledKey, previousMaster);
    await _restorePreference(prefs, _modeKey, previousMode);
  }
}

RawNotification _notification(
  String key,
  String text,
  int postTime, {
  String packageName = 'com.google.android.apps.messaging',
  String title = _seedSender,
  bool isSmsApp = true,
}) {
  return RawNotification(
    key: key,
    packageName: packageName,
    title: title,
    text: text,
    postTime: postTime,
    isSmsApp: isSmsApp,
  );
}

List<_SeedCategory> _seedCategories() => [
  _SeedCategory(
    'Food & Dining',
    'restaurant',
    CategoryPalette.colors[0],
    transactions: [
      _SeedTransaction(4650, 0, 3, 'Lunch at Maple Cafe'),
      _SeedTransaction(8290, 0, 8, 'Dinner with friends'),
      _SeedTransaction(12800, 1, 16, 'Weekend brunch'),
      _SeedTransaction(5990, 3, 11, 'Coffee and pastries'),
    ],
    monthlyBudgetCents: 12000,
  ),
  _SeedCategory(
    'Groceries',
    'shopping_cart',
    CategoryPalette.colors[1],
    transactions: [
      _SeedTransaction(62450, 0, 5, 'Weekly supermarket run'),
      _SeedTransaction(18400, 0, 9, 'Fresh produce'),
      _SeedTransaction(48750, 1, 12, 'Monthly groceries'),
      _SeedTransaction(32100, 3, 18, 'Pantry restock'),
    ],
    monthlyBudgetCents: 110000,
  ),
  _SeedCategory(
    'Transport',
    'directions_car',
    CategoryPalette.colors[2],
    transactions: [
      _SeedTransaction(18600, 0, 4, 'Cab to office'),
      _SeedTransaction(4500, 0, 10, 'Metro card top-up'),
      _SeedTransaction(12350, 1, 14, 'Ride share'),
      _SeedTransaction(8500, 3, 7, 'Fuel'),
    ],
    monthlyBudgetCents: 30000,
  ),
  _SeedCategory(
    'Entertainment',
    'movie',
    CategoryPalette.colors[3],
    transactions: [
      _SeedTransaction(3499, 0, 7, 'Cinema tickets'),
      _SeedTransaction(1299, 1, 19, 'Concert stream'),
      _SeedTransaction(2200, 3, 13, 'Museum visit'),
    ],
    monthlyBudgetCents: 10000,
  ),
  _SeedCategory(
    'Bills & Utilities',
    'receipt_long',
    CategoryPalette.colors[4],
    transactions: [
      _SeedTransaction(42800, 0, 6, 'Electricity bill'),
      _SeedTransaction(9999, 0, 9, 'Home internet'),
      _SeedTransaction(15600, 1, 8, 'Water and utilities'),
      _SeedTransaction(39900, 3, 6, 'Electricity bill'),
    ],
    monthlyBudgetCents: 75000,
  ),
  _SeedCategory(
    'Shopping',
    'shopping_bag',
    CategoryPalette.colors[5],
    transactions: [
      _SeedTransaction(7299, 0, 2, 'Household supplies'),
      _SeedTransaction(58900, 1, 17, 'Running shoes'),
      _SeedTransaction(2499, 3, 5, 'Phone accessories'),
    ],
    monthlyBudgetCents: 50000,
  ),
  _SeedCategory(
    'Health',
    'medical_services',
    CategoryPalette.colors[6],
    transactions: [
      _SeedTransaction(8500, 0, 6, 'Pharmacy'),
      _SeedTransaction(25000, 1, 21, 'Clinic visit'),
      _SeedTransaction(12000, 3, 12, 'Dental checkup'),
    ],
    monthlyBudgetCents: 35000,
  ),
  _SeedCategory(
    'Education',
    'school',
    CategoryPalette.colors[7],
    transactions: [
      _SeedTransaction(15900, 0, 8, 'Online course'),
      _SeedTransaction(7500, 1, 11, 'Reference books'),
      _SeedTransaction(49900, 3, 14, 'Workshop registration'),
    ],
    monthlyBudgetCents: 40000,
  ),
  _SeedCategory(
    'Home & Rent',
    'home',
    CategoryPalette.colors[8],
    transactions: [
      _SeedTransaction(285000, 0, 2, 'Monthly rent'),
      _SeedTransaction(6400, 1, 4, 'Hardware store'),
      _SeedTransaction(12800, 3, 6, 'Home supplies'),
    ],
    monthlyBudgetCents: 300000,
  ),
  _SeedCategory(
    'Personal Care',
    'fitness_center',
    CategoryPalette.colors[9],
    transactions: [
      _SeedTransaction(3499, 0, 9, 'Haircut'),
      _SeedTransaction(2199, 1, 10, 'Skincare'),
      _SeedTransaction(1800, 3, 16, 'Personal care essentials'),
    ],
    monthlyBudgetCents: 12000,
  ),
  _SeedCategory(
    'Subscriptions',
    'phone_android',
    CategoryPalette.colors[10],
    transactions: [
      _SeedTransaction(1499, 0, 1, 'Music subscription'),
      _SeedTransaction(899, 0, 5, 'Cloud storage'),
      _SeedTransaction(1299, 1, 1, 'Video subscription'),
      _SeedTransaction(1499, 3, 1, 'Music subscription'),
    ],
    monthlyBudgetCents: 7000,
  ),
  _SeedCategory(
    'Travel',
    'flight',
    CategoryPalette.colors[11],
    transactions: [
      _SeedTransaction(85000, 1, 16, 'Weekend train tickets'),
      _SeedTransaction(12400, 3, 14, 'Hotel deposit'),
      _SeedTransaction(6500, 5, 12, 'Airport transfer'),
    ],
    monthlyBudgetCents: 100000,
  ),
  _SeedCategory(
    'Pets',
    'pets',
    CategoryPalette.colors[12],
    transactions: [
      _SeedTransaction(4200, 0, 7, 'Pet food'),
      _SeedTransaction(8900, 1, 18, 'Vet checkup'),
      _SeedTransaction(2600, 3, 8, 'Pet supplies'),
    ],
    monthlyBudgetCents: 18000,
  ),
  _SeedCategory(
    'Gifts & Donations',
    'card_giftcard',
    CategoryPalette.colors[13],
    transactions: [
      _SeedTransaction(2500, 0, 10, 'Birthday gift'),
      _SeedTransaction(5000, 1, 20, 'Community donation'),
      _SeedTransaction(3200, 3, 22, 'Wedding present'),
    ],
    monthlyBudgetCents: 15000,
  ),
  _SeedCategory(
    'Insurance',
    'category',
    CategoryPalette.colors[14],
    transactions: [
      _SeedTransaction(18500, 0, 5, 'Health policy premium'),
      _SeedTransaction(42000, 3, 5, 'Vehicle insurance installment'),
    ],
    monthlyBudgetCents: 45000,
  ),
  _SeedCategory(
    'Other Expenses',
    'category',
    CategoryPalette.colors[15],
    transactions: [
      _SeedTransaction(1850, 0, 9, 'Postage and supplies'),
      _SeedTransaction(3500, 1, 15, 'Miscellaneous purchase'),
      _SeedTransaction(1200, 3, 18, 'Small cash expense'),
    ],
    monthlyBudgetCents: 10000,
  ),
  _SeedCategory(
    'Salary',
    'payments',
    CategoryPalette.colors[16],
    isIncome: true,
    transactions: [
      _SeedTransaction(785000, 0, 1, 'Monthly salary'),
      _SeedTransaction(785000, 1, 1, 'Monthly salary'),
      _SeedTransaction(760000, 2, 1, 'Monthly salary'),
      _SeedTransaction(760000, 3, 1, 'Monthly salary'),
      _SeedTransaction(745000, 4, 1, 'Monthly salary'),
    ],
  ),
  _SeedCategory(
    'Freelance',
    'laptop_mac',
    CategoryPalette.colors[17],
    isIncome: true,
    transactions: [
      _SeedTransaction(125000, 0, 6, 'Website project milestone'),
      _SeedTransaction(85000, 1, 13, 'Design consultation'),
      _SeedTransaction(210000, 2, 18, 'Mobile app project'),
      _SeedTransaction(65000, 4, 12, 'Logo design work'),
    ],
  ),
  _SeedCategory(
    'Investments',
    'trending_up',
    CategoryPalette.colors[18],
    isIncome: true,
    transactions: [
      _SeedTransaction(18450, 0, 9, 'Dividend payout'),
      _SeedTransaction(12900, 2, 10, 'Mutual fund distribution'),
      _SeedTransaction(22600, 4, 10, 'Quarterly dividend'),
    ],
  ),
  _SeedCategory(
    'Gifts & Other Income',
    'card_giftcard',
    CategoryPalette.colors[19],
    isIncome: true,
    transactions: [
      _SeedTransaction(5000, 0, 8, 'Birthday gift received'),
      _SeedTransaction(10000, 2, 15, 'Family contribution'),
      _SeedTransaction(2500, 4, 20, 'Cashback received'),
    ],
  ),
  _SeedCategory(
    'Business Income',
    'shopping_bag',
    CategoryPalette.colors[20],
    isIncome: true,
    transactions: [
      _SeedTransaction(245000, 0, 5, 'Store sales settlement'),
      _SeedTransaction(198000, 1, 7, 'Weekly sales settlement'),
      _SeedTransaction(275000, 2, 9, 'Store sales settlement'),
      _SeedTransaction(221000, 3, 8, 'Store sales settlement'),
    ],
  ),
  _SeedCategory(
    'Rental Income',
    'home',
    CategoryPalette.colors[21],
    isIncome: true,
    transactions: [
      _SeedTransaction(320000, 0, 3, 'Apartment rent'),
      _SeedTransaction(320000, 1, 3, 'Apartment rent'),
      _SeedTransaction(320000, 2, 3, 'Apartment rent'),
    ],
  ),
  _SeedCategory(
    'Refunds',
    'receipt_long',
    CategoryPalette.colors[22],
    isIncome: true,
    transactions: [
      _SeedTransaction(2599, 0, 4, 'Returned online order'),
      _SeedTransaction(4500, 1, 17, 'Cancelled booking refund'),
      _SeedTransaction(1299, 3, 11, 'Subscription refund'),
    ],
  ),
];

DateTime _dateForSample(DateTime now, int monthsAgo, int dayInMonth) {
  final monthAnchor = DateTime(now.year, now.month - monthsAgo, 1);
  final lastDay = DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
  final latestDay = monthsAgo == 0 ? now.day : lastDay;
  final day = dayInMonth.clamp(1, latestDay);
  return DateTime(monthAnchor.year, monthAnchor.month, day, 12);
}

Future<void> _cleanup(AppDatabase db) async {
  final seededCaptures = await (db.select(
    db.capturedTransactions,
  )..where((capture) => capture.sender.equals(_seedSender))).get();
  final autoAddedTransactionIds = seededCaptures
      .map((capture) => capture.transactionId)
      .whereType<int>()
      .toList();
  final categories = await (db.select(
    db.categories,
  )..where((category) => category.name.like('$_categoryPrefix%'))).get();
  final categoryIds = categories.map((category) => category.id).toList();

  await db.transaction(() async {
    if (autoAddedTransactionIds.isNotEmpty) {
      await (db.delete(db.transactions)..where(
            (transaction) => transaction.id.isIn(autoAddedTransactionIds),
          ))
          .go();
    }
    await (db.delete(
      db.capturedTransactions,
    )..where((capture) => capture.sender.equals(_seedSender))).go();
    await (db.delete(
      db.transactions,
    )..where((transaction) => transaction.note.like('$_notePrefix%'))).go();
    await (db.delete(db.transactions)..where(
          (transaction) => transaction.note.like('$_captureNotePrefix%'),
        ))
        .go();
    if (categoryIds.isNotEmpty) {
      await (db.delete(
        db.budgets,
      )..where((budget) => budget.categoryId.isIn(categoryIds))).go();
      await (db.delete(
        db.categories,
      )..where((category) => category.id.isIn(categoryIds))).go();
    }
  });
}

Future<void> _restorePreference(
  SharedPreferences prefs,
  String key,
  Object? previousValue,
) async {
  if (previousValue == null) {
    await prefs.remove(key);
  } else if (previousValue is bool) {
    await prefs.setBool(key, previousValue);
  } else if (previousValue is String) {
    await prefs.setString(key, previousValue);
  }
}

class _ManualCaptureEnabledNotifier extends AutoCaptureEnabledNotifier {
  _ManualCaptureEnabledNotifier(super.preferences) {
    state = true;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    state = enabled;
  }
}

class _NoopNotificationCaptureService implements NotificationCaptureService {
  @override
  Future<List<RawNotification>> drain() async => [];

  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<bool> openPermissionSettings() async => false;
}

class _SeedCategory {
  final String name;
  final String icon;
  final int color;
  final bool isIncome;
  final List<_SeedTransaction> transactions;
  final int? monthlyBudgetCents;

  const _SeedCategory(
    this.name,
    this.icon,
    this.color, {
    this.isIncome = false,
    required this.transactions,
    this.monthlyBudgetCents,
  });
}

class _SeedTransaction {
  final int amountCents;
  final int monthsAgo;
  final int dayInMonth;
  final String note;

  const _SeedTransaction(
    this.amountCents,
    this.monthsAgo,
    this.dayInMonth,
    this.note,
  );
}
