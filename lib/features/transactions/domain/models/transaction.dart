import '../../../../shared/models/transaction_type.dart';

class Transaction {
  final int id;
  final int amount;
  final TransactionType type;
  final int categoryId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    this.note,
  });
}
