class BackupEnvelopeDto {
  final int formatVersion;
  final String appVersion;
  final int dbSchemaVersion;
  final int createdAt;
  final BackupDataDto data;

  const BackupEnvelopeDto({
    required this.formatVersion,
    required this.appVersion,
    required this.dbSchemaVersion,
    required this.createdAt,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'formatVersion': formatVersion,
    'appVersion': appVersion,
    'dbSchemaVersion': dbSchemaVersion,
    'createdAt': createdAt,
    'data': data.toJson(),
  };

  factory BackupEnvelopeDto.fromJson(Map<String, dynamic> json) {
    return BackupEnvelopeDto(
      formatVersion: json['formatVersion'] as int,
      appVersion: json['appVersion'] as String? ?? '1.0.0',
      dbSchemaVersion: json['dbSchemaVersion'] as int? ?? 1,
      createdAt: json['createdAt'] as int,
      data: BackupDataDto.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class BackupDataDto {
  final List<CategoryDto> categories;
  final List<TransactionDto> transactions;
  final List<BudgetDto> budgets;
  final Map<String, dynamic> preferences;
  final List<CapturedTransactionDto> capturedTransactions;

  const BackupDataDto({
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.preferences,
    this.capturedTransactions = const [],
  });

  Map<String, dynamic> toJson() => {
    'categories': categories.map((c) => c.toJson()).toList(),
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'budgets': budgets.map((b) => b.toJson()).toList(),
    'preferences': preferences,
    if (capturedTransactions.isNotEmpty)
      'capturedTransactions': capturedTransactions
          .map((ct) => ct.toJson())
          .toList(),
  };

  factory BackupDataDto.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'] as List<dynamic>? ?? [];
    final rawTxs = json['transactions'] as List<dynamic>? ?? [];
    final rawBudgets = json['budgets'] as List<dynamic>? ?? [];
    final rawPrefs = json['preferences'] as Map<String, dynamic>? ?? {};
    final rawCaptures = json['capturedTransactions'] as List<dynamic>? ?? [];

    return BackupDataDto(
      categories: rawCats
          .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      transactions: rawTxs
          .map((e) => TransactionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      budgets: rawBudgets
          .map((e) => BudgetDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      preferences: Map<String, dynamic>.from(rawPrefs),
      capturedTransactions: rawCaptures
          .map(
            (e) => CapturedTransactionDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class CategoryDto {
  final int id;
  final String name;
  final String icon;
  final int color;
  final bool isIncome;

  const CategoryDto({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'isIncome': isIncome,
  };

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as int,
      isIncome: json['isIncome'] as bool? ?? false,
    );
  }
}

class TransactionDto {
  final int id;
  final int amount;
  final String type;
  final int categoryId;
  final int date;
  final String? note;
  final int createdAt;

  const TransactionDto({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type,
    'categoryId': categoryId,
    'date': date,
    if (note != null) 'note': note,
    'createdAt': createdAt,
  };

  factory TransactionDto.fromJson(Map<String, dynamic> json) {
    return TransactionDto(
      id: json['id'] as int,
      amount: json['amount'] as int,
      type: json['type'] as String,
      categoryId: json['categoryId'] as int,
      date: json['date'] as int,
      note: json['note'] as String?,
      createdAt: json['createdAt'] as int? ?? json['date'] as int,
    );
  }
}

class BudgetDto {
  final int id;
  final int categoryId;
  final int amountLimit;
  final int month;
  final int year;

  const BudgetDto({
    required this.id,
    required this.categoryId,
    required this.amountLimit,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'amountLimit': amountLimit,
    'month': month,
    'year': year,
  };

  factory BudgetDto.fromJson(Map<String, dynamic> json) {
    return BudgetDto(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int,
      amountLimit: json['amountLimit'] as int,
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }
}

class CapturedTransactionDto {
  final int id;
  final int amountCents;
  final String type;
  final String? counterparty;
  final String? accountLast4;
  final String? reference;
  final int occurredAt;
  final int capturedAt;
  final String sourcePackage;
  final String sender;
  final String dedupeKey;
  final String status;
  final int duplicateCount;
  final int? transactionId;
  final int? suggestedCategoryId;

  const CapturedTransactionDto({
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
    this.duplicateCount = 0,
    this.transactionId,
    this.suggestedCategoryId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amountCents': amountCents,
    'type': type,
    if (counterparty != null) 'counterparty': counterparty,
    if (accountLast4 != null) 'accountLast4': accountLast4,
    if (reference != null) 'reference': reference,
    'occurredAt': occurredAt,
    'capturedAt': capturedAt,
    'sourcePackage': sourcePackage,
    'sender': sender,
    'dedupeKey': dedupeKey,
    'status': status,
    if (duplicateCount > 0) 'duplicateCount': duplicateCount,
    if (transactionId != null) 'transactionId': transactionId,
    if (suggestedCategoryId != null) 'suggestedCategoryId': suggestedCategoryId,
  };

  factory CapturedTransactionDto.fromJson(Map<String, dynamic> json) {
    return CapturedTransactionDto(
      id: json['id'] as int,
      amountCents: json['amountCents'] as int,
      type: json['type'] as String,
      counterparty: json['counterparty'] as String?,
      accountLast4: json['accountLast4'] as String?,
      reference: json['reference'] as String?,
      occurredAt: json['occurredAt'] as int,
      capturedAt: json['capturedAt'] as int,
      sourcePackage: json['sourcePackage'] as String,
      sender: json['sender'] as String,
      dedupeKey: json['dedupeKey'] as String,
      status: json['status'] as String,
      duplicateCount: json['duplicateCount'] as int? ?? 0,
      transactionId: json['transactionId'] as int?,
      suggestedCategoryId: json['suggestedCategoryId'] as int?,
    );
  }
}
