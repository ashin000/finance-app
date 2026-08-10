import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_service.dart';
import '../firebase/firebase_service.dart';
import '../native/method_channel_service.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final DatabaseService _db = DatabaseService.instance;
  final FirebaseService _fb = FirebaseService.instance;
  final MethodChannelService _native = MethodChannelService.instance;

  Timer? _pollTimer;
  VoidCallback? onNewTransactionsPolled;

  // Start polling background notifications and checking sync status
  void startAutoSync({Duration interval = const Duration(seconds: 10)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) async {
      await pollFromNative();
      await syncTransactions();
    });
  }

  void stopAutoSync() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // Poll notifications caught natively by NotificationListenerService
  Future<void> pollFromNative() async {
    final pending = await _native.getPendingTransactions();
    if (pending.isNotEmpty) {
      debugPrint("Polled ${pending.length} new transactions from native listener.");
      await _db.saveTransactions(pending);
      onNewTransactionsPolled?.call();
    }
  }


  // Sync unsynced offline transactions to Firestore
  Future<void> syncTransactions() async {
    if (!_fb.isInitialized || _fb.currentUser == null) return;

    final unsynced = _db.getUnsyncedTransactions();
    if (unsynced.isEmpty) return;

    debugPrint("Syncing ${unsynced.length} transactions to cloud...");
    for (var tx in unsynced) {
      try {
        await _fb.syncTransactionToCloud(tx);
        await _db.markAsSynced(tx.id);
      } catch (e) {
        debugPrint("Failed to sync transaction ${tx.id}: $e");
      }
    }
  }

  // Pull all data from Firestore to populate local cache (on login/sync command)
  Future<void> syncFromCloud() async {
    if (!_fb.isInitialized || _fb.currentUser == null) return;

    debugPrint("Pulling transactions from Firestore...");
    final cloudTxs = await _fb.fetchTransactionsFromCloud();
    if (cloudTxs.isNotEmpty) {
      // Local merge: save all cloud transactions
      await _db.saveTransactions(cloudTxs);
      debugPrint("Pulled and cached ${cloudTxs.length} transactions from cloud.");
    }
  }
}
