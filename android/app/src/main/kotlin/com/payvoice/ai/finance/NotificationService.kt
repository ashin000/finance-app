package com.payvoice.ai.finance

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.speech.tts.TextToSpeech
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

class NotificationService : NotificationListenerService(), TextToSpeech.OnInitListener {

    private val TAG = "PayVoiceNotification"
    private var tts: TextToSpeech? = null
    private var isTtsReady = false

    override fun onCreate() {
        super.onCreate()
        initializeTTS()
        Log.d(TAG, "Notification Service Created")
    }

    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        super.onDestroy()
        Log.d(TAG, "Notification Service Destroyed")
    }

    private fun initializeTTS() {
        tts = TextToSpeech(applicationContext, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            isTtsReady = true
            updateTTSLanguage()
            Log.d(TAG, "TTS Initialized Successfully")
        } else {
            Log.e(TAG, "TTS Initialization Failed")
        }
    }

    private fun updateTTSLanguage() {
        if (!isTtsReady || tts == null) return
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val langCode = prefs.getString("flutter.tts_language", "en") ?: "en"
        val locale = when (langCode) {
            "hi" -> Locale("hi", "IN")
            "ta" -> Locale("ta", "IN")
            else -> Locale.US
        }
        val result = tts?.setLanguage(locale)
        if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
            Log.e(TAG, "Language $langCode is not supported or missing data")
            tts?.setLanguage(Locale.US)
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName
        val extras = sbn.notification.extras
        val title = extras.getString("android.title")
        val text = extras.getCharSequence("android.text")?.toString()

        Log.d(TAG, "Notification received from package: $packageName")
        Log.d(TAG, "Title: $title | Text: $text")

        if (text == null) return

        // Check if package is enabled for parsing
        if (!isPackageEnabled(packageName)) {
            Log.d(TAG, "Package $packageName is disabled. Skipping.")
            return
        }

        // Parse notification
        val parsed = parseNotification(title, text, packageName)
        if (parsed != null) {
            Log.d(TAG, "Parsed Transaction: Amount=${parsed.amount}, Type=${parsed.type}")
            
            // Store transaction locally
            saveTransactionToSharedPrefs(parsed)

            // Trigger TTS if enabled
            speakTransaction(parsed)

            // Notify Flutter app (if active)
            val intent = Intent("com.payvoice.ai.NEW_TRANSACTION")
            sendBroadcast(intent)
        }
    }

    private fun isPackageEnabled(packageName: String): Boolean {
        val targetPackages = setOf(
            "com.google.android.apps.nbu.paisa.user", // Google Pay
            "com.phonepe.app",                       // PhonePe
            "net.one97.paytm",                       // Paytm
            "in.org.npci.upiapp",                    // BHIM
            "com.amazon.mShop.android.shopping",      // Amazon Pay
            "co.cred.android",                       // CRED
            "com.sbi.upi", "com.sbi.SBIOnyx", "com.sbi.yono", // SBI
            "com.snapwork.hdfc", "com.hdfcbank.smartbuy",     // HDFC
            "com.csg.icici", "com.icicibank.imobile",         // ICICI
            "com.axis.mobile",                       // Axis
            "com.msf.kbank.mobile",                  // Kotak
            "com.canarabank.mobility",               // Canara
            "com.indianbank.mobilebanking",          // Indian Bank
            "com.unionbank.corporate", "com.unionbank.retail", // Union Bank
            "com.fedmobile"                          // Federal Bank
        )

        if (!targetPackages.contains(packageName)) {
            return false
        }

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Check if user has explicitly toggled this package off
        // Key is structured as "flutter.app_enabled_<packageName>"
        val key = "flutter.app_enabled_$packageName"
        return prefs.getBoolean(key, true)
    }

    private fun parseNotification(title: String?, text: String, packageName: String): ParsedTransaction? {
        val cleanText = text.replace(Regex("\\s+"), " ")

        // Amount Regex (matching ₹, Rs, Rs., INR followed by standard amounts like 500, 1,250.00, etc.)
        val amountRegex = Regex("(?:Rs\\.?|INR|₹)\\s*([\\d,]+(?:\\.\\d{2})?)", RegexOption.IGNORE_CASE)
        val amountMatch = amountRegex.find(cleanText) ?: (title?.let { amountRegex.find(it) })
        val amountStr = amountMatch?.groupValues?.get(1)?.replace(",", "")
        val amount = amountStr?.toDoubleOrNull() ?: return null

        // Determine App Name from packageName
        val appName = when {
            packageName.contains("nbu.paisa") -> "Google Pay"
            packageName.contains("phonepe") -> "PhonePe"
            packageName.contains("paytm") -> "Paytm"
            packageName.contains("upiapp") -> "BHIM"
            packageName.contains("amazon") -> "Amazon Pay"
            packageName.contains("cred") -> "CRED"
            packageName.contains("sbi") -> "SBI YONO"
            packageName.contains("hdfc") -> "HDFC Bank"
            packageName.contains("icici") -> "ICICI iMobile"
            packageName.contains("axis") -> "Axis Bank"
            packageName.contains("kbank") -> "Kotak Bank"
            packageName.contains("canarabank") -> "Canara Bank"
            packageName.contains("indianbank") -> "Indian Bank"
            packageName.contains("unionbank") -> "Union Bank"
            packageName.contains("fedmobile") -> "Federal Bank"
            else -> "Bank App"
        }

        var type = "Expense"
        var sender = ""
        var receiver = ""
        var merchant = ""
        var bank = ""
        
        val textLower = cleanText.lowercase()

        when {
            // Cashback / Refunds
            textLower.contains("cashback") -> {
                type = "Cashback"
                sender = appName
            }
            textLower.contains("refund") -> {
                type = "Refund"
                sender = "Merchant"
            }
            textLower.contains("failed") || textLower.contains("declined") -> {
                type = "Failed Payment"
            }
            textLower.contains("pending") || textLower.contains("requested") -> {
                type = "Pending Transaction"
            }
            // Received / Credited
            textLower.contains("received") || textLower.contains("credited") || textLower.contains("deposited") || textLower.contains("added") -> {
                type = "Income"
                val fromMatch = Regex("(?:received from|credited by|from)\\s+([^.]+)", RegexOption.IGNORE_CASE).find(cleanText)
                if (fromMatch != null) {
                    sender = cleanUnwantedSuffix(fromMatch.groupValues[1])
                }
            }
            // Sent / Paid / Debited
            textLower.contains("paid to") || textLower.contains("sent to") || textLower.contains("debited") || textLower.contains("transferred") || textLower.contains("spent") -> {
                type = "Expense"
                val toMatch = Regex("(?:paid to|sent to|transferred to|to)\\s+([^.]+)", RegexOption.IGNORE_CASE).find(cleanText)
                if (toMatch != null) {
                    receiver = cleanUnwantedSuffix(toMatch.groupValues[1])
                    merchant = receiver
                }
            }
        }

        // Extract bank if mentioned
        if (textLower.contains("sbi") || appName == "SBI YONO") bank = "SBI"
        else if (textLower.contains("hdfc") || appName == "HDFC Bank") bank = "HDFC"
        else if (textLower.contains("icici") || appName == "ICICI iMobile") bank = "ICICI"
        else if (textLower.contains("axis") || appName == "Axis Bank") bank = "Axis"
        else if (textLower.contains("kotak") || appName == "Kotak Bank") bank = "Kotak"

        return ParsedTransaction(
            amount = amount,
            type = type,
            sender = sender,
            receiver = receiver,
            merchant = merchant,
            bank = bank,
            upiApp = appName,
            timestamp = System.currentTimeMillis(),
            notificationText = cleanText
        )
    }

    private fun cleanUnwantedSuffix(text: String): String {
        var clean = text
        val suffixes = listOf(
            "Ref", "RefNo", "UTR", "Transaction ID", "via", "on", "using", "A/c", "Account", "at", "towards", "from", "for"
        )
        for (s in suffixes) {
            val idx = clean.indexOf(" $s", ignoreCase = true)
            if (idx != -1) {
                clean = clean.substring(0, idx)
            }
        }
        return clean.trim().removeSuffix(".").removeSuffix(",").trim()
    }

    private fun saveTransactionToSharedPrefs(tx: ParsedTransaction) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val jsonArrayStr = prefs.getString("flutter.pending_transactions", "[]") ?: "[]"
        
        try {
            val jsonArray = JSONArray(jsonArrayStr)
            val txJson = JSONObject().apply {
                put("amount", tx.amount)
                put("type", tx.type)
                put("sender", tx.sender)
                put("receiver", tx.receiver)
                put("merchant", tx.merchant)
                put("bank", tx.bank)
                put("upiApp", tx.upiApp)
                put("timestamp", tx.timestamp)
                put("notificationText", tx.notificationText)
            }
            jsonArray.put(txJson)
            prefs.edit().putString("flutter.pending_transactions", jsonArray.toString()).apply()
            Log.d(TAG, "Transaction saved to SharedPreferences cache successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving transaction to SharedPreferences: ${e.message}")
        }
    }

    private fun speakTransaction(tx: ParsedTransaction) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val ttsEnabled = prefs.getBoolean("flutter.tts_enabled", true)
        if (!ttsEnabled) {
            Log.d(TAG, "TTS announcements are disabled. Silence.")
            return
        }

        // Check Silent Hours
        val silentHoursEnabled = prefs.getBoolean("flutter.silent_hours_enabled", false)
        if (silentHoursEnabled) {
            val startStr = prefs.getString("flutter.silent_hours_start", "22:00") ?: "22:00"
            val endStr = prefs.getString("flutter.silent_hours_end", "06:00") ?: "06:00"
            if (isCurrentTimeInSilentHours(startStr, endStr)) {
                Log.d(TAG, "Currently in silent hours. Silence.")
                return
            }
        }

        updateTTSLanguage()
        val langCode = prefs.getString("flutter.tts_language", "en") ?: "en"
        val speechText = generateAnnouncement(tx, langCode)

        // Set TTS Volume and Speech Rate
        val speechRate = prefs.getFloat("flutter.tts_speed", 1.0f)
        val speechVolume = prefs.getFloat("flutter.tts_volume", 1.0f)

        tts?.setSpeechRate(speechRate)
        
        val params = Bundle()
        params.putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, speechVolume)

        tts?.speak(speechText, TextToSpeech.QUEUE_FLUSH, params, "transaction_speech_id")
        Log.d(TAG, "Announced: $speechText (Speed: $speechRate, Volume: $speechVolume)")
    }

    private fun isCurrentTimeInSilentHours(start: String, end: String): Boolean {
        try {
            val sdf = java.text.SimpleDateFormat("HH:mm", Locale.US)
            val nowStr = sdf.format(java.util.Date())
            val nowTime = sdf.parse(nowStr)
            val startTime = sdf.parse(start)
            val endTime = sdf.parse(end)

            if (nowTime == null || startTime == null || endTime == null) return false

            return if (startTime.before(endTime)) {
                nowTime.after(startTime) && nowTime.before(endTime)
            } else {
                // Over midnight silent hours (e.g. 22:00 to 06:00)
                nowTime.after(startTime) || nowTime.before(endTime)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating silent hours: ${e.message}")
            return false
        }
    }

    private fun generateAnnouncement(tx: ParsedTransaction, lang: String): String {
        val amountInt = tx.amount.toInt()
        val amountText = if (tx.amount % 1.0 == 0.0) "$amountInt" else String.format("%.2f", tx.amount)

        return when (lang) {
            "hi" -> { // Hindi
                when (tx.type) {
                    "Income" -> {
                        val senderName = if (tx.sender.isNotEmpty()) tx.sender else "अज्ञात"
                        "$senderName se $amountText rupaye praapt hue."
                    }
                    "Expense" -> {
                        val recName = if (tx.receiver.isNotEmpty()) tx.receiver else "व्यापாரி"
                        "$recName ko $amountText rupaye ka bhugtan kiya gaya."
                    }
                    "Refund" -> "Rupaye $amountText ka refund mila."
                    "Cashback" -> "Rupaye $amountText ka cashback mila."
                    else -> "Rupaye $amountText ki transaction hui."
                }
            }
            "ta" -> { // Tamil
                when (tx.type) {
                    "Income" -> {
                        val senderName = if (tx.sender.isNotEmpty()) tx.sender else "யாரோ"
                        "$senderName இடமிருந்து $amountText ரூபாய் பெறப்பட்டது."
                    }
                    "Expense" -> {
                        val recName = if (tx.receiver.isNotEmpty()) tx.receiver else "வணிகர்"
                        "$recName க்கு $amountText ரூபாய் செலுத்தப்பட்டது."
                    }
                    "Refund" -> "ரூபாய் $amountText திரும்பப் பெறப்பட்டது."
                    "Cashback" -> "ரூபாய் $amountText கேஷ்பேக் பெறப்பட்டது."
                    else -> "ரூபாய் $amountText பரிவர்த்தனை செய்யப்பட்டது."
                }
            }
            else -> { // English (default)
                when (tx.type) {
                    "Income" -> {
                        val senderName = if (tx.sender.isNotEmpty()) tx.sender else "someone"
                        "Rupees $amountText received from $senderName."
                    }
                    "Expense" -> {
                        val recName = if (tx.receiver.isNotEmpty()) tx.receiver else "merchant"
                        "Rupees $amountText paid to $recName."
                    }
                    "Refund" -> "Refund of Rupees $amountText received."
                    "Cashback" -> "Cashback of Rupees $amountText received."
                    else -> "Transaction of Rupees $amountText detected."
                }
            }
        }
    }
}

data class ParsedTransaction(
    val amount: Double,
    val type: String,
    val sender: String,
    val receiver: String,
    val merchant: String,
    val bank: String,
    val upiApp: String,
    val timestamp: Long,
    val notificationText: String
)
