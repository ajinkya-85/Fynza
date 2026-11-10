class Budget {
  final int id;
  final int categoryId;
  final int amountLimit;
  final int month;
  final int year;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.amountLimit,
    required this.month,
    required this.year,
  });
}
