import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../transactions/transactions_provider.dart';
import '../../models/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, Color> _categoryColors = {
    'Food': Colors.orange,
    'Groceries': Colors.green,
    'Fuel': Colors.blueGrey,
    'Shopping': Colors.purple,
    'EMI': Colors.red,
    'Bills': Colors.amber,
    'Electricity': Colors.yellow.shade700,
    'Internet': Colors.indigo,
    'Rent': Colors.brown,
    'Entertainment': Colors.pink,
    'Education': Colors.teal,
    'Healthcare': Colors.red.shade300,
    'Travel': Colors.cyan,
    'Subscription': Colors.deepPurple,
    'Others': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Spending Analytics"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondaryLight,
          tabs: const [
            Tab(text: "Daily"),
            Tab(text: "Weekly"),
            Tab(text: "Monthly"),
            Tab(text: "Yearly"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPeriodAnalytics(transactions, 'Daily'),
          _buildPeriodAnalytics(transactions, 'Weekly'),
          _buildPeriodAnalytics(transactions, 'Monthly'),
          _buildPeriodAnalytics(transactions, 'Yearly'),
        ],
      ),
    );
  }

  Widget _buildPeriodAnalytics(List<TransactionModel> allTxs, String period) {
    final now = DateTime.now();
    
    // Filter transactions by period
    final List<TransactionModel> periodTxs = allTxs.where((tx) {
      if (period == 'Daily') {
        return tx.timestamp.day == now.day &&
            tx.timestamp.month == now.month &&
            tx.timestamp.year == now.year;
      } else if (period == 'Weekly') {
        final oneWeekAgo = now.subtract(const Duration(days: 7));
        return tx.timestamp.isAfter(oneWeekAgo);
      } else if (period == 'Monthly') {
        return tx.timestamp.month == now.month && tx.timestamp.year == now.year;
      } else { // Yearly
        return tx.timestamp.year == now.year;
      }
    }).toList();

    // Summary calculations
    double income = 0;
    double expense = 0;
    double highestExpense = 0;
    String highestExpenseMerchant = "N/A";
    
    final Map<String, double> categoryMap = {};
    final Map<String, int> upiAppMap = {};
    final Map<String, int> merchantMap = {};

    for (var tx in periodTxs) {
      if (tx.type == 'Income' || tx.type == 'Cashback' || tx.type == 'Refund') {
        income += tx.amount;
      } else if (tx.type == 'Expense') {
        expense += tx.amount;
        
        // Category breakdown
        categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;

        // Highest expense
        if (tx.amount > highestExpense) {
          highestExpense = tx.amount;
          highestExpenseMerchant = tx.merchant.isNotEmpty ? tx.merchant : (tx.receiver.isNotEmpty ? tx.receiver : tx.category);
        }

        // Merchants frequency
        final mName = tx.merchant.isNotEmpty ? tx.merchant : tx.receiver;
        if (mName.isNotEmpty) {
          merchantMap[mName] = (merchantMap[mName] ?? 0) + 1;
        }
      }

      // App frequency
      if (tx.upiApp.isNotEmpty) {
        upiAppMap[tx.upiApp] = (upiAppMap[tx.upiApp] ?? 0) + 1;
      }
    }

    final netSavings = income - expense;
    final mostUsedApp = upiAppMap.isNotEmpty 
        ? upiAppMap.entries.reduce((a, b) => a.value > b.value ? a : b).key 
        : "N/A";
    
    final mostFreqMerchant = merchantMap.isNotEmpty 
        ? merchantMap.entries.reduce((a, b) => a.value > b.value ? a : b).key 
        : "N/A";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Balance Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: "Total Income",
                  value: "₹${income.toStringAsFixed(0)}",
                  color: Colors.green.shade700,
                  backgroundColor: Colors.green.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: "Total Expense",
                  value: "₹${expense.toStringAsFixed(0)}",
                  color: Colors.red.shade700,
                  backgroundColor: Colors.red.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            title: "Net Savings",
            value: "₹${netSavings.toStringAsFixed(0)}",
            color: netSavings >= 0 ? Colors.blue.shade700 : Colors.red.shade700,
            backgroundColor: netSavings >= 0 ? Colors.blue.shade50 : Colors.red.shade50,
            fullWidth: true,
          ),
          const SizedBox(height: 28),

          // Pie Chart section
          if (expense > 0) ...[
            const Text(
              "Spending by Category",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: categoryMap.entries.map((entry) {
                    final color = _categoryColors[entry.key] ?? Colors.grey;
                    final pct = (entry.value / expense) * 100;
                    return PieChartSectionData(
                      color: color,
                      value: entry.value,
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: categoryMap.keys.map((cat) {
                final color = _categoryColors[cat] ?? Colors.grey;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Daily Spending Trends line chart
          if (periodTxs.isNotEmpty) ...[
            const Text(
              "Spending Trend",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              padding: const EdgeInsets.only(right: 20, top: 10),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateTrendSpots(periodTxs, period),
                      isCurved: true,
                      color: AppTheme.primaryLight,
                      barWidth: 4,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryLight.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Key Highlights
          const Text(
            "Period Highlights",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildHighlightRow("Highest Expense", highestExpense > 0 ? "₹${highestExpense.toStringAsFixed(0)} ($highestExpenseMerchant)" : "N/A"),
          _buildHighlightRow("Most Used App", mostUsedApp),
          _buildHighlightRow("Top Merchant", mostFreqMerchant),
          _buildHighlightRow("Transactions Count", "${periodTxs.length}"),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required Color backgroundColor,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightRow(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondaryLight, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateTrendSpots(List<TransactionModel> txs, String period) {
    final Map<int, double> timeline = {};
    
    // Group totals by hour, day, week or month
    for (var tx in txs.where((t) => t.type == 'Expense')) {
      int key = tx.timestamp.day;
      if (period == 'Daily') {
        key = tx.timestamp.hour;
      } else if (period == 'Yearly') {
        key = tx.timestamp.month;
      }
      timeline[key] = (timeline[key] ?? 0) + tx.amount;
    }

    if (timeline.isEmpty) return [const FlSpot(0, 0)];

    final sortedKeys = timeline.keys.toList()..sort();
    return sortedKeys.map((k) => FlSpot(k.toDouble(), timeline[k]!)).toList();
  }
}
