import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/web_helper.dart';
import '../../core/theme/theme.dart';
import '../transactions/transactions_provider.dart';
import '../../models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// PDF and Excel imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import '../../core/localization/app_localizations.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedFormat = 'PDF';
  String _selectedRange = 'This Month';
  bool _isGenerating = false;

  final List<String> _formats = ['PDF', 'Excel (.xlsx)', 'CSV'];
  final List<String> _ranges = ['Today', 'Last 7 Days', 'This Month', 'All Time'];

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final textSecondary = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final accentColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFDBEAFE);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('export_reports')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header illustration/card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  Icon(Icons.analytics_rounded, size: 60, color: accentColor),
                  const SizedBox(height: 12),
                  Text(
                    "Generate Financial Statements",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Export clean summary statements with all transactions, AI categorizations, and totals.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Select Format Section
            const Text(
              "Choose Export Format",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFormat,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.file_present_rounded)),
              items: _formats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedFormat = val);
              },
            ),
            const SizedBox(height: 20),

            // Select Range Section
            const Text(
              "Select Time Frame",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRange,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.date_range_rounded)),
              items: _ranges.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRange = val);
              },
            ),
            const Spacer(),

            // Generate & Share Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateAndShareReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_selectedFormat == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded),
                          const SizedBox(width: 12),
                          const Text(
                            "Generate and Share Statement",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndShareReport() async {
    setState(() => _isGenerating = true);

    try {
      final transactions = ref.read(transactionsProvider);
      final now = DateTime.now();
      
      // Filter by range
      final rangeTxs = transactions.where((tx) {
        if (_selectedRange == 'Today') {
          return tx.timestamp.day == now.day &&
              tx.timestamp.month == now.month &&
              tx.timestamp.year == now.year;
        } else if (_selectedRange == 'Last 7 Days') {
          final oneWeekAgo = now.subtract(const Duration(days: 7));
          return tx.timestamp.isAfter(oneWeekAgo);
        } else if (_selectedRange == 'This Month') {
          return tx.timestamp.month == now.month && tx.timestamp.year == now.year;
        } else { // All Time
          return true;
        }
      }).toList();

      if (rangeTxs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No transactions found for the selected range.")),
        );
        setState(() => _isGenerating = false);
        return;
      }

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
      
      if (kIsWeb) {
        if (_selectedFormat == 'PDF') {
          final bytes = await _generatePdfReport(rangeTxs);
          downloadFileWeb(bytes, "PayVoice_Report_$dateStr.pdf", "application/pdf");
        } else if (_selectedFormat.contains('Excel')) {
          final bytes = await _generateExcelReport(rangeTxs);
          if (bytes != null) {
            downloadFileWeb(bytes, "PayVoice_Report_$dateStr.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
          }
        } else { // CSV
          final csvStr = await _generateCsvReport(rangeTxs);
          final bytes = utf8.encode(csvStr);
          downloadFileWeb(bytes, "PayVoice_Report_$dateStr.csv", "text/csv");
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        if (_selectedFormat == 'PDF') {
          final pdfFile = File("${tempDir.path}/PayVoice_Report_$dateStr.pdf");
          final bytes = await _generatePdfReport(rangeTxs);
          await pdfFile.writeAsBytes(bytes);
          await Share.shareXFiles([XFile(pdfFile.path)], text: 'My PayVoice AI PDF Financial Report');
        } else if (_selectedFormat.contains('Excel')) {
          final excelFile = File("${tempDir.path}/PayVoice_Report_$dateStr.xlsx");
          final bytes = await _generateExcelReport(rangeTxs);
          if (bytes != null) {
            await excelFile.writeAsBytes(bytes);
            await Share.shareXFiles([XFile(excelFile.path)], text: 'My PayVoice AI Excel Financial Report');
          }
        } else { // CSV
          final csvFile = File("${tempDir.path}/PayVoice_Report_$dateStr.csv");
          final csvStr = await _generateCsvReport(rangeTxs);
          await csvFile.writeAsString(csvStr);
          await Share.shareXFiles([XFile(csvFile.path)], text: 'My PayVoice AI CSV Financial Statement');
        }
      }
    } catch (e) {
      debugPrint("Error generating statement: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate report: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<Uint8List> _generatePdfReport(List<TransactionModel> txs) async {
    final pdf = pw.Document();

    // Summary Calculations
    double income = 0;
    double expense = 0;
    for (var tx in txs) {
      if (tx.type == 'Income' || tx.type == 'Cashback' || tx.type == 'Refund') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "PayVoice AI Financial Statement",
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.Text(
                  DateFormat('dd-MM-yyyy').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.blue800),
            pw.SizedBox(height: 16),

            // Summary Grid Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfMetric("Total Income", "Rs ${income.toStringAsFixed(0)}", PdfColors.green700),
                  _buildPdfMetric("Total Expense", "Rs ${expense.toStringAsFixed(0)}", PdfColors.red700),
                  _buildPdfMetric("Net Savings", "Rs ${(income - expense).toStringAsFixed(0)}", PdfColors.blue800),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Transactions Table Title
            pw.Text(
              "Detailed Transactions",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // Table of Transactions
            pw.TableHelper.fromTextArray(
              headers: ['Date/Time', 'App', 'Description/Party', 'Category', 'Amount'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                4: pw.Alignment.centerRight,
              },
              data: txs.map((tx) {
                final date = DateFormat('dd-MM-yy HH:mm').format(tx.timestamp);
                final name = tx.merchant.isNotEmpty ? tx.merchant : (tx.sender.isNotEmpty ? tx.sender : (tx.receiver.isNotEmpty ? tx.receiver : '-'));
                final amountPrefix = tx.type == 'Income' || tx.type == 'Cashback' ? '+' : '-';
                return [
                  date,
                  tx.upiApp,
                  name,
                  tx.category,
                  "$amountPrefix Rs ${tx.amount.toStringAsFixed(0)}"
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildPdfMetric(String title, String val, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(val, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  Future<List<int>?> _generateExcelReport(List<TransactionModel> txs) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Headers
    final List<String> headers = [
      'Transaction ID', 'Amount (Rs)', 'Type', 'Category', 
      'Sender', 'Receiver', 'Merchant', 'Bank', 'UPI App', 
      'Timestamp', 'Notification Text'
    ];
    
    sheet.appendRow(headers.map((h) => ex.TextCellValue(h)).toList());

    for (var tx in txs) {
      sheet.appendRow([
        ex.TextCellValue(tx.id),
        ex.DoubleCellValue(tx.amount),
        ex.TextCellValue(tx.type),
        ex.TextCellValue(tx.category),
        ex.TextCellValue(tx.sender),
        ex.TextCellValue(tx.receiver),
        ex.TextCellValue(tx.merchant),
        ex.TextCellValue(tx.bank),
        ex.TextCellValue(tx.upiApp),
        ex.TextCellValue(DateFormat('yyyy-MM-dd HH:mm:ss').format(tx.timestamp)),
        ex.TextCellValue(tx.notificationText),
      ]);
    }

    return excel.save();
  }

  Future<String> _generateCsvReport(List<TransactionModel> txs) async {
    final StringBuffer csv = StringBuffer();
    
    // Headers
    csv.writeln('ID,Amount,Type,Category,Sender,Receiver,Merchant,Bank,UPI App,Timestamp,NotificationText');

    for (var tx in txs) {
      // Escape commas in notification text and party names
      final cleanText = tx.notificationText.replaceAll('"', '""');
      final cleanSender = tx.sender.replaceAll('"', '""');
      final cleanReceiver = tx.receiver.replaceAll('"', '""');
      final cleanMerchant = tx.merchant.replaceAll('"', '""');
      
      csv.writeln(
        '${tx.id},${tx.amount},${tx.type},${tx.category},"$cleanSender","$cleanReceiver","$cleanMerchant",${tx.bank},${tx.upiApp},${tx.timestamp.toIso8601String()},"$cleanText"',
      );
    }

    return csv.toString();
  }
}
