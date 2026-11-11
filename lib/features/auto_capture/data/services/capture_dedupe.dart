import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../../shared/models/transaction_type.dart';

/// Generates deterministic deduplication keys for captured SMS transactions.
class CaptureDedupe {
  CaptureDedupe._();

  /// Creates a key from a scoped transaction reference or an exact source event.
  static String computeKey({
    required int amountCents,
    required TransactionType type,
    String? reference,
    String? accountLast4,
    required String sender,
    required String rawText,
    required String notificationKey,
    required String packageName,
    required int postTime,
  }) {
    if (reference != null && reference.trim().isNotEmpty) {
      return _hash([
        'reference',
        reference.trim().toLowerCase(),
        amountCents.toString(),
        type.name,
        accountLast4?.trim() ?? '',
      ]);
    }

    return _hash([
      'source-event',
      packageName.trim().toLowerCase(),
      notificationKey.trim(),
      postTime.toString(),
      sender.trim().toUpperCase(),
      type.name,
      amountCents.toString(),
      accountLast4?.trim() ?? '',
      normalizeText(rawText),
    ]);
  }

  static String _hash(List<String> components) {
    return sha256.convert(utf8.encode(components.join('|'))).toString();
  }

  /// Normalizes SMS text by stripping timestamps, whitespace, and case.
  static String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }
}
