package com.example.quranglow

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "quranglow/device",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTimeZone" -> result.success(TimeZone.getDefault().id)
                else -> result.notImplemented()
            }
        }
    }
}
