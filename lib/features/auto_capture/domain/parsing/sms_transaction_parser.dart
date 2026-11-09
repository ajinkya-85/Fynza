import '../../../../shared/models/transaction_type.dart';
import '../models/parsed_transaction.dart';
import 'parser_rules.dart';

/// Pure Dart SMS transaction parser with zero Flutter dependencies or I/O.
class SmsTransactionParser {
  const SmsTransactionParser();

  /// Parses string amount into exact integer cents using string manipulation.
  /// Never parses through `double`.
  /// Examples:
  /// - `1,234.5` -> 123450
  /// - `5,00,000` -> 50000000
  /// - `0.99` -> 99
  /// - `50` -> 5000
  static int? parseAmountStringToCents(String raw) {
    var cleaned = raw.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;

    final parts = cleaned.split('.');
    if (parts.length > 2) return null;

    final integerPart = parts[0];
    if (integerPart.isEmpty && parts.length == 1) return null;

    final intVal = int.tryParse(integerPart.isEmpty ? '0' : integerPart);
    if (intVal == null) return null;

    int cents = intVal * 100;
    if (parts.length == 2) {
      var fraction = parts[1];
      if (fraction.length == 1) {
        fraction += '0';
      } else if (fraction.length > 2) {
        fraction = fraction.substring(0, 2);
      }
      final fracVal = int.tryParse(fraction);
      if (fracVal == null) return null;
      cents += fracVal;
    }

    return cents > 0 ? cents : null;
  }

  /// Pure function to parse an SMS message and return a [ParseResult].
  ParseResult parse(String text, DateTime postedAt) {
    final lowerText = text.toLowerCase();

    // 1. Check for OTP / Security keywords
    for (final otp in ParserRules.rejectionOtpKeywords) {
      if (lowerText.contains(otp)) {
        return const NotATransaction('OTP or verification code message');
      }
    }

    // 2. Check for other rejection rules (promos, statements, failed, future tense)
    for (final rej in ParserRules.rejectionKeywords) {
      if (lowerText.contains(rej)) {
        return NotATransaction('Rejected keyword found: $rej');
      }
    }

    // 3. Currency check: Must not contain foreign currencies without INR
    final hasInr = ParserRules.currencyPattern.hasMatch(text);
    if (!hasInr) {
      return const NotATransaction('No INR currency marker found');
    }

    for (final foreign in ParserRules.foreignCurrencies) {
      if (lowerText.contains(foreign)) {
        // e.g. "USD 50"
        return const NotATransaction('Foreign currency detected');
      }
    }

    // 4. Transaction type detection
    bool isDebit = false;
    bool isCredit = false;
    bool isReversal = false;

    for (final rev in ParserRules.reversalKeywords) {
      if (lowerText.contains(rev)) {
        isReversal = true;
        break;
      }
    }

    for (final deb in ParserRules.debitKeywords) {
      if (lowerText.contains(deb)) {
        isDebit = true;
        break;
      }
    }

    for (final cred in ParserRules.creditKeywords) {
      if (lowerText.contains(cred)) {
        isCredit = true;
        break;
      }
    }

    if (isReversal) {
      // Reversals/refunds are treated as income
      isCredit = true;
      isDebit = false;
    } else if (isDebit && isCredit) {
      return const NotATransaction('Ambiguous debit and credit keywords');
    } else if (!isDebit && !isCredit) {
      return const NotATransaction('No debit or credit keyword found');
    }

    final type = isDebit ? TransactionType.expense : TransactionType.income;

    // 5. Amount extraction
    final amountCents = _extractTransactionAmount(text);
    if (amountCents == null || amountCents <= 0) {
      return const NotATransaction('Could not extract valid transaction amount');
    }

    // 6. Account number last 4 digits
    final accountLast4 = _extractAccountLast4(text);

    // 7. Reference number (UPI Ref / Txn ID)
    final reference = _extractReference(text);

    // 8. Counterparty extraction
    final counterparty = _extractCounterparty(text, isDebit: isDebit);

    // 9. Confidence assessment
    // High: amount + unambiguous type + (reference or accountLast4)
    // Medium: reversal/refund or missing both reference and account
    final isHigh = !isReversal &&
        (reference != null && reference.isNotEmpty ||
            accountLast4 != null && accountLast4.isNotEmpty);

    final confidence =
        isHigh ? ParseConfidence.high : ParseConfidence.medium;

    return ParsedTransaction(
      amountCents: amountCents,
      type: type,
      counterparty: counterparty,
      accountLast4: accountLast4,
      reference: reference,
      confidence: confidence,
    );
  }

  /// Extracts the main transaction amount, ignoring balances/limits.
  int? _extractTransactionAmount(String text) {
    final matches = ParserRules.currencyPattern.allMatches(text).toList();
    if (matches.isEmpty) return null;

    final lower = text.toLowerCase();

    for (final match in matches) {
      final matchStart = match.start;
      final precedingText = lower.substring(
        (matchStart - 35).clamp(0, matchStart),
        matchStart,
      );

      // Check if this amount is right after a balance indicator
      bool isBalance = false;
      for (final bal in ParserRules.balanceIndicators) {
        if (precedingText.contains(bal)) {
          isBalance = true;
          break;
        }
      }

      if (!isBalance) {
        final rawAmount = match.group(1);
        if (rawAmount != null) {
          final cents = parseAmountStringToCents(rawAmount);
          if (cents != null && cents > 0) {
            return cents;
          }
        }
      }
    }

    // Fallback if the first match was not balance-prefixed
    final firstRaw = matches.first.group(1);
    if (firstRaw != null) {
      return parseAmountStringToCents(firstRaw);
    }
    return null;
  }

  String? _extractAccountLast4(String text) {
    for (final pattern in ParserRules.accountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final acc = match.group(1);
        if (acc != null && acc.length == 4) {
          return acc;
        }
      }
    }
    return null;
  }

  String? _extractReference(String text) {
    for (final pattern in ParserRules.referencePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final ref = match.group(1)?.trim();
        if (ref != null && ref.isNotEmpty) {
          return ref;
        }
      }
    }
    return null;
  }

  String? _extractCounterparty(String text, {required bool isDebit}) {
    for (final pattern in ParserRules.counterpartyPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        // Check group 2 for UPI/xxx/yyy patterns
        String? cp = match.groupCount >= 2 && match.group(2) != null
            ? match.group(2)
            : match.group(1);

        if (cp != null) {
          cp = _cleanCounterparty(cp);
          if (cp.isNotEmpty && cp.length >= 2) {
            return cp;
          }
        }
      }
    }
    return null;
  }

  String _cleanCounterparty(String raw) {
    var cleaned = raw
        .replaceAll(RegExp(r'^(?:vpa|info:|towards|to|from)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[@/][A-Za-z0-9._\-]+$'), '') // strip @okaxis / @upi handles
        .replaceAll(RegExp(r'[*]+'), '')
        .trim();

    // Remove trailing punctuation
    cleaned = cleaned.replaceAll(RegExp(r'[\.,\-_/]+$'), '').trim();

    // If it's pure digits or too generic, return empty
    if (RegExp(r'^\d+$').hasMatch(cleaned)) return '';
    return cleaned;
  }
}
