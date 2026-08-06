package com.payvoice.ai.finance

import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.payvoice.ai/notifications"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerPermissionGranted" -> {
                    result.success(isNotificationListenerPermissionGranted())
                }
                "openNotificationListenerSettings" -> {
                    openNotificationListenerSettings()
                    result.success(true)
                }
                "getPendingTransactions" -> {
                    result.success(getPendingTransactions())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isNotificationListenerPermissionGranted(): Boolean {
        val cn = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        val packageName = packageName
        return cn != null && cn.contains(packageName)
    }

    private fun openNotificationListenerSettings() {
        val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun getPendingTransactions(): String {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val listStr = prefs.getString("flutter.pending_transactions", "[]") ?: "[]"
        
        // Clear the cache after retrieval
        prefs.edit().putString("flutter.pending_transactions", "[]").apply()
        return listStr
    }
}
