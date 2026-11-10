package io.fynza.app.autocapture

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.provider.Telephony
import android.util.Log
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class SmsNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "FynzaAutoCapture"

        // Fallback list of well-known SMS package names
        private val KNOWN_SMS_PACKAGES = setOf(
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
            "com.xiaomi.mms",
            "com.oneplus.mms",
            "com.oppo.mms",
            "com.coloros.mms",
            "com.vivo.mms",
            "com.motorola.messaging",
            "com.truecaller"
        )

        // Well-known UPI, wallet, and banking application package names
        private val KNOWN_PAYMENT_PACKAGES = setOf(
            "com.google.android.apps.nbu.paisa.user",
            "com.phonepe.app",
            "net.one97.paytm",
            "in.org.npci.upiapp",
            "com.dreamplug.androidapp",
            "in.amazon.mShop.android.shopping",
            "com.samsung.android.spay",
            "com.snapwork.hdfc",
            "com.enStage.wibmo.hdfc",
            "com.csam.icici.bank.imobile",
            "com.sbi.lotusintouch",
            "com.sbi.SBIFreedomPlus",
            "com.axis.mobile",
            "com.msf.kbank.mobile",
            "com.bankofbaroda.mconnect",
            "com.pnb.pnbone",
            "com.canarabank.ai1"
        )

        // Currency markers for native pre-filter
        private val CURRENCY_REGEX = Regex("(?:Rs\\.?|INR|₹)\\s*[\\d,]+", RegexOption.IGNORE_CASE)

        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_MASTER_ENABLED = "flutter.auto_capture_master_enabled"
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        try {
            // Check master switch from SharedPreferences
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean(KEY_MASTER_ENABLED, false)
            if (!isEnabled) return

            val packageName = sbn.packageName ?: return

            // Rule 1: Ignore notifications with FLAG_GROUP_SUMMARY
            val notification = sbn.notification ?: return
            if ((notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) {
                return
            }

            // Rule 2: Package must be an SMS or payment/banking app
            val defaultSms = try {
                Telephony.Sms.getDefaultSmsPackage(this)
            } catch (e: Exception) {
                null
            }

            val lowerPackage = packageName.lowercase()
            val isSmsApp = (defaultSms != null && packageName.equals(defaultSms, ignoreCase = true)) ||
                    KNOWN_SMS_PACKAGES.contains(lowerPackage) ||
                    lowerPackage.contains("sms") ||
                    lowerPackage.contains("mms")

            val isPaymentApp = KNOWN_PAYMENT_PACKAGES.contains(lowerPackage) ||
                    lowerPackage.contains("upi") ||
                    lowerPackage.contains("pay")

            if (!isSmsApp && !isPaymentApp) {
                return
            }

            // Extract sender (title) and message text
            val extras = notification.extras ?: return
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
            val text = extractNotificationText(notification, extras)

            if (text.isEmpty()) return

            // Rule 3: Native pre-filter: queue only if currency marker is present
            if (!CURRENCY_REGEX.containsMatchIn(text)) {
                return
            }

            val postTime = sbn.postTime
            val key = sbn.key ?: "${packageName}_$postTime"

            AutoCaptureQueue.enqueue(
                context = applicationContext,
                key = key,
                packageName = packageName,
                title = title,
                text = text,
                postTime = postTime,
                isSmsApp = isSmsApp
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to process a notification", e)
        }
    }

    private fun extractNotificationText(notification: Notification, extras: Bundle): String {
        // Priority 1: EXTRA_BIG_TEXT
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim()
        if (!bigText.isNullOrEmpty()) {
            return bigText
        }

        // Priority 2: EXTRA_TEXT
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim()
        if (!text.isNullOrEmpty()) {
            return text
        }

        // Priority 3: EXTRA_MESSAGES (MessagingStyle)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val messages = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
            if (messages != null && messages.isNotEmpty()) {
                val sb = StringBuilder()
                for (msgObj in messages) {
                    if (msgObj is Bundle) {
                        val msgText = msgObj.getCharSequence("text")
                        if (!msgText.isNullOrEmpty()) {
                            if (sb.isNotEmpty()) sb.append(" ")
                            sb.append(msgText)
                        }
                    }
                }
                if (sb.isNotEmpty()) {
                    return sb.toString().trim()
                }
            }
        }

        return ""
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                requestRebind(ComponentName(this, SmsNotificationListenerService::class.java))
            } catch (e: Exception) {
                Log.w(TAG, "Failed to request notification listener rebind", e)
            }
        }
    }
}
