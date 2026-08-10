import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/transaction_model.dart';
import 'transactions_provider.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _selectedType = 'All';
  String _selectedCategory = 'All';
  String _selectedBank = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All', 'Food', 'Groceries', 'Fuel', 'Shopping', 'EMI', 'Bills', 
    'Electricity', 'Internet', 'Rent', 'Entertainment', 
    'Education', 'Healthcare', 'Travel', 'Subscription', 'Others'
  ];

  final List<String> _banks = ['All', 'SBI', 'HDFC', 'ICICI', 'Axis', 'Kotak'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final l10n = ref.watch(localizationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final textSecondary = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

    // Apply filtering & searching logic
    final filtered = transactions.where((tx) {
      // 1. Search Query Match
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          tx.category.toLowerCase().contains(query) ||
          tx.sender.toLowerCase().contains(query) ||
          tx.receiver.toLowerCase().contains(query) ||
          tx.merchant.toLowerCase().contains(query) ||
          tx.bank.toLowerCase().contains(query) ||
          tx.upiApp.toLowerCase().contains(query) ||
          tx.notificationText.toLowerCase().contains(query);

      // 2. Type Match
      final matchesType = _selectedType == 'All' ||
          (_selectedType == 'Income' && (tx.type == 'Income' || tx.type == 'Cashback' || tx.type == 'Refund')) ||
          (_selectedType == 'Expense' && tx.type == 'Expense');

      // 3. Category Match
      final matchesCategory = _selectedCategory == 'All' || tx.category == _selectedCategory;

      // 4. Bank Match
      final matchesBank = _selectedBank == 'All' || tx.bank.toLowerCase() == _selectedBank.toLowerCase();

      return matchesSearch && matchesType && matchesCategory && matchesBank;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('recent_transactions')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(transactionsProvider.notifier).syncNow(),
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Chips
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search transactions, merchants, UPI...",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),
          ),

          // Horizontal Quick Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                _buildFilterChip(l10n.translate('all'), _selectedType == 'All', (val) {
                  setState(() => _selectedType = 'All');
                }),
                _buildFilterChip(l10n.translate('income'), _selectedType == 'Income', (val) {
                  setState(() => _selectedType = 'Income');
                }),
                _buildFilterChip(l10n.translate('expense'), _selectedType == 'Expense', (val) {
                  setState(() => _selectedType = 'Expense');
                }),
              ],
            ),
          ),

          // Category & Bank dropdown filters row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Category",
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBank,
                    decoration: const InputDecoration(
                      labelText: "Bank",
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _banks.map((b) {
                      return DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedBank = val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Transactions List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(l10n.translate('no_transactions_match_filters')),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => _showTransactionDetailsBottomSheet(context, tx),
                          leading: CircleAvatar(
                            backgroundColor: tx.type == 'Income' || tx.type == 'Cashback'
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            child: Icon(
                              tx.type == 'Income' || tx.type == 'Cashback'
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: tx.type == 'Income' || tx.type == 'Cashback'
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          title: Text(
                            tx.merchant.isNotEmpty ? tx.merchant : (tx.sender.isNotEmpty ? tx.sender : tx.category),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${DateFormat('dd MMM yyyy, hh:mm a').format(tx.timestamp)} | ${tx.upiApp}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    tx.type == 'Income' || tx.type == 'Cashback'
                                        ? "+₹${tx.amount.toStringAsFixed(2)}"
                                        : "-₹${tx.amount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: tx.type == 'Income' || tx.type == 'Cashback'
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    tx.category,
                                    style: TextStyle(fontSize: 10, color: textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Function(bool) onSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final chipBg = isDark ? const Color(0xFF1E293B) : Colors.grey.shade100;
    final textColor = isSelected 
        ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
        : (isDark ? Colors.white70 : Colors.black87);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          label, 
          style: TextStyle(
            fontSize: 13, 
            color: textColor, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )
        ),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: accentColor.withOpacity(0.15),
        checkmarkColor: accentColor,
        backgroundColor: chipBg,
      ),
    );
  }

  void _showTransactionDetailsBottomSheet(BuildContext context, TransactionModel tx) {
    final l10n = ref.read(localizationsProvider);
    String currentCategory = tx.category;

    final isDarkOuter = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkOuter ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textSecondary = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Transaction Details",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Big Amount Announcement representation
                  Center(
                    child: Column(
                      children: [
                        Text(
                          tx.type == 'Income' || tx.type == 'Cashback' ? "RECEIVED" : "PAID",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: tx.type == 'Income' || tx.type == 'Cashback' ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${tx.amount.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metadata Detail Rows
                  _buildDetailRow(context, "Source App", tx.upiApp),
                  _buildDetailRow(context, "Bank Account", tx.bank.isNotEmpty ? tx.bank : "N/A"),
                  _buildDetailRow(context, "Party Details", tx.sender.isNotEmpty ? tx.sender : (tx.receiver.isNotEmpty ? tx.receiver : "N/A")),
                  _buildDetailRow(context, "Time & Date", DateFormat('dd MMMM yyyy, hh:mm a').format(tx.timestamp)),
                  _buildDetailRow(context, "Sync Status", tx.isSynced ? "Synced to Cloud" : "Stored Offline Only"),
                  
                  const SizedBox(height: 16),
                  Text(l10n.translate('raw_notification_text'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tx.notificationText,
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Dropdown to override Category
                  Text(l10n.translate('change_category_override'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: currentCategory,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _categories.where((c) => c != 'All').map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() {
                          currentCategory = val;
                        });
                        ref.read(transactionsProvider.notifier).updateTransaction(
                          tx.copyWith(category: val),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton.icon(
                      onPressed: () {
                        ref.read(transactionsProvider.notifier).deleteTransaction(tx.id);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l10n.translate('delete_record'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
