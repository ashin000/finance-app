import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../../services/database/database_service.dart';
import '../../services/sync/sync_service.dart';

class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  final DatabaseService _db = DatabaseService.instance;
  final SyncService _sync = SyncService.instance;

  TransactionsNotifier() : super([]) {
    loadTransactions();
    // Start background polling and auto-sync
    _sync.startAutoSync();
  }

  // Load transactions from local Hive database
  void loadTransactions() {
    state = _db.getTransactions();
  }

  // Add manual transaction
  Future<void> addTransaction({
    required double amount,
    required String type,
    required String category,
    required String description,
    required String bank,
    required String upiApp,
  }) async {
    final tx = TransactionModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_$amount',
      amount: amount,
      type: type,
      category: category,
      sender: type == 'Income' ? description : '',
      receiver: type == 'Expense' ? description : '',
      merchant: type == 'Expense' ? description : '',
      bank: bank,
      upiApp: upiApp,
      timestamp: DateTime.now(),
      notificationText: "Manually entered: $description",
      isSynced: false,
    );

    await _db.saveTransaction(tx);
    loadTransactions();
    
    // Trigger async sync to cloud
    _sync.syncTransactions();
  }

  // Edit/override transaction details (e.g., manual category updates)
  Future<void> updateTransaction(TransactionModel updatedTx) async {
    final newTx = updatedTx.copyWith(
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await _db.saveTransaction(newTx);
    loadTransactions();

    // Sync changes to cloud
    _sync.syncTransactions();
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    loadTransactions();
    // In production, we'd also flag it as deleted in Firestore or call FirebaseService to remove it
  }

  // Force trigger sync
  Future<void> syncNow() async {
    await _sync.pollFromNative();
    await _sync.syncTransactions();
    await _sync.syncFromCloud();
    loadTransactions();
  }

  @override
  void dispose() {
    _sync.stopAutoSync();
    super.dispose();
  }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>((ref) {
  return TransactionsNotifier();
});
