/// Table-driven keywords, token sets, and regex rules for Indian bank SMS parsing.
class ParserRules {
  ParserRules._();

  /// Currency markers (case-insensitive).
  static final RegExp currencyPattern = RegExp(
    r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  /// Isolated amount regex for extracting digits and decimals.
  static final RegExp amountPattern = RegExp(r'[\d,]+(?:\.\d{1,2})?');

  /// Indicators that the subsequent number is a balance or limit, NOT the spent amount.
  static final List<String> balanceIndicators = [
    'avl bal',
    'avail bal',
    'available bal',
    'avl balance',
    'avail balance',
    'available balance',
    'bal:',
    'bal ',
    'balance',
    'limit:',
    'limit ',
    'available limit',
    'credit limit',
    'total bal',
    'clr bal',
  ];

  /// Requires an explicit payment-completion signal before interpreting a
  /// recharge message as a real transaction rather than a plan promotion.
  static final List<RegExp> successfulRechargePatterns = [
    RegExp(
      r'\b(?:recharge|recharged)\b.{0,40}\b(?:success(?:ful(?:ly)?)?|completed|done)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(?:successful|successfully|completed)\b.{0,30}\brecharged\b',
      caseSensitive: false,
    ),
  ];

  /// Debit keywords -> Expense.
  static final List<String> debitKeywords = [
    'debited',
    'spent',
    'paid',
    'sent',
    'withdrawn',
    'purchase',
    'payment of',
    'payment done',
    'used at',
    'transferred to',
    'charged',
    'recharged',
  ];

  /// Credit keywords -> Income.
  static final List<String> creditKeywords = [
    'credited',
    'received',
    'deposited',
    'added to',
    'transferred from',
  ];

  /// Reversal / Refund keywords -> Income with refund context.
  static final List<String> reversalKeywords = [
    'refund',
    'refunded',
    'reversed',
    'reversal',
  ];

  /// Strong rejection keywords (OTP, Verification, Authentication).
  static final List<String> rejectionOtpKeywords = [
    'otp',
    'one time password',
    'verification code',
    'secret code',
    'do not share',
    'valid for',
    'security code',
  ];

  /// Promos, Offers, Loans, Statements, Mandates, Bills due, Future tense, Failures.
  static final List<String> rejectionKeywords = [
    // Promos / loans
    'pre-approved',
    'pre approved',
    'apply for',
    'get loan',
    'congratulations',
    'click here',
    'click http',
    'claim now',
    'win up to',
    'recharge now',
    'recharge offer',
    'special recharge',
    'recharge to get',
    'recharge and get',
    'get extra data',
    'free data',
    'unlimited calls',
    'data pack benefits',
    'enjoy exciting offers',
    // Statements / bills
    'minimum amount due',
    'min amount due',
    'statement generated',
    'total amount due',
    'bill generated',
    'bill is due',
    'payment due date',
    'due by',
    // Mandates & requests
    'mandate created',
    'mandate request',
    'collect request',
    'request to pay',
    'requested money',
    // Future / Scheduled
    'will be debited',
    'is scheduled',
    'scheduled for',
    // Failures
    'failed',
    'declined',
    'unsuccessful',
    'transaction failed',
    'rejected',
    'cancelled',
    'aborted',
    'could not be processed',
    'insufficient funds',
  ];

  /// Other foreign currency markers (if found without INR, reject).
  static final List<String> foreignCurrencies = [
    r'$',
    'usd',
    'eur',
    '€',
    'gbp',
    '£',
    'aed',
    'cad',
    'aud',
    'sgd',
  ];

  /// Account number regexes (last 4 digits).
  static final List<RegExp> accountPatterns = [
    RegExp(
      r'(?:A/c|Acct|Account|card|ending)\s*(?:no\.?)?\s*[*xX]*([0-9]{4})\b',
      caseSensitive: false,
    ),
    RegExp(r'[•*xX]{2,}\s*([0-9]{4})\b', caseSensitive: false),
    RegExp(
      r'([0-9]{4})\s*(?:is debited|was debited|credited)',
      caseSensitive: false,
    ),
  ];

  /// Reference / Transaction ID regexes.
  static final List<RegExp> referencePatterns = [
    RegExp(
      r'(?:UPI\s*Ref(?:\s*no)?|Ref\s*no|Reference\s*no|Txn(?:\s*Id)?|Transaction\s*ID|Google\s*transaction\s*ID|Google\s*Pay\s*ID|IMPS\s*Ref|RRN|UTR)[\s.:/=-]*([A-Za-z0-9]{6,25})\b',
      caseSensitive: false,
    ),
    RegExp(r'\bUPI/([A-Za-z0-9]{6,25})\b', caseSensitive: false),
    RegExp(r'\bRef[:\s]+([0-9]{6,20})\b', caseSensitive: false),
  ];

  /// Counterparty extraction prefixes.
  static final List<RegExp> counterpartyPatterns = [
    RegExp(
      r'(?:to|paid to|sent to|transfer to|payment of .* to|payment to|at|vpa|info:?|towards)\s+([A-Za-z0-9&@.\-_/\s]{2,40}?)(?=\s+(?:on|via|ref|upi|avl|bal|using|thru|dated|a/c|successfully|\.|$))',
      caseSensitive: false,
    ),
    RegExp(
      r'UPI/([A-Za-z0-9._\-]+)/([A-Za-z0-9\s._\-]+)/',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:from|received from)\s+([A-Za-z0-9&@.\-_/\s]{2,40}?)(?=\s+(?:on|via|ref|upi|avl|bal|using|thru|dated|a/c|successfully|\.|$))',
      caseSensitive: false,
    ),
  ];
}
