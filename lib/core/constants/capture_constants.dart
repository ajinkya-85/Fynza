/// Global compile-time flag and constants for auto transaction capture.
class CaptureConstants {
  CaptureConstants._();

  /// Compile-time switch to enable or disable the entire auto-capture feature.
  /// Pass `--dart-define=AUTO_CAPTURE=false` to disable.
  static const bool isEnabled =
      bool.fromEnvironment('AUTO_CAPTURE', defaultValue: true);

  /// Standard Indian Rupee currency tokens.
  static const List<String> inrCurrencyTokens = [
    '₹',
    'rs.',
    'rs',
    'inr',
  ];

  /// Well-known Android SMS application packages.
  static const List<String> knownSmsPackages = [
    'com.google.android.apps.messaging', // Google Messages
    'com.samsung.android.messaging', // Samsung Messages
    'com.android.mms', // AOSP Messages
    'com.xiaomi.mms', // Xiaomi / MIUI SMS
    'com.oneplus.mms', // OnePlus SMS
    'com.oppo.mms', // Oppo SMS
    'com.coloros.mms', // Realme / ColorOS SMS
    'com.vivo.mms', // Vivo SMS
    'com.motorola.messaging', // Motorola SMS
    'com.truecaller', // Truecaller SMS
  ];

  /// Well-known UPI, wallet, and banking application packages.
  static const List<String> knownPaymentPackages = [
    // UPI apps
    'com.google.android.apps.nbu.paisa.user', // Google Pay
    'com.phonepe.app', // PhonePe
    'net.one97.paytm', // Paytm
    'in.org.npci.upiapp', // BHIM UPI
    'com.dreamplug.androidapp', // CRED
    'in.amazon.mShop.android.shopping', // Amazon Pay
    'com.samsung.android.spay', // Samsung Pay

    // Major Indian Banking apps
    'com.snapwork.hdfc', // HDFC Bank MobileBanking
    'com.enStage.wibmo.hdfc', // HDFC PayZapp
    'com.csam.icici.bank.imobile', // ICICI iMobile
    'com.sbi.lotusintouch', // SBI YONO
    'com.sbi.SBIFreedomPlus', // SBI YONO Lite
    'com.axis.mobile', // Axis Mobile
    'com.msf.kbank.mobile', // Kotak 811
    'com.bankofbaroda.mconnect', // BOB World
    'com.pnb.pnbone', // PNB One
    'com.canarabank.ai1', // Canara ai1
  ];

  /// Checks if the given package name belongs to a known SMS or payment app.
  static bool isSupportedPackage(String packageName) {
    final lower = packageName.toLowerCase();
    return knownSmsPackages.contains(lower) ||
        knownPaymentPackages.contains(lower) ||
        lower.contains('sms') ||
        lower.contains('mms') ||
        lower.contains('upi') ||
        lower.contains('pay');
  }
}
