import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart' as trans_model;
import '../services/error_service.dart';
import '../utils/security_utils.dart';

enum TimeFilter { today, weekly, monthly, all, custom }
enum SortOption { newest, oldest, highToLow, lowToHigh }

class TransactionService extends ChangeNotifier {
  final Box<trans_model.TransactionModel> _box =
      Hive.box<trans_model.TransactionModel>('transactions_box');
  
  TimeFilter _currentTimeFilter = TimeFilter.all;
  SortOption _currentSortOption = SortOption.newest;
  String _searchQuery = '';
  DateTimeRange? _customDateRange;

  // ================= GETTERS =================
  TimeFilter get currentTimeFilter => _currentTimeFilter;
  SortOption get currentSortOption => _currentSortOption;
  String get searchQuery => _searchQuery;
  DateTimeRange? get customDateRange => _customDateRange;

  // 🔹 RAW ALL TRANSACTIONS (no filters)
  List<trans_model.TransactionModel> get allTransactions {
    try {
      return _box.values.toList();
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Get All Transactions');
      return [];
    }
  }

  // ================= FILTERED TRANSACTIONS =================
  List<trans_model.TransactionModel> get transactions {
    try {
      List<trans_model.TransactionModel> list = allTransactions;

      // 🔍 SEARCH FILTER
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        list = list.where((t) {
          return t.title.toLowerCase().contains(q) ||
              t.category.name.toLowerCase().contains(q) ||
              t.paymentMethod.name.toLowerCase().contains(q) ||
              t.amount.toString().contains(q) ||
              (t.description ?? '').toLowerCase().contains(q);
        }).toList();
      }

      // ⏱ TIME FILTER
      final now = DateTime.now();
      list = list.where((t) {
        switch (_currentTimeFilter) {
          case TimeFilter.today:
            return t.date.year == now.year &&
                t.date.month == now.month &&
                t.date.day == now.day;
          case TimeFilter.weekly:
            return t.date.isAfter(now.subtract(const Duration(days: 7)));
          case TimeFilter.monthly:
            return t.date.year == now.year && t.date.month == now.month;
          case TimeFilter.custom:
            if (_customDateRange == null) return true;
            return t.date.isAfter(
                    _customDateRange!.start.subtract(const Duration(days: 1))) &&
                t.date.isBefore(
                    _customDateRange!.end.add(const Duration(days: 1)));
          case TimeFilter.all:
            return true;
        }
      }).toList();

      // ↕ SORT
      switch (_currentSortOption) {
        case SortOption.newest:
          list.sort((a, b) => b.date.compareTo(a.date));
          break;
        case SortOption.oldest:
          list.sort((a, b) => a.date.compareTo(b.date));
          break;
        case SortOption.highToLow:
          list.sort((a, b) => b.amount.compareTo(a.amount));
          break;
        case SortOption.lowToHigh:
          list.sort((a, b) => a.amount.compareTo(b.amount));
          break;
      }

      return list;
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Get Filtered Transactions');
      return [];
    }
  }

  // ================= TOTALS =================
  double get totalIncome => _calculateTotal(trans_model.TransactionType.income);
  double get totalExpense => _calculateTotal(trans_model.TransactionType.expense);
  double get netBalance => totalIncome - totalExpense;

  double _calculateTotal(trans_model.TransactionType type) {
    try {
      return transactions
          .where((t) => t.type == type)
          .fold(0.0, (sum, t) => sum + t.amount);
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Calculate Total');
      return 0.0;
    }
  }

  // ================= FILTER SETTERS =================
  void setTimeFilter(TimeFilter filter, {DateTimeRange? customRange}) {
    try {
      _currentTimeFilter = filter;
      _customDateRange = customRange;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('⏱️ Filter set to: $filter');
      }
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Set Time Filter');
    }
  }

  void setSearchQuery(String query) {
    try {
      _searchQuery = query;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('🔍 Search query: $query');
      }
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Set Search Query');
    }
  }

  void setSortOption(SortOption option) {
    try {
      _currentSortOption = option;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('↕️ Sort option: $option');
      }
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Set Sort Option');
    }
  }

  void clearFilters() {
    try {
      _currentTimeFilter = TimeFilter.all;
      _currentSortOption = SortOption.newest;
      _searchQuery = '';
      _customDateRange = null;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('🧹 All filters cleared');
      }
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Clear Filters');
    }
  }

  // ================= CRUD OPERATIONS =================
  Future<void> addTransaction(trans_model.TransactionModel t) async {
    try {
      // Validate input
      if (!SecurityUtils.isValidTitle(t.title)) {
        throw Exception('Invalid title. Must be 1-100 characters.');
      }
      if (!SecurityUtils.isValidAmount(t.amount.toString())) {
        throw Exception('Invalid amount. Must be between ₹1 and ₹1,00,00,00,000.');
      }
      if (!SecurityUtils.isValidDate(t.date)) {
        throw Exception('Invalid date. Must be between 2020 and today.');
      }
      if (!SecurityUtils.isValidDescription(t.description)) {
        throw Exception('Description too long. Maximum 500 characters.');
      }

      // Sanitize input
      final sanitizedTransaction = trans_model.TransactionModel(
        id: t.id,
        title: SecurityUtils.sanitizeInput(t.title),
        amount: t.amount,
        date: t.date,
        category: t.category,
        paymentMethod: t.paymentMethod,
        type: t.type,
        description: t.description != null 
            ? SecurityUtils.sanitizeInput(t.description!)
            : null,
      );

      await _box.put(sanitizedTransaction.id, sanitizedTransaction);
      notifyListeners();

      // Log success
      if (kDebugMode) {
        debugPrint('✅ Transaction added: ${sanitizedTransaction.title} - ₹${sanitizedTransaction.amount}');
      }
      
      // Clear undo cache for new transactions
      _lastDeleted = null;
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Add Transaction');
      rethrow;
    }
  }

  Future<void> updateTransaction(trans_model.TransactionModel t) async {
    try {
      // Validate input
      if (!SecurityUtils.isValidTitle(t.title)) {
        throw Exception('Invalid title. Must be 1-100 characters.');
      }
      if (!SecurityUtils.isValidAmount(t.amount.toString())) {
        throw Exception('Invalid amount. Must be between ₹1 and ₹1,00,00,00,000.');
      }
      if (!SecurityUtils.isValidDate(t.date)) {
        throw Exception('Invalid date. Must be between 2020 and today.');
      }
      if (!SecurityUtils.isValidDescription(t.description)) {
        throw Exception('Description too long. Maximum 500 characters.');
      }

      // Sanitize input
      final sanitizedTransaction = trans_model.TransactionModel(
        id: t.id,
        title: SecurityUtils.sanitizeInput(t.title),
        amount: t.amount,
        date: t.date,
        category: t.category,
        paymentMethod: t.paymentMethod,
        type: t.type,
        description: t.description != null 
            ? SecurityUtils.sanitizeInput(t.description!)
            : null,
      );

      await _box.put(sanitizedTransaction.id, sanitizedTransaction);
      notifyListeners();

      if (kDebugMode) {
        debugPrint('✏️ Transaction updated: ${sanitizedTransaction.title}');
      }
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Update Transaction');
      rethrow;
    }
  }

  // ================= DELETE + UNDO =================
  trans_model.TransactionModel? _lastDeleted;
  final List<trans_model.TransactionModel> _recentlyDeleted = [];

  Future<void> deleteTransaction(String id) async {
    try {
      final transaction = _box.get(id);
      if (transaction != null) {
        _lastDeleted = transaction;
        _recentlyDeleted.add(transaction);
        await _box.delete(id);
        notifyListeners();

        if (kDebugMode) {
          debugPrint('🗑️ Transaction deleted: ${transaction.title}');
        }
      } else {
        throw Exception('Transaction not found with ID: $id');
      }
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Delete Transaction');
      rethrow;
    }
  }

  Future<void> undoDelete() async {
    try {
      if (_lastDeleted != null) {
        await _box.put(_lastDeleted!.id, _lastDeleted!);
        _recentlyDeleted.remove(_lastDeleted);
        
        if (kDebugMode) {
          debugPrint('↩️ Transaction restored: ${_lastDeleted!.title}');
        }
        
        _lastDeleted = null;
        notifyListeners();
      } else {
        throw Exception('No transaction to undo');
      }
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Undo Delete');
      rethrow;
    }
  }

  trans_model.TransactionModel? get lastDeleted => _lastDeleted;
  List<trans_model.TransactionModel> get recentlyDeleted => List.from(_recentlyDeleted);

  // ================= BULK OPERATIONS =================
  Future<void> clearAll() async {
    try {
      final transactions = allTransactions;
      if (transactions.isNotEmpty) {
        _recentlyDeleted.addAll(transactions);
        _lastDeleted = transactions.last;
        await _box.clear();
        notifyListeners();

        if (kDebugMode) {
          debugPrint('🧹 All transactions cleared (${transactions.length} items)');
        }
      }
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Clear All');
      rethrow;
    }
  }

  Future<void> restoreAll() async {
    try {
      if (_recentlyDeleted.isNotEmpty) {
        for (final transaction in _recentlyDeleted) {
          await _box.put(transaction.id, transaction);
        }
        
        final restoredCount = _recentlyDeleted.length;
        _recentlyDeleted.clear();
        _lastDeleted = null;
        notifyListeners();

        if (kDebugMode) {
          debugPrint('🔄 All transactions restored ($restoredCount items)');
        }
      } else {
        throw Exception('No transactions to restore');
      }
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Restore All');
      rethrow;
    }
  }

  // ================= STATISTICS =================
  Map<trans_model.Category, double> get categoryWiseExpenses {
    try {
      final Map<trans_model.Category, double> result = {};
      for (final t in transactions.where((t) => t.type == trans_model.TransactionType.expense)) {
        result[t.category] = (result[t.category] ?? 0) + t.amount;
      }
      return result;
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Category Wise Expenses');
      return {};
    }
  }

  Map<trans_model.Category, double> get categoryWiseIncome {
    try {
      final Map<trans_model.Category, double> result = {};
      for (final t in transactions.where((t) => t.type == trans_model.TransactionType.income)) {
        result[t.category] = (result[t.category] ?? 0) + t.amount;
      }
      return result;
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Category Wise Income');
      return {};
    }
  }

  // ================= SEARCH SUGGESTIONS =================
  List<String> getSearchSuggestions(String query) {
    try {
      final suggestions = <String>{};
      final q = query.toLowerCase();
      
      for (final t in allTransactions) {
        if (t.title.toLowerCase().contains(q)) {
          suggestions.add(t.title);
        }
        if (t.category.name.toLowerCase().contains(q)) {
          suggestions.add(t.category.name);
        }
        if (t.description?.toLowerCase().contains(q) ?? false) {
          suggestions.add(t.description!);
        }
      }
      
      return suggestions.toList();
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Search Suggestions');
      return [];
    }
  }

  // ================= TRANSACTION STATS =================
  Map<String, dynamic> getTransactionStats() {
    try {
      final stats = {
        'totalTransactions': allTransactions.length,
        'incomeTransactions': allTransactions.where((t) => t.type == trans_model.TransactionType.income).length,
        'expenseTransactions': allTransactions.where((t) => t.type == trans_model.TransactionType.expense).length,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netBalance': netBalance,
        'oldestTransaction': allTransactions.isNotEmpty 
            ? allTransactions.last.date 
            : null,
        'newestTransaction': allTransactions.isNotEmpty 
            ? allTransactions.first.date 
            : null,
        'averageTransaction': allTransactions.isNotEmpty 
            ? (totalIncome + totalExpense) / allTransactions.length 
            : 0,
      };
      
      return stats;
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Transaction Stats');
      return {};
    }
  }

  // ================= MEMORY MANAGEMENT =================
  @override
  void dispose() {
    // Clear caches
    _recentlyDeleted.clear();
    _lastDeleted = null;
    
    // Close Hive box if needed (but be careful as it might affect other instances)
    super.dispose();
  }
}