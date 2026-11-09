import '../../../../shared/models/transaction_type.dart';
import 'capture_status.dart';

/// Represents a captured transaction domain entity.
class CaptureItem {
  final int id;
  final int amountCents;
  final TransactionType type;
  final String? counterparty;
  final String? accountLast4;
  final String? reference;
  final DateTime occurredAt;
  final DateTime capturedAt;
  final String sourcePackage;
  final String sender;
  final String dedupeKey;
  final CaptureStatus status;
  final int? transactionId;
  final int? suggestedCategoryId;
  final bool isPossibleDuplicate;

  const CaptureItem({
    required this.id,
    required this.amountCents,
    required this.type,
    this.counterparty,
    this.accountLast4,
    this.reference,
    required this.occurredAt,
    required this.capturedAt,
    required this.sourcePackage,
    required this.sender,
    required this.dedupeKey,
    required this.status,
    this.transactionId,
    this.suggestedCategoryId,
    this.isPossibleDuplicate = false,
  });
}
