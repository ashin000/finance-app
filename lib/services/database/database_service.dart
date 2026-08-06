import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction_model.dart';

class DatabaseService {
  static const String _txBoxName = 'transactions';
  
  // Singleton instance
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  late Box<TransactionModel> _txBox;

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    
    // Open boxes
    _txBox = await Hive.openBox<TransactionModel>(_txBoxName);
  }

  // Transaction CRUD Operations
  List<TransactionModel> getTransactions() {
    return _txBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveTransaction(TransactionModel tx) async {
    await _txBox.put(tx.id, tx);
  }

  Future<void> saveTransactions(List<TransactionModel> txs) async {
    final Map<String, TransactionModel> map = {
      for (var tx in txs) tx.id: tx
    };
    await _txBox.putAll(map);
  }

  Future<void> deleteTransaction(String id) async {
    await _txBox.delete(id);
  }

  Future<void> clearAll() async {
    await _txBox.clear();
  }

  List<TransactionModel> getUnsyncedTransactions() {
    return _txBox.values.where((tx) => !tx.isSynced).toList();
  }

  Future<void> markAsSynced(String id) async {
    final tx = _txBox.get(id);
    if (tx != null) {
      await _txBox.put(id, tx.copyWith(isSynced: true));
    }
  }
}
