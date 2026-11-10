import '../../../../shared/models/transaction_type.dart';
import '../models/capture_item.dart';
import '../models/raw_notification.dart';

abstract class CaptureRepository {
  Stream<List<CaptureItem>> watchPendingCaptures();
  Stream<int> watchPendingCount();
  Stream<List<CaptureItem>> watchRecentlyAutoAdded({int limit = 10});

  Future<void> ingest(List<RawNotification> notifications);

  Future<void> confirmCapture(
    int captureId, {
    required int categoryId,
    String? note,
    DateTime? date,
    int? amountCents,
    TransactionType? type,
  });

  Future<void> dismissCapture(int captureId);
  Future<void> undoDismiss(int captureId);
  Future<void> undoAutoAdd(int captureId);
  Future<void> ignoreSender(String sender);
  Future<void> deleteAllCapturedData();
  Future<void> purgeOldCaptures({
    Duration retentionPeriod = const Duration(days: 90),
  });
  Future<int?> getSuggestedCategory(String counterparty);
}
