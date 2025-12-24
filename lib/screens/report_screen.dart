import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/transaction_service.dart';
import '../services/language_service.dart';
import '../models/transaction.dart' as trans_model;
import '../utils/constants.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  TimeFilter _selectedTimeFilter = TimeFilter.monthly;
  trans_model.TransactionType _selectedType = trans_model.TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TransactionService>();
    final lang = context.watch<LanguageService>();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Apply time filter temporarily for this screen
    service.setTimeFilter(_selectedTimeFilter);
    
    // Get data based on selected type
    final Map<trans_model.Category, double> dataMap = _selectedType == trans_model.TransactionType.expense
        ? service.categoryWiseExpenses
        : service.categoryWiseIncome;

    final totalAmount = dataMap.values.fold(0.0, (sum, amount) => sum + amount);
    final totalTransactions = _selectedType == trans_model.TransactionType.expense
        ? service.transactions.where((t) => t.type == trans_model.TransactionType.expense).length
        : service.transactions.where((t) => t.type == trans_model.TransactionType.income).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('reports')),
        actions: [
          PopupMenuButton<TimeFilter>(
            icon: const Icon(Icons.filter_alt_outlined),
            onSelected: (filter) {
              setState(() => _selectedTimeFilter = filter);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: TimeFilter.today,
                child: Text(lang.translate('today')),
              ),
              PopupMenuItem(
                value: TimeFilter.weekly,
                child: Text(lang.translate('weekly')),
              ),
              PopupMenuItem(
                value: TimeFilter.monthly,
                child: Text(lang.translate('monthly')),
              ),
              PopupMenuItem(
                value: TimeFilter.all,
                child: Text(lang.translate('all')),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔖 FILTER CONTROLS
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<trans_model.TransactionType>(
                        segments: [
                          ButtonSegment(
                            value: trans_model.TransactionType.expense,
                            label: Text(lang.translate('expense')),
                            icon: const Icon(Icons.arrow_downward, size: 16),
                          ),
                          ButtonSegment(
                            value: trans_model.TransactionType.income,
                            label: Text(lang.translate('income')),
                            icon: const Icon(Icons.arrow_upward, size: 16),
                          ),
                        ],
                        selected: {_selectedType},
                        onSelectionChanged: (Set<trans_model.TransactionType> newSelection) {
                          setState(() => _selectedType = newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // 📊 SUMMARY CARDS
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    context,
                    lang.isHindi ? 'कुल राशि' : 'Total Amount',
                    currency.format(totalAmount),
                    _selectedType == trans_model.TransactionType.income 
                        ? AppConstants.incomeColor 
                        : AppConstants.expenseColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    context,
                    lang.isHindi ? 'लेन-देन' : 'Transactions',
                    totalTransactions.toString(),
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 📊 CHART TITLE
            Text(
              lang.translate('spending_by_category'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _timeFilterLabel(_selectedTimeFilter, lang),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // PIE CHART
            SizedBox(
              height: 280,
              child: dataMap.isEmpty
                  ? _buildEmptyState(lang)
                  : PieChart(
                      PieChartData(
                        sections: _buildSections(dataMap, totalAmount),
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 30),

            // LEGEND TITLE
            Text(
              lang.isHindi ? 'श्रेणी विवरण' : 'Category Details',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // LEGEND LIST
            ...dataMap.entries.map((entry) {
              final percentage = totalAmount > 0 
                  ? (entry.value / totalAmount * 100).toStringAsFixed(1)
                  : '0.0';
                  
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(entry.key),
                      color: _getCategoryColor(entry.key),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _getCategoryName(entry.key, lang),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('$percentage%'),
                  trailing: Text(
                    currency.format(entry.value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _selectedType == trans_model.TransactionType.income 
                          ? AppConstants.incomeColor 
                          : AppConstants.expenseColor,
                    ),
                  ),
                ),
              );
            }).toList(),
            
            if (dataMap.isEmpty) const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _buildEmptyState(LanguageService lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            lang.translate('no_data'),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.isHindi 
              ? 'चयनित फ़िल्टर के लिए कोई डेटा नहीं'
              : 'No data for selected filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
      Map<trans_model.Category, double> dataMap, double total) {
    return dataMap.entries.map((entry) {
      final percentage = (entry.value / total) * 100;

      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: total > 0 ? '${percentage.toStringAsFixed(0)}%' : '0%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgePositionPercentageOffset: 0.98,
      );
    }).toList();
  }

  String _timeFilterLabel(TimeFilter filter, LanguageService lang) {
    switch (filter) {
      case TimeFilter.today:
        return lang.translate('today');
      case TimeFilter.weekly:
        return lang.translate('weekly');
      case TimeFilter.monthly:
        return lang.translate('monthly');
      case TimeFilter.all:
      default:
        return lang.translate('all_time');
    }
  }

  Color _getCategoryColor(trans_model.Category cat) {
    switch (cat) {
      case trans_model.Category.food:
        return Colors.orange.shade600;
      case trans_model.Category.transport:
        return Colors.blue.shade600;
      case trans_model.Category.shopping:
        return Colors.purple.shade600;
      case trans_model.Category.bills:
        return Colors.red.shade600;
      case trans_model.Category.entertainment:
        return Colors.pink.shade600;
      case trans_model.Category.health:
        return Colors.teal.shade600;
      case trans_model.Category.education:
        return Colors.indigo.shade600;
      case trans_model.Category.salary:
        return Colors.green.shade600;
      case trans_model.Category.investment:
        return Colors.lightGreen.shade600;
      case trans_model.Category.gift:
        return Colors.amber.shade600;
      case trans_model.Category.other:
      
        return Colors.grey.shade600;
    }
  }

  IconData _getCategoryIcon(trans_model.Category cat) {
    switch (cat) {
      case trans_model.Category.food:
        return Icons.restaurant;
      case trans_model.Category.transport:
        return Icons.directions_car;
      case trans_model.Category.shopping:
        return Icons.shopping_bag;
      case trans_model.Category.bills:
        return Icons.receipt_long;
      case trans_model.Category.entertainment:
        return Icons.movie;
      case trans_model.Category.health:
        return Icons.medical_services;
      case trans_model.Category.education:
        return Icons.school;
      case trans_model.Category.salary:
        return Icons.payments;
      case trans_model.Category.investment:
        return Icons.trending_up;
      case trans_model.Category.gift:
        return Icons.card_giftcard;
      case trans_model.Category.other:
        return Icons.category;
    }
  }

  String _getCategoryName(trans_model.Category cat, LanguageService lang) {
    final names = {
      trans_model.Category.food: lang.isHindi ? 'खाना' : 'Food',
      trans_model.Category.transport: lang.isHindi ? 'यातायात' : 'Transport',
      trans_model.Category.shopping: lang.isHindi ? 'खरीदारी' : 'Shopping',
      trans_model.Category.bills: lang.isHindi ? 'बिल' : 'Bills',
      trans_model.Category.entertainment: lang.isHindi ? 'मनोरंजन' : 'Entertainment',
      trans_model.Category.health: lang.isHindi ? 'स्वास्थ्य' : 'Health',
      trans_model.Category.education: lang.isHindi ? 'शिक्षा' : 'Education',
      trans_model.Category.salary: lang.isHindi ? 'वेतन' : 'Salary',
      trans_model.Category.investment: lang.isHindi ? 'निवेश' : 'Investment',
      trans_model.Category.gift: lang.isHindi ? 'उपहार' : 'Gift',
      trans_model.Category.other: lang.isHindi ? 'अन्य' : 'Other',
    };
    
    return names[cat] ?? cat.name;
  }
}