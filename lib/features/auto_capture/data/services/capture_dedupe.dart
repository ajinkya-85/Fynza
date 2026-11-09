import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../../shared/models/transaction_type.dart';

/// Generates deterministic deduplication keys for captured SMS transactions.
class CaptureDedupe {
  CaptureDedupe._();

  /// Creates a SHA-256 dedupe key.
  /// - If [reference] is present, key = SHA256(reference).
  /// - Otherwise, key = SHA256(type + amountCents + accountLast4 + sender + normalizedText).
  static String computeKey({
    required int amountCents,
    required TransactionType type,
    String? reference,
    String? accountLast4,
    required String sender,
    required String rawText,
  }) {
    if (reference != null && reference.trim().isNotEmpty) {
      final cleanRef = reference.trim().toLowerCase();
      final bytes = utf8.encode('ref:$cleanRef');
      return sha256.convert(bytes).toString();
    }

    final normalized = normalizeText(rawText);
    final payload = [
      type.name,
      amountCents.toString(),
      accountLast4 ?? '',
      sender.trim().toUpperCase(),
      normalized,
    ].join('|');

    final bytes = utf8.encode(payload);
    return sha256.convert(bytes).toString();
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
