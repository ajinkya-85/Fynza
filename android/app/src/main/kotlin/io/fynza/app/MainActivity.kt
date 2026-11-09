package io.fynza.app

import io.fynza.app.autocapture.AutoCapturePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AutoCapturePlugin.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }
}

