import 'package:fynza/features/auto_capture/domain/models/capture_item.dart';
import 'package:fynza/features/auto_capture/domain/models/capture_status.dart';
import 'package:fynza/features/auto_capture/presentation/views/capture_inbox_grouping.dart';
import 'package:fynza/shared/models/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

CaptureItem _capture({
  required int id,
  required DateTime date,
  String? reference,
  String? accountLast4,
  String? counterparty,
  String sender = 'HDFCBK',
  bool isPossibleDuplicate = true,
}) {
  return CaptureItem(
    id: id,
    amountCents: 2500,
    type: TransactionType.expense,
    counterparty: counterparty,
    accountLast4: accountLast4,
    reference: reference,
    occurredAt: date,
    capturedAt: date,
    sourcePackage: 'com.google.android.apps.messaging',
    sender: sender,
    dedupeKey: 'key_$id',
    status: CaptureStatus.pending,
    isPossibleDuplicate: isPossibleDuplicate,
  );
}

void main() {
  group('groupPendingCaptures', () {
    final date = DateTime(2026, 11, 10, 12);

    test('groups duplicate captures with the same transaction reference', () {
      final groups = groupPendingCaptures([
        _capture(id: 1, date: date, reference: 'ref-123'),
        _capture(
          id: 2,
          date: date.add(const Duration(hours: 1)),
          reference: 'ref-123',
          sender: 'PHONEPE',
        ),
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.items.map((item) => item.id), [1, 2]);
      expect(groups.single.hasMultiple, isTrue);
    });

    test('keeps distinct references as separate transactions', () {
      final groups = groupPendingCaptures([
        _capture(id: 1, date: date, reference: 'ref-123'),
        _capture(id: 2, date: date, reference: 'ref-456'),
      ]);

      expect(groups, hasLength(2));
    });

    test(
      'groups matching sender and near-simultaneous captures without refs',
      () {
        final groups = groupPendingCaptures([
          _capture(id: 1, date: date, isPossibleDuplicate: false),
          _capture(id: 2, date: date.add(const Duration(minutes: 2))),
        ]);

        expect(groups, hasLength(1));
        expect(groups.single.hasMultiple, isTrue);
      },
    );
  });
}
