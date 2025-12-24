import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/language_service.dart';
import '../services/error_service.dart';
import '../widgets/category_chips.dart';
import '../utils/security_utils.dart';
import '../utils/constants.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _selectedType;
  Category? _selectedCategory;
  late PaymentMethod _selectedPaymentMethod;
  late DateTime _selectedDate;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSubmitting = false;
  bool _isDeleting = false;
  Timer? _autoSaveTimer;

  // ✅ Hindi categories mapping
  final Map<String, String> _hindiCategories = {
    'food': 'खाना',
    'transport': 'यातायात',
    'shopping': 'खरीदारी',
    'entertainment': 'मनोरंजन',
    'bills': 'बिल',
    'health': 'स्वास्थ्य',
    'education': 'शिक्षा',
    'other': 'अन्य',
    'income': 'आय',
  };

  String _getCategoryDisplayName(Category category, LanguageService lang) {
    if (lang.isHindi && _hindiCategories.containsKey(category.name)) {
      return _hindiCategories[category.name]!;
    }
    return category.name[0].toUpperCase() + category.name.substring(1);
  }

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      final t = widget.transaction!;
      _selectedType = t.type;
      _selectedCategory = t.category;
      _selectedPaymentMethod = t.paymentMethod;
      _selectedDate = t.date;
      _titleController.text = t.title;
      _amountController.text = t.amount.toStringAsFixed(2);
      _descController.text = t.description ?? '';
    } else {
      _selectedType = TransactionType.expense;
      _selectedCategory = null;
      _selectedPaymentMethod = PaymentMethod.cash;
      _selectedDate = DateTime.now();
    }

    _startAutoSaveTimer();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_formKey.currentState?.validate() ?? false) {
        _autoSaveDraft();
      }
    });
  }

  Future<void> _autoSaveDraft() async {
    if (_isSubmitting || _isDeleting) return;
    
    try {
      if (_titleController.text.trim().isNotEmpty && 
          _amountController.text.trim().isNotEmpty) {
        
        if (kDebugMode) {
          debugPrint('💾 Auto-saving draft...');
        }
      }
    } catch (error, stackTrace) {
      ErrorService.logError(error, stackTrace, context: 'Auto Save Draft');
    }
  }

  Future<void> _pickDate() async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              // ✅ FIX: Use DialogTheme instead of DialogThemeData
              dialogTheme: DialogThemeData(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() => _selectedDate = picked);
        
        if (kDebugMode) {
          debugPrint('📅 Date selected: ${DateFormat('dd/MM/yyyy').format(picked)}');
        }
      }
    } catch (error, stackTrace) {
      ErrorService.logError(
        error, 
        stackTrace, 
        context: 'Pick Date',
        showSnackbar: true,
        buildContext: context,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ErrorService.showErrorDialog(
        context,
        'Validation Error',
        'Please fix the errors in the form before submitting.',
      );
      return;
    }

    if (_selectedCategory == null) {
      ErrorService.showErrorDialog(
        context,
        'Category Required',
        'Please select a category for this transaction.',
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || !SecurityUtils.isValidAmount(_amountController.text)) {
      ErrorService.showErrorDialog(
        context,
        'Invalid Amount',
        'Please enter a valid amount between ₹1 and ₹1,00,00,00,000.',
      );
      return;
    }

    final title = _titleController.text.trim();
    if (!SecurityUtils.isValidTitle(title)) {
      ErrorService.showErrorDialog(
        context,
        'Invalid Title',
        'Title must be between 1 and 100 characters.',
      );
      return;
    }

    if (!SecurityUtils.isValidDate(_selectedDate)) {
      ErrorService.showErrorDialog(
        context,
        'Invalid Date',
        'Please select a valid date between 2020 and today.',
      );
      return;
    }

    final description = _descController.text.trim();
    if (!SecurityUtils.isValidDescription(description)) {
      ErrorService.showErrorDialog(
        context,
        'Description Too Long',
        'Description must be 500 characters or less.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tx = TransactionModel(
        id: widget.transaction?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: SecurityUtils.sanitizeInput(title),
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory!,
        paymentMethod: _selectedPaymentMethod,
        type: _selectedType,
        description: description.isNotEmpty
            ? SecurityUtils.sanitizeInput(description)
            : null,
      );

      final service = context.read<TransactionService>();
      
      if (widget.transaction == null) {
        await service.addTransaction(tx);
        
        if (kDebugMode) {
          debugPrint('✅ New transaction saved: ${tx.title} - ₹${tx.amount}');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<LanguageService>().translate('save')),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        await service.updateTransaction(tx);
        
        if (kDebugMode) {
          debugPrint('✏️ Transaction updated: ${tx.title}');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<LanguageService>().translate('update')),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      ErrorService.logError(
        e, 
        stackTrace, 
        context: 'Submit Transaction',
        showSnackbar: true,
        buildContext: context,
      );
      
      if (mounted) {
        await ErrorService.showErrorDialog(
          context,
          'Save Failed',
          'Failed to save transaction. Please try again.\n\nError: ${e.toString()}',
          actionText: 'Retry',
          onAction: _submit,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction != null
              ? lang.translate('edit_entry')
              : lang.translate('new_entry'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: _isDeleting ? null : () => _confirmDelete(context, lang),
              tooltip: lang.isHindi ? 'हटाएं' : 'Delete',
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeToggle(lang, theme),
                      const SizedBox(height: 24),

                      // AMOUNT
                      TextFormField(
                        controller: _amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: _inputDecoration(
                          context,
                          lang.translate('amount'),
                          Icons.currency_rupee_rounded,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Amount is required';
                          }
                          final n = double.tryParse(v);
                          if (n == null) {
                            return 'Enter a valid number';
                          }
                          if (n <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          if (n > 1000000000) {
                            return 'Amount must be less than ₹1,00,00,00,000';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // TITLE
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: _inputDecoration(
                          context,
                          lang.translate('title_hint'),
                          Icons.edit_note_rounded,
                        ),
                        maxLength: 100,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (v.trim().length > 100) {
                            return 'Title must be 100 characters or less';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // DATE
                      _section(lang.translate('date'), theme),
                      _dateTile(theme),
                      const SizedBox(height: 24),

                      // CATEGORY
                      _section(lang.translate('category'), theme),
                      CategoryChips(
                        transactionType: _selectedType,
                        selectedCategory: _selectedCategory,
                        onSelected: (cat) {
                          setState(() => _selectedCategory = cat);
                          
                          if (kDebugMode) {
                            debugPrint('🏷️ Category selected: ${cat.name}');
                          }
                        },
                        getCategoryDisplayName: (category) => 
                            _getCategoryDisplayName(category, lang), // ✅ Fixed
                      ),
                      const SizedBox(height: 24),

                      // PAYMENT MODE
                      _section(lang.translate('payment_mode'), theme),
                      DropdownButtonFormField<PaymentMethod>(
                        initialValue: _selectedPaymentMethod,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                          prefixIcon: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
                        items: PaymentMethod.values.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Row(
                              children: [
                                Icon(
                                  _paymentIcon(method),
                                  size: 18,
                                  color: isDarkMode ? Colors.white70 : Colors.blueGrey,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _getPaymentMethodName(method, lang),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedPaymentMethod = v);
                            
                            if (kDebugMode) {
                              debugPrint('💳 Payment method: ${v.name}');
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // NOTES
                      TextFormField(
                        controller: _descController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        maxLines: 3,
                        maxLength: 500,
                        decoration: _inputDecoration(
                          context,
                          lang.translate('notes'),
                          Icons.notes_rounded,
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),

            // BOTTOM BAR
            SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(128),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting || _isDeleting 
                            ? null 
                            : () {
                                _autoSaveTimer?.cancel();
                                Navigator.pop(context);
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: theme.primaryColor),
                        ),
                        child: Text(
                          lang.translate('cancel').toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting || _isDeleting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                (widget.transaction != null
                                        ? lang.translate('update')
                                        : lang.translate('save'))
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _section(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.blueGrey,
            fontSize: 16,
          ),
        ),
      );

  InputDecoration _inputDecoration(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
      ),
      prefixIcon: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
      filled: true,
      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _dateTile(ThemeData theme) => InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.brightness == Brightness.dark 
                  ? Colors.grey.shade700 
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(14),
            color: theme.brightness == Brightness.dark 
                ? Colors.grey[800] 
                : Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: theme.brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      );

  Widget _buildTypeToggle(LanguageService lang, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _typeBtn(TransactionType.expense,
              lang.translate('expense'), AppConstants.expenseColor, theme),
          _typeBtn(TransactionType.income,
              lang.translate('income'), AppConstants.incomeColor, theme),
        ],
      ),
    );
  }

  Widget _typeBtn(TransactionType type, String text, Color color, ThemeData theme) {
    final selected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCategory = null;
          });
          
          if (kDebugMode) {
            debugPrint('💰 Transaction type: ${type.name}');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : 
                    (theme.brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade700),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _paymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.upi:
        return Icons.qr_code_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.netBanking:
        return Icons.account_balance_rounded;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  String _getPaymentMethodName(PaymentMethod method, LanguageService lang) {
    if (lang.isHindi) {
      switch (method) {
        case PaymentMethod.cash: return 'नकद';
        case PaymentMethod.upi: return 'UPI';
        case PaymentMethod.card: return 'कार्ड';
        case PaymentMethod.netBanking: return 'नेट बैंकिंग';
        case PaymentMethod.wallet: return 'डिजिटल वॉलेट';
        default: return method.name;
      }
    }
    return method.name[0].toUpperCase() + method.name.substring(1);
  }

  void _confirmDelete(BuildContext context, LanguageService lang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        // ✅ FIX: Use dialogTheme instead of dialogBackgroundColor
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: Text(
          lang.isHindi ? 'हटाएं?' : 'Delete?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          lang.isHindi
            ? 'क्या आप इस एंट्री को हटाना चाहते हैं? यह क्रिया वापस नहीं की जा सकती।'
            : 'Are you sure you want to delete this transaction? This action cannot be undone.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(178), // ✅ FIX: 0.7 opacity = 178 alpha
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isDeleting = true);
              try {
                await context.read<TransactionService>().deleteTransaction(widget.transaction!.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lang.translate('delete_msg')),
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: lang.translate('undo'),
                        onPressed: () async {
                          try {
                            await context.read<TransactionService>().undoDelete();
                          } catch (e, stackTrace) {
                            ErrorService.logError(
                              e, 
                              stackTrace, 
                              context: 'Undo Delete from Snackbar',
                              showSnackbar: true,
                              buildContext: context,
                            );
                          }
                        },
                      ),
                    ),
                  );
                  Navigator.pop(context, true);
                }
              } catch (e, stackTrace) {
                ErrorService.logError(
                  e,
                  stackTrace,
                  context: 'Delete Transaction',
                  showSnackbar: true,
                  buildContext: context,
                );
              } finally {
                if (mounted) setState(() => _isDeleting = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(lang.translate('delete')),
          ),
        ],
      ),
    );
  }
}