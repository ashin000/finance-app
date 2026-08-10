import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../../core/localization/app_localizations.dart';
import '../settings/settings_provider.dart';
import '../transactions/transactions_provider.dart';
import '../budgets/budgets_provider.dart';
import '../../services/native/method_channel_service.dart';
import '../../main.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isNotificationPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await MethodChannelService.instance.isNotificationPermissionGranted();
    if (mounted) {
      setState(() {
        _isNotificationPermissionGranted = granted;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    await MethodChannelService.instance.openNotificationPermissionSettings();
    // Re-check after returning
    Future.delayed(const Duration(seconds: 2), _checkPermissions);
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final budgetState = ref.watch(budgetsProvider);
    final l10n = ref.watch(localizationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final textSecondary = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final accentColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;

    // Calculations
    double totalIncome = 0;
    double totalExpense = 0;
    
    final now = DateTime.now();
    final thisMonthTransactions = transactions.where((tx) =>
        tx.timestamp.month == now.month && tx.timestamp.year == now.year);

    for (var tx in thisMonthTransactions) {
      if (tx.type == 'Income' || tx.type == 'Cashback' || tx.type == 'Refund') {
        totalIncome += tx.amount;
      } else if (tx.type == 'Expense') {
        totalExpense += tx.amount;
      }
    }

    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;

    // Local AI Insights
    final List<String> aiInsights = [];
    if (totalIncome > 0) {
      aiInsights.add("You saved ${savingsRate.toStringAsFixed(0)}% of your income this month.");
    }
    if (totalExpense > 0) {
      // Find top category
      final Map<String, double> catTotals = {};
      for (var tx in thisMonthTransactions.where((t) => t.type == 'Expense')) {
        catTotals[tx.category] = (catTotals[tx.category] ?? 0) + tx.amount;
      }
      if (catTotals.isNotEmpty) {
        final topCat = catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
        aiInsights.add("Your largest expense category is ${topCat.key} (₹${topCat.value.toStringAsFixed(0)}).");
      }

      // Average daily expense
      final currentDay = now.day;
      final avgDaily = totalExpense / currentDay;
      aiInsights.add("Your average daily spending is ₹${avgDaily.toStringAsFixed(0)}.");
    } else {
      aiInsights.add("No expenses detected yet for this month. Start tracking automatically!");
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(transactionsProvider.notifier).syncNow();
            await _checkPermissions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('welcome_back'),
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.translate('app_title'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, color: AppTheme.primaryLight),
                      onPressed: () {
                        ref.read(transactionsProvider.notifier).syncNow();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Syncing transactions...")),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Permission Warning Banner
                if (!_isNotificationPermissionGranted)
                  GestureDetector(
                    onTap: _requestNotificationPermission,
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Notification Access Disabled",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Tap here to enable background transaction detection and announcements.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Balance Card (Glassmorphic)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration(context: context, opacity: 0.9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "NET MONTHLY SAVINGS",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryLight,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹${netSavings.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: netSavings >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BalanceMetric(
                            label: "INCOME",
                            value: "₹${totalIncome.toStringAsFixed(0)}",
                            color: Colors.green.shade600,
                          ),
                          _BalanceMetric(
                            label: "EXPENSE",
                            value: "₹${totalExpense.toStringAsFixed(0)}",
                            color: Colors.red.shade600,
                          ),
                          _BalanceMetric(
                            label: "SAVED",
                            value: "${savingsRate.toStringAsFixed(0)}%",
                            color: AppTheme.primaryLight,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions Title
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickActionBtn(
                      icon: Icons.add_rounded,
                      label: "Add Manual",
                      onPressed: () => _showAddTransactionDialog(context),
                    ),
                    _QuickActionBtn(
                      icon: Icons.security_rounded,
                      label: "Perms Settings",
                      onPressed: _requestNotificationPermission,
                    ),
                    _QuickActionBtn(
                      icon: Icons.refresh_rounded,
                      label: "Sync Cache",
                      onPressed: () {
                        ref.read(transactionsProvider.notifier).syncNow();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Budget Tracking Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Monthly Budget Limit",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            "₹${totalExpense.toStringAsFixed(0)} / ₹${budgetState.totalBudget.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: budgetState.totalBudget > 0 
                              ? (totalExpense / budgetState.totalBudget).clamp(0.0, 1.0)
                              : 0.0,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            (totalExpense > budgetState.totalBudget)
                                ? Colors.redAccent
                                : AppTheme.primaryLight,
                          ),
                        ),
                      ),
                      if (totalExpense > budgetState.totalBudget) ...[
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Alert: You have exceeded your monthly budget!",
                              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // AI Insights Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            "AI Financial Insights",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...aiInsights.map((insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                insight,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.translate('recent_transactions'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(tabIndexProvider.notifier).state = 1;
                      },
                      child: Text(l10n.translate('view_all')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(l10n.translate('no_transactions_recorded')),
                    ),
                  )
                else
                  ...transactions.take(4).map((tx) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: tx.type == 'Income' || tx.type == 'Cashback' 
                                ? Colors.green.shade50 
                                : Colors.blue.shade50,
                            child: Icon(
                              tx.type == 'Income' || tx.type == 'Cashback'
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: tx.type == 'Income' || tx.type == 'Cashback'
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                          title: Text(
                            tx.upiApp.isNotEmpty ? "${tx.upiApp} - ${tx.category}" : tx.category,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${DateFormat('dd MMM, hh:mm a').format(tx.timestamp)} | ${tx.sender.isNotEmpty ? tx.sender : (tx.receiver.isNotEmpty ? tx.receiver : 'Transaction')}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            tx.type == 'Income' || tx.type == 'Cashback'
                                ? "+₹${tx.amount.toStringAsFixed(0)}"
                                : "-₹${tx.amount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: tx.type == 'Income' || tx.type == 'Cashback'
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final l10n = ref.read(localizationsProvider);
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String txType = 'Expense';
    String txCategory = 'Food';
    String bankName = 'SBI';
    String upiAppName = 'Google Pay';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardTheme.color,
              shape: Theme.of(context).cardTheme.shape,
              title: Text(l10n.translate('add_manual_transaction'), style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount (₹)",
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: txType,
                      decoration: const InputDecoration(labelText: "Type"),
                      items: ['Expense', 'Income'].map((val) {
                        return DropdownMenuItem(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            txType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: txCategory,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: [
                        'Food', 'Groceries', 'Fuel', 'Shopping', 'EMI', 'Bills', 
                        'Electricity', 'Internet', 'Rent', 'Entertainment', 
                        'Education', 'Healthcare', 'Travel', 'Subscription', 'Others'
                      ].map((val) {
                        return DropdownMenuItem(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            txCategory = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final double? amt = double.tryParse(amountController.text);
                    if (amt == null || amt <= 0) return;
                    
                    ref.read(transactionsProvider.notifier).addTransaction(
                          amount: amt,
                          type: txType,
                          category: txCategory,
                          description: descController.text.trim(),
                          bank: bankName,
                          upiApp: upiAppName,
                        );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(l10n.translate('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BalanceMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final accentColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: cardBg,
            foregroundColor: accentColor,
            elevation: 1,
            side: BorderSide(color: borderCol),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
