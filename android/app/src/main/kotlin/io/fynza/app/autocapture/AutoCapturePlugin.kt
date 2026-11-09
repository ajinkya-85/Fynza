package io.fynza.app.autocapture

import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AutoCapturePlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "io.fynza.app/auto_capture"

        fun register(context: Context, messenger: BinaryMessenger): AutoCapturePlugin {
            val channel = MethodChannel(messenger, CHANNEL)
            val plugin = AutoCapturePlugin(context)
            channel.setMethodCallHandler(plugin)
            return plugin
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "drainQueue" -> {
                try {
                    val events = AutoCaptureQueue.drain(context)
                    result.success(events)
                } catch (e: Exception) {
                    result.error("DRAIN_ERROR", e.message, null)
                }
            }
            "isNotificationListenerGranted" -> {
                try {
                    val packageName = context.packageName
                    val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(context)
                    val isGranted = enabledPackages.contains(packageName)
                    result.success(isGranted)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
            "openNotificationListenerSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SETTINGS_ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }
}

