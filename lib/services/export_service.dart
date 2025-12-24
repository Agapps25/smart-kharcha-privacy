import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction.dart';

class ExportService {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _date = DateFormat('dd MMM yyyy');
  final _fullDate = DateFormat('dd MMM yyyy, HH:mm');

  // ✅ Fix: Add proper rupee symbol in PDF
  String _getFormattedAmount(double amount) {
    return '₹${_currency.format(amount).replaceAll('₹', '')}';
  }

  // ================= PDF EXPORT =================
  Future<Uint8List?> exportToPDFBytes(
    List<TransactionModel> transactions,
    String title,
  ) async {
    if (transactions.isEmpty) return null;

    try {
      final pdf = pw.Document();

      // Calculate totals
      final incomeTotal = transactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final expenseTotal = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final netBalance = incomeTotal - expenseTotal;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Smart Kharcha',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          title,
                          style: const pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      _fullDate.format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 24),
                
                // Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _summaryItem('Income', incomeTotal, true),
                      _summaryItem('Expense', expenseTotal, false),
                      _summaryItem('Balance', netBalance, netBalance >= 0),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 24),
                
                // Table header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
                  ),
                  child: pw.Row(
                    children: [
                      _tableHeader('Date', 1.5),
                      _tableHeader('Title', 3),
                      _tableHeader('Type', 1),
                      _tableHeader('Category', 1.5),
                      _tableHeader('Amount', 1.5),
                    ],
                  ),
                ),
                
                // Transactions
                for (final t in transactions)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
                    ),
                    child: pw.Row(
                      children: [
                        _tableCell(_date.format(t.date), 1.5),
                        _tableCell(t.title, 3),
                        _tableCell(t.type.name.toUpperCase(), 1),
                        _tableCell(t.category.name.toUpperCase(), 1.5),
                        _tableCell(
                          '${t.type == TransactionType.income ? "+" : "-"} ${_getFormattedAmount(t.amount)}',
                          1.5,
                          color: t.type == TransactionType.income
                              ? PdfColors.green
                              : PdfColors.red,
                        ),
                      ],
                    ),
                  ),
                
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                
                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Transactions: ${transactions.length}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Generated by Smart Kharcha App',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      return await pdf.save();
    } catch (e) {
      if (kDebugMode) {
        print('PDF Export Error: $e');
      }
      return null;
    }
  }

  // ================= CSV EXPORT =================
  Future<Uint8List?> exportToCSVBytes(List<TransactionModel> transactions) async {
    if (transactions.isEmpty) return null;

    try {
      final csv = StringBuffer();
      
      // Header
      csv.writeln('Date,Title,Type,Category,Amount,Payment Method,Description');
      
      // Data
      for (final t in transactions) {
        csv.writeln([
          '"${_date.format(t.date)}"',
          '"${t.title}"',
          '"${t.type.name}"',
          '"${t.category.name}"',
          '"${_currency.format(t.amount)}"',
          '"${t.paymentMethod.name}"',
          '"${t.description ?? ""}"',
        ].join(','));
      }
      
      return Uint8List.fromList(csv.toString().codeUnits);
    } catch (e) {
      if (kDebugMode) {
        print('CSV Export Error: $e');
      }
      return null;
    }
  }

  // ================= SHARE FILE =================
  Future<void> shareFile(Uint8List fileBytes, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(fileBytes);
      
      await Share.shareXFiles(
        [XFile(tempFile.path, name: fileName)],
        subject: 'Expense Report',
        text: 'Here is your expense report from Smart Kharcha App',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Share Error: $e');
      }
      rethrow;
    }
  }

  // ================= SAVE TO DEVICE =================
  Future<String?> saveFileToDevice(Uint8List fileBytes, String fileName) async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      // Get downloads directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) return null;
      
      final downloadsDir = Directory('${directory.path}/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      final filePath = '${downloadsDir.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Save File Error: $e');
      }
      return null;
    }
  }

  // ================= HELPER METHODS =================
  pw.Widget _summaryItem(String label, double amount, bool isPositive) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _getFormattedAmount(amount),
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: isPositive ? PdfColors.green : PdfColors.red,
          ),
        ),
      ],
    );
  }

  pw.Widget _tableHeader(String text, double flex) {
    return pw.Expanded(
      flex: (flex * 10).toInt(),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text, double flex, {PdfColor? color}) {
    return pw.Expanded(
      flex: (flex * 10).toInt(),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  // ✅ Add legacy methods for compatibility
  Future<String?> exportToPDF(
    List<TransactionModel> transactions,
    String title,
  ) async {
    final bytes = await exportToPDFBytes(transactions, title);
    if (bytes == null) return null;
    
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/expense_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String?> exportToCSV(List<TransactionModel> transactions) async {
    final bytes = await exportToCSVBytes(transactions);
    if (bytes == null) return null;
    
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/expense_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }
}