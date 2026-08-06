import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../transactions/transactions_provider.dart';
import 'budgets_provider.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetsProvider);
    final transactions = ref.watch(transactionsProvider);

    // Sum monthly expenses by category
    final now = DateTime.now();
    final thisMonthExpenses = transactions.where((tx) =>
        tx.type == 'Expense' &&
        tx.timestamp.month == now.month &&
        tx.timestamp.year == now.year);

    final Map<String, double> categorySpent = {};
    for (var tx in thisMonthExpenses) {
      categorySpent[tx.category] = (categorySpent[tx.category] ?? 0) + tx.amount;
    }

    final categories = [
      'Food', 'Groceries', 'Fuel', 'Shopping', 'EMI', 'Bills', 
      'Electricity', 'Internet', 'Rent', 'Entertainment', 
      'Education', 'Healthcare', 'Travel', 'Subscription'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Budgets Tracker"),
      ),
      body: budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Budget Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.glassDecoration(context: context, opacity: 0.9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TOTAL MONTHLY BUDGET LIMIT",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondaryLight,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "₹${budgetState.totalBudget.toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryLight),
                              onPressed: () => _showEditBudgetDialog(context, ref, 'Total', budgetState.totalBudget),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Category-wise Limits",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ...categories.map((cat) {
                    final limit = budgetState.categoryBudgets[cat] ?? 0.0;
                    final spent = categorySpent[cat] ?? 0.0;
                    final remaining = limit - spent;
                    final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Title & Action Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _getCategoryIcon(cat),
                                    const SizedBox(width: 8),
                                    Text(
                                      cat,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryLight),
                                  onPressed: () => _showEditBudgetDialog(context, ref, cat, limit),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            if (limit == 0)
                              const Text(
                                "No budget limit configured.",
                                style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 13, fontStyle: FontStyle.italic),
                              )
                            else ...[
                              // Progress details
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Spent: ₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    remaining >= 0 ? "Left: ₹${remaining.toStringAsFixed(0)}" : "Over: ₹${(-remaining).toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: remaining >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    spent > limit ? Colors.redAccent : AppTheme.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, WidgetRef ref, String category, double currentLimit) {
    final controller = TextEditingController(text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : "");
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: Theme.of(context).cardTheme.shape,
          title: Text("Set $category Budget", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Monthly Limit (₹)",
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final double? limit = double.tryParse(controller.text);
                if (limit == null || limit < 0) return;
                
                if (category == 'Total') {
                  ref.read(budgetsProvider.notifier).setTotalBudget(limit);
                } else {
                  ref.read(budgetsProvider.notifier).setCategoryBudget(category, limit);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData data = Icons.category_rounded;
    Color color = Colors.grey;

    switch (category) {
      case 'Food':
        data = Icons.fastfood_rounded;
        color = Colors.orange;
        break;
      case 'Groceries':
        data = Icons.local_grocery_store_rounded;
        color = Colors.green;
        break;
      case 'Fuel':
        data = Icons.local_gas_station_rounded;
        color = Colors.blueGrey;
        break;
      case 'Shopping':
        data = Icons.shopping_bag_rounded;
        color = Colors.purple;
        break;
      case 'EMI':
        data = Icons.credit_card_rounded;
        color = Colors.red;
        break;
      case 'Bills':
        data = Icons.receipt_long_rounded;
        color = Colors.amber;
        break;
      case 'Rent':
        data = Icons.home_rounded;
        color = Colors.brown;
        break;
      case 'Entertainment':
        data = Icons.movie_rounded;
        color = Colors.pink;
        break;
      case 'Healthcare':
        data = Icons.medical_services_rounded;
        color = Colors.red.shade400;
        break;
      case 'Travel':
        data = Icons.directions_car_rounded;
        color = Colors.cyan;
        break;
      case 'Subscription':
        data = Icons.subscriptions_rounded;
        color = Colors.deepPurple;
        break;
    }
    return Icon(data, color: color);
  }
}
