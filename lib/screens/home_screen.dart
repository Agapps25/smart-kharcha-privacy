import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/transaction_service.dart';
import '../services/language_service.dart';
import '../widgets/stats_card.dart';
import '../widgets/loading_shimmer.dart';
import 'add_transaction_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import '../widgets/transaction_tile.dart';
import 'all_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _snackbarOverlayEntry;
  Timer? _snackbarTimer;
  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _removeSnackbarOverlay();
    _snackbarTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearching = _searchFocusNode.hasFocus;
    });
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
                      color: Colors.black.withAlpha(30),
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
      context.read<TransactionService>().setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TransactionService>();
    final lang = context.watch<LanguageService>();
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                lang.translate('app_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 20,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
            tooltip: lang.isHindi ? 'रिपोर्ट' : 'Reports',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            tooltip: lang.isHindi ? 'सेटिंग' : 'Settings',
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: service.setSortOption,
            tooltip: lang.isHindi ? 'क्रमबद्ध करें' : 'Sort',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortOption.newest,
                child: Row(
                  children: [
                    const Icon(Icons.new_releases_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(lang.isHindi ? 'नवीनतम पहले' : 'Newest First'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOption.oldest,
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(lang.isHindi ? 'पुराना पहले' : 'Oldest First'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOption.highToLow,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(lang.isHindi ? 'ज़्यादा से कम' : 'High to Low'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortOption.lowToHigh,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(lang.isHindi ? 'कम से ज़्यादा' : 'Low to High'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // 🔍 SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: lang.translate('search_hint'),
                onChanged: (value) {
                  _debounceSearch(value);
                },
                leading: const Icon(Icons.search_rounded, color: Colors.grey),
                trailing: _searchController.text.isEmpty
                    ? null
                    : [
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            service.setSearchQuery('');
                            _searchFocusNode.unfocus();
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
                  BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            // 💳 STATS CARD
            StatsCard(
              balance: service.netBalance,
              income: service.totalIncome,
              expense: service.totalExpense,
            ),

            // ⏱ TIME FILTERS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: lang.translate('today'),
                      filter: TimeFilter.today,
                      service: service,
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: lang.translate('weekly'),
                      filter: TimeFilter.weekly,
                      service: service,
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: lang.translate('monthly'),
                      filter: TimeFilter.monthly,
                      service: service,
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: lang.translate('all'),
                      filter: TimeFilter.all,
                      service: service,
                    ),
                  ],
                ),
              ),
            ),

            // 📊 TRANSACTION HEADER WITH COUNT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.isHindi ? 'लेन-देन' : 'Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${service.transactions.length}',
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

            // 👇 VIEW ALL TRANSACTIONS BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllTransactionsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt_rounded, size: 20),
                  label: Text(
                    lang.isHindi ? 'सभी देखें' : 'View All',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            // 📃 TRANSACTIONS LIST
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: _isLoading
                    ? const LoadingShimmer()
                    : service.transactions.isEmpty
                        ? _buildEmptyState(lang, service)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                            itemCount: service.transactions.length,
                            itemBuilder: (context, index) {
                              final t = service.transactions[index];
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: TransactionTile(
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
                                ),
                              );
                            },
                          ),
                ),
            ),
          ],
        ),
      ),

      // ➕ ADD TRANSACTION FAB - FIXED (Small Circular Button)
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isSearching ? const Offset(0, 2) : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isSearching ? 0 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
                setState(() {}); // Refresh after adding
              },
              tooltip: lang.translate('new_entry'), // Tooltip for accessibility
              child: const Icon(Icons.add_rounded, size: 28),
              shape: const CircleBorder(),
            ),
          ),
        ),
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
              Icons.account_balance_wallet_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              lang.translate('no_data'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.isHindi ? 'पहला लेन-देन जोड़ें' : 'Add your first transaction',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            if (service.currentTimeFilter != TimeFilter.all || _searchController.text.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  service.setTimeFilter(TimeFilter.all);
                  service.setSearchQuery('');
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                },
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: Text(lang.isHindi ? 'फ़िल्टर हटाएं' : 'Clear Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
}

// Separate Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final TimeFilter filter;
  final TransactionService service;

  const _FilterChip({
    required this.label,
    required this.filter,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = service.currentTimeFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => service.setTimeFilter(filter),
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
    );
  }
}