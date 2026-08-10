import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../models/transaction_model.dart';

class MethodChannelService {
  static const MethodChannel _channel = MethodChannel('com.payvoice.ai/notifications');

  static final MethodChannelService instance = MethodChannelService._internal();
  MethodChannelService._internal();

  // Check if NotificationListenerService access is enabled
  Future<bool> isNotificationPermissionGranted() async {
    if (kIsWeb) return true;
    try {
      final bool granted = await _channel.invokeMethod('isNotificationListenerPermissionGranted');
      return granted;
    } on PlatformException catch (e) {
      debugPrint("Failed to check notification permission: ${e.message}");
      return false;
    }
  }

  // Request NotificationListenerService access
  Future<void> openNotificationPermissionSettings() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open notification permission settings: ${e.message}");
    }
  }

  // Fetch and clear transactions parsed natively in background
  Future<List<TransactionModel>> getPendingTransactions() async {
    if (kIsWeb) return [];
    try {
      final String jsonString = await _channel.invokeMethod('getPendingTransactions');
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return TransactionModel.fromNativeJson(map);
      }).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to fetch pending transactions: ${e.message}");
      return [];
    } catch (e) {
      debugPrint("Failed parsing pending transactions: $e");
      return [];
    }
  }

  // Open device biometric/security settings to register fingerprint
  Future<void> openBiometricSettings() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('openBiometricSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open biometric settings: ${e.message}");
    }
  }
}
