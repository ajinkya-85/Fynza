import '../../../../shared/models/transaction_type.dart';

enum ParseConfidence {
  high,
  medium,
}

/// Sealed result from parsing an SMS text.
sealed class ParseResult {
  const ParseResult();
}

/// Successfully parsed financial transaction.
class ParsedTransaction extends ParseResult {
  final int amountCents;
  final TransactionType type;
  final String? counterparty;
  final String? accountLast4;
  final String? reference;
  final ParseConfidence confidence;

  const ParsedTransaction({
    required this.amountCents,
    required this.type,
    this.counterparty,
    this.accountLast4,
    this.reference,
    required this.confidence,
  });
}

/// The SMS was rejected and not parsed as a financial transaction.
class NotATransaction extends ParseResult {
  final String reason;

  const NotATransaction(this.reason);
}
