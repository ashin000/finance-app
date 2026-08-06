import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../services/firebase/firebase_service.dart';

class BudgetState {
  final Map<String, double> categoryBudgets; // e.g. {'Food': 6000.0, 'Groceries': 5000.0}
  final double totalBudget;
  final bool isLoading;

  BudgetState({
    this.categoryBudgets = const {},
    this.totalBudget = 0.0,
    this.isLoading = false,
  });

  BudgetState copyWith({
    Map<String, double>? categoryBudgets,
    double? totalBudget,
    bool? isLoading,
  }) {
    return BudgetState(
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      totalBudget: totalBudget ?? this.totalBudget,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BudgetsNotifier extends StateNotifier<BudgetState> {
  final FirebaseService _fb = FirebaseService.instance;
  late SharedPreferences _prefs;

  BudgetsNotifier() : super(BudgetState()) {
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    state = state.copyWith(isLoading: true);
    _prefs = await SharedPreferences.getInstance();
    
    // Load local budget configuration
    final total = _prefs.getDouble('total_budget') ?? 30000.0;
    
    final catBudgets = <String, double>{};
    // List of categories
    final categories = [
      'Food', 'Groceries', 'Fuel', 'Shopping', 'EMI', 'Bills', 
      'Electricity', 'Internet', 'Rent', 'Entertainment', 
      'Education', 'Healthcare', 'Travel', 'Subscription'
    ];
    for (var cat in categories) {
      final val = _prefs.getDouble('budget_$cat');
      if (val != null) catBudgets[cat] = val;
    }

    state = BudgetState(
      categoryBudgets: catBudgets,
      totalBudget: total,
      isLoading: false,
    );

    // If online, fetch latest from Firestore to sync
    if (_fb.isInitialized && _fb.currentUser != null) {
      try {
        final cloudBudgets = await _fb.fetchBudgetsFromCloud('Monthly');
        if (cloudBudgets.isNotEmpty) {
          final updatedCatBudgets = Map<String, double>.from(state.categoryBudgets);
          cloudBudgets.forEach((cat, limit) {
            updatedCatBudgets[cat] = limit;
            _prefs.setDouble('budget_$cat', limit);
          });
          
          state = state.copyWith(
            categoryBudgets: updatedCatBudgets,
          );
        }
      } catch (e) {
        debugPrint("Failed to sync cloud budgets: $e");
      }
    }
  }

  Future<void> setCategoryBudget(String category, double limit) async {
    await _prefs.setDouble('budget_$category', limit);
    final updated = Map<String, double>.from(state.categoryBudgets);
    updated[category] = limit;
    state = state.copyWith(categoryBudgets: updated);

    // Sync to Firebase if authenticated
    if (_fb.isInitialized && _fb.currentUser != null) {
      await _fb.syncBudgetsToCloud(category, limit, 'Monthly');
    }
  }

  Future<void> setTotalBudget(double limit) async {
    await _prefs.setDouble('total_budget', limit);
    state = state.copyWith(totalBudget: limit);

    // Sync total to Firebase
    if (_fb.isInitialized && _fb.currentUser != null) {
      await _fb.syncBudgetsToCloud('Total', limit, 'Monthly');
    }
  }
}

final budgetsProvider = StateNotifierProvider<BudgetsNotifier, BudgetState>((ref) {
  return BudgetsNotifier();
});
