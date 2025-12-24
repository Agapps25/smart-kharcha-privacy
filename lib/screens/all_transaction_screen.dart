import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../services/language_service.dart';
import '../services/export_service.dart';
import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/loading_shimmer.dart';
import 'add_transaction_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() =>
      _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  TransactionType? _typeFilter;
  DateTimeRange? _dateRange;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  OverlayEntry? _snackbarOverlayEntry;
  Timer? _snackbarTimer;
  bool _isLoading = false;
  final ExportService _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _removeSnackbarOverlay();
    _snackbarTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _removeSnackbarOverlay() {
    _snackbarOverlayEntry?.remove();
    _snackbarOverlayEntry = null;
    _snackbarTimer?.cancel();
    _snackbarTimer = null;
  }

  void _showCustomSnackbar(BuildContext context, String message, VoidCallback undoAction, LanguageService lang) {
    _removeSnackbarOverlay();
    
    final overlay = Overlay.of(context);

    _snackbarOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: 90,
        child: GestureDetector(
          onTap: _removeSnackbarOverlay,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: const Key('snackbar_dismiss'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => _removeSnackbarOverlay(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(128),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        undoAction();
                        _removeSnackbarOverlay();
                      },
                      child: Text(
                        lang.translate('undo'),
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      onPressed: _removeSnackbarOverlay,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_snackbarOverlayEntry!);

    _snackbarTimer = Timer(const Duration(seconds: 5), () {
      if (_snackbarOverlayEntry != null) {
        _removeSnackbarOverlay();
      }
    });
  }

  void _debounceSearch(String query) {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {});
    });
  }

  Future<void> _handleExport(BuildContext context, LanguageService lang, List<TransactionModel> transactions) async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.isHindi ? 'निर्यात के लिए कोई डेटा नहीं' : 'No data to export'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.isHindi ? 'निर्यात प्रारूप' : 'Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(lang.isHindi ? 'PDF फाइल' : 'PDF File'),
              subtitle: Text(lang.isHindi ? 'प्रिंट करने योग्य रिपोर्ट' : 'Printable report'),
              onTap: () async {
                Navigator.pop(context);
                // ✅ FIX: Use exportToPDFBytes instead of exportToPDF
                final result = await _exportService.exportToPDFBytes(
                  transactions, 
                  lang.isHindi ? 'फ़िल्टर किए गए लेन-देन' : 'Filtered Transactions'
                );
                
                if (result != null) {
                  await _exportService.shareFile(
                    result, // ✅ Now Uint8List, not String
                    'Filtered_Transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf'
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text(lang.isHindi ? 'CSV फाइल' : 'CSV File'),
              subtitle: Text(lang.isHindi ? 'Excel में खोलने योग्य' : 'Open in Excel/Sheets'),
              onTap: () async {
                Navigator.pop(context);
                // ✅ FIX: Use exportToCSVBytes instead of exportToCSV
                final result = await _exportService.exportToCSVBytes(transactions);
                
                if (result != null) {
                  await _exportService.shareFile(
                    result, // ✅ Now Uint8List, not String
                    'Filtered_Transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv'
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TransactionService>();
    final lang = context.watch<LanguageService>();
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Get all transactions (unfiltered from service)
    List<TransactionModel> allTransactions = service.allTransactions;

    // 🔍 SEARCH FILTER
    if (_searchCtrl.text.isNotEmpty) {
      final q = _searchCtrl.text.toLowerCase();
      allTransactions = allTransactions.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.category.name.toLowerCase().contains(q) ||
            t.paymentMethod.name.toLowerCase().contains(q) ||
            t.amount.toString().contains(q) ||
            (t.description ?? '').toLowerCase().contains(q);
      }).toList();
    }

    // 📌 TYPE FILTER
    if (_typeFilter != null) {
      allTransactions = allTransactions.where((t) => t.type == _typeFilter).toList();
    }

    // 📆 DATE RANGE FILTER
    if (_dateRange != null) {
      allTransactions = allTransactions.where((t) {
        return t.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by newest first
    allTransactions.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.isHindi ? 'सभी ट्रांजेक्शन' : 'All Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _openFilterSheet(context, lang),
            tooltip: lang.isHindi ? 'फ़िल्टर' : 'Filter',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: lang.isHindi ? 'अधिक विकल्प' : 'More options',
            onSelected: (value) {
              if (value == 'export') {
                _handleExport(context, lang, allTransactions);
              } else if (value == 'clear_filters') {
                setState(() {
                  _typeFilter = null;
                  _dateRange = null;
                  _searchCtrl.clear();
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_off, size: 20, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      lang.isHindi ? 'फ़िल्टर हटाएं' : 'Clear Filters',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download_rounded, size: 20, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      lang.isHindi ? 'निर्यात करें' : 'Export',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: lang.translate('search_hint'),
              onChanged: (value) {
                _debounceSearch(value);
              },
              leading: const Icon(Icons.search_rounded, color: Colors.grey),
              trailing: _searchCtrl.text.isEmpty
                  ? null
                  : [
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      ),
                    ],
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.white,
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              side: WidgetStateProperty.all(
                BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),

          // 📊 FILTER INDICATORS
          if (_typeFilter != null || _dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_typeFilter != null)
                    Chip(
                      label: Text(
                        _typeFilter == TransactionType.income
                            ? lang.translate('income')
                            : lang.translate('expense'),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _typeFilter = null),
                    ),
                  if (_dateRange != null)
                    Chip(
                      label: Text(
                        '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}',
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _dateRange = null),
                    ),
                ],
              ),
            ),

          // 📊 TRANSACTION COUNT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.isHindi ? 'कुल लेन-देन' : 'Total Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    // ✅ FIX: withOpacity को withAlpha में बदलें
                    color: Theme.of(context).primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allTransactions.length}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 📃 LIST
          Expanded(
            child: _isLoading
                ? const LoadingShimmer()
                : allTransactions.isEmpty
                    ? _buildEmptyState(lang, service)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                        itemCount: allTransactions.length,
                        itemBuilder: (_, i) {
                          final t = allTransactions[i];
                          return TransactionTile(
                            key: ValueKey(t.id),
                            transaction: t,
                            format: format,
                            onDelete: () {
                              service.deleteTransaction(t.id);
                              _showCustomSnackbar(
                                context,
                                lang.translate('delete_msg'),
                                service.undoDelete,
                                lang,
                              );
                            },
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddTransactionScreen(transaction: t),
                                ),
                              );
                              setState(() {}); // Refresh after editing
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageService lang, TransactionService service) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              lang.translate('no_data'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                // ✅ FIX: withOpacity को withAlpha में बदलें
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.isHindi ? 'कोई लेन-देन नहीं मिला' : 'No transactions found',
              style: TextStyle(
                fontSize: 14,
                // ✅ FIX: withOpacity को withAlpha में बदलें
                color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
              ),
            ),
            const SizedBox(height: 24),
            if (_typeFilter != null || _dateRange != null || _searchCtrl.text.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _typeFilter = null;
                    _dateRange = null;
                    _searchCtrl.clear();
                  });
                },
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: Text(lang.isHindi ? 'फ़िल्टर हटाएं' : 'Clear Filters'),
                style: ElevatedButton.styleFrom(
                  // ✅ FIX: withOpacity को withAlpha में बदलें
                  backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
                  foregroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= FILTER SHEET =================
  void _openFilterSheet(BuildContext context, LanguageService lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.isHindi ? 'फ़िल्टर' : 'Filters',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                lang.isHindi ? 'प्रकार चुनें' : 'Select Type',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  _chip('All', _typeFilter == null, () {
                    setState(() => _typeFilter = null);
                    Navigator.pop(context);
                  }),
                  _chip(lang.translate('income'), _typeFilter == TransactionType.income, () {
                    setState(() => _typeFilter = TransactionType.income);
                    Navigator.pop(context);
                  }),
                  _chip(lang.translate('expense'), _typeFilter == TransactionType.expense, () {
                    setState(() => _typeFilter = TransactionType.expense);
                    Navigator.pop(context);
                  }),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              Text(
                lang.isHindi ? 'तारीख सीमा' : 'Date Range',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.blue),
                title: Text(
                  lang.isHindi ? 'कस्टम तारीख' : 'Custom Date Range',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _dateRange == null
                      ? (lang.isHindi ? 'चयन नहीं' : 'Not selected')
                      : '${_formatDateForDisplay(_dateRange!.start)} - ${_formatDateForDisplay(_dateRange!.end)}',
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: _dateRange != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() => _dateRange = null);
                          Navigator.pop(context);
                        },
                      )
                    : null,
                onTap: () async {
                  final now = DateTime.now();
                  final firstDate = DateTime(now.year - 1, 1, 1);
                  final lastDate = DateTime(now.year + 1, 12, 31);
                  
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    currentDate: now,
                    initialDateRange: _dateRange,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Theme.of(context).primaryColor,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Colors.black,
                          ),
                          // ✅ FIX: DialogThemeData को DialogTheme में बदलें
                          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
                        ),
                        child: child!,
                      );
                    },
                  );
                  
                  if (picked != null) {
                    setState(() => _dateRange = picked);
                    Navigator.pop(context);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Quick date presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _datePresetChip(
                      lang.isHindi ? 'आज' : 'Today',
                      () {
                        final now = DateTime.now();
                        setState(() {
                          _dateRange = DateTimeRange(
                            start: DateTime(now.year, now.month, now.day),
                            end: DateTime(now.year, now.month, now.day),
                          );
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    _datePresetChip(
                      lang.isHindi ? 'इस हफ्ते' : 'This Week',
                      () {
                        final now = DateTime.now();
                        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                        setState(() {
                          _dateRange = DateTimeRange(
                            start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
                            end: DateTime(now.year, now.month, now.day),
                          );
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    _datePresetChip(
                      lang.isHindi ? 'इस महीने' : 'This Month',
                      () {
                        final now = DateTime.now();
                        setState(() {
                          _dateRange = DateTimeRange(
                            start: DateTime(now.year, now.month, 1),
                            end: DateTime(now.year, now.month, now.day),
                          );
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    _datePresetChip(
                      lang.isHindi ? 'इस साल' : 'This Year',
                      () {
                        final now = DateTime.now();
                        setState(() {
                          _dateRange = DateTimeRange(
                            start: DateTime(now.year, 1, 1),
                            end: DateTime(now.year, now.month, now.day),
                          );
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _typeFilter = null;
                          _dateRange = null;
                          _searchCtrl.clear();
                        });
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(lang.isHindi ? 'सभी हटाएं' : 'Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        lang.isHindi ? 'लागू करें' : 'Apply',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _datePresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.blue.shade50,
      labelStyle: TextStyle(
        color: Colors.blue.shade700,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
    );
  }
}