import 'package:drift/drift.dart';
import '../../../shared/models/transaction_type.dart';
import '../../../features/auto_capture/domain/models/capture_status.dart';

class CapturedTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountCents => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get counterparty => text().nullable()();
  TextColumn get accountLast4 => text().nullable()();
  TextColumn get reference => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get sourcePackage => text()();
  TextColumn get sender => text()();
  TextColumn get dedupeKey => text().unique()();
  TextColumn get status => textEnum<CaptureStatus>()();
  IntColumn get transactionId => integer()
      .nullable()
      .customConstraint('NULL REFERENCES transactions(id) ON DELETE SET NULL')();
  IntColumn get suggestedCategoryId => integer()
      .nullable()
      .customConstraint('NULL REFERENCES categories(id) ON DELETE SET NULL')();
}
