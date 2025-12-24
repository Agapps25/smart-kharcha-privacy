import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  bool _isHindi = false;
  bool get isHindi => _isHindi;

  // ✅ Initialize with saved language
  void initialize(bool savedValue) {
    _isHindi = savedValue;
    notifyListeners();
  }

  // ✅ Set language to specific value (not toggle)
  void setLanguage(bool isHindi) async {
    _isHindi = isHindi;
    
    // ✅ Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appLanguage', _isHindi);
    
    notifyListeners();
  }

  // ✅ Toggle method for UI switches
  void toggleLanguage() async {
    _isHindi = !_isHindi;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appLanguage', _isHindi);
    
    notifyListeners();
  }

  String translate(String key) {
    final Map<String, Map<String, String>> values = {
      // App
      'app_title': {'en': 'Smart Kharcha', 'hi': 'स्मार्ट खर्चा '},

      // Home / Stats
      'balance': {'en': 'Balance', 'hi': 'बैलेंस'},
      'net_balance': {'en': 'Net Balance', 'hi': 'कुल बैलेंस'},
      'income': {'en': 'Income', 'hi': 'आय'},
      'expense': {'en': 'Expense', 'hi': 'खर्च'},

      // Actions
      'new_entry': {'en': 'New Entry', 'hi': 'नई एंट्री'},
      'save': {'en': 'SAVE', 'hi': 'सुरक्षित करें'},
      'cancel': {'en': 'CANCEL', 'hi': 'रद्द करें'},
      'update': {'en': 'UPDATE', 'hi': 'अपडेट करें'},
      'edit_entry': {'en': 'Edit Entry', 'hi': 'एंट्री बदलें'},
      'undo': {'en': 'UNDO', 'hi': 'वापस लें'},

      // Search & empty
      'search_hint': {
        'en': 'Search title, category, amount...',
        'hi': 'शीर्षक, श्रेणी, राशि खोजें...'
      },
      'no_data': {
        'en': 'No transactions found',
        'hi': 'कोई डेटा नहीं मिला'
      },
      'delete_msg': {
        'en': 'Transaction deleted',
        'hi': 'एंट्री हटा दी गई'
      },

      // Filters
      'today': {'en': 'Today', 'hi': 'आज'},
      'weekly': {'en': 'Weekly', 'hi': 'साप्ताहिक'},
      'monthly': {'en': 'Monthly', 'hi': 'मासिक'},
      'all': {'en': 'All', 'hi': 'सभी'},
      'all_time': {'en': 'All Time', 'hi': 'सभी समय'},

      // Forms
      'amount': {'en': 'Amount', 'hi': 'राशि'},
      'title_hint': {'en': 'Title / Note', 'hi': 'शीर्षक / नोट'},
      'category': {'en': 'Category', 'hi': 'श्रेणी'},
      'payment_mode': {'en': 'Payment Mode', 'hi': 'भुगतान का तरीका'},

      // Reports
      'reports': {'en': 'Reports', 'hi': 'रिपोर्ट्स'},
      'spending_by_category': {
        'en': 'Spending by Category',
        'hi': 'श्रेणी अनुसार खर्च'
      },

      // Settings - General
      'settings': {'en': 'Settings', 'hi': 'सेटिंग्स'},
      'general': {'en': 'General', 'hi': 'सामान्य'},
      'language': {'en': 'Language', 'hi': 'भाषा'},

      // Settings - Reports & Export
      'export_pdf': {'en': 'Export to PDF', 'hi': 'PDF में निर्यात करें'},
      'export_excel': {'en': 'Export to Excel', 'hi': 'Excel में निर्यात करें'},
      'export_success': {'en': 'Export successful', 'hi': 'निर्यात सफल'},

      // Settings - Support
      'support': {'en': 'Support', 'hi': 'सहायता'},
      'contact_us': {'en': 'Contact Us', 'hi': 'संपर्क करें'},
      'report_bug': {'en': 'Report Bug', 'hi': 'बग रिपोर्ट करें'},

      // Settings - Legal
      'legal': {'en': 'Legal', 'hi': 'कानूनी'},
      'privacy_policy': {'en': 'Privacy Policy', 'hi': 'गोपनीयता नीति'},
      'terms_of_service': {'en': 'Terms of Service', 'hi': 'सेवा की शर्तें'},

      // Settings - Data
      'data_storage': {'en': 'Data Storage', 'hi': 'डेटा संग्रहण'},
      'local_data_info': {
        'en': 'Local Storage Info',
        'hi': 'स्थानीय संग्रहण जानकारी'
      },
      'clear_data': {'en': 'Clear All Data', 'hi': 'सभी डेटा साफ करें'},
      'confirm': {'en': 'Confirm', 'hi': 'पुष्टि करें'},
      'clear_warning': {
        'en': 'This will delete all transactions permanently.',
        'hi': 'यह सभी लेन-देन स्थायी रूप से हटा देगा।'
      },
      'delete_all': {'en': 'Delete All', 'hi': 'सब हटाएं'},

      // Settings - About
      'about': {'en': 'About', 'hi': 'के बारे में'},

      // Common
      'ok': {'en': 'OK', 'hi': 'ठीक है'},

      // Onboarding
      'skip': {'en': 'Skip', 'hi': 'छोड़ें'},
      'next': {'en': 'Next', 'hi': 'अगला'},
      'get_started': {'en': 'Get Started', 'hi': 'शुरू करें'},

      // Categories
      'food': {'en': 'Food', 'hi': 'खाना'},
      'transport': {'en': 'Transport', 'hi': 'यातायात'},
      'shopping': {'en': 'Shopping', 'hi': 'शॉपिंग'},
      'bills': {'en': 'Bills', 'hi': 'बिल'},
      'entertainment': {'en': 'Entertainment', 'hi': 'मनोरंजन'},
      'health': {'en': 'Health', 'hi': 'स्वास्थ्य'},
      'education': {'en': 'Education', 'hi': 'शिक्षा'},
      'other': {'en': 'Other', 'hi': 'अन्य'},

      // Payment Modes
      'cash': {'en': 'Cash', 'hi': 'कैश'},
      'card': {'en': 'Card', 'hi': 'कार्ड'},
      'upi': {'en': 'UPI', 'hi': 'यूपीआई'},
      'online': {'en': 'Online', 'hi': 'ऑनलाइन'},

      // Months
      'january': {'en': 'January', 'hi': 'जनवरी'},
      'february': {'en': 'February', 'hi': 'फरवरी'},
      'march': {'en': 'March', 'hi': 'मार्च'},
      'april': {'en': 'April', 'hi': 'अप्रैल'},
      'may': {'en': 'May', 'hi': 'मई'},
      'june': {'en': 'June', 'hi': 'जून'},
      'july': {'en': 'July', 'hi': 'जुलाई'},
      'august': {'en': 'August', 'hi': 'अगस्त'},
      'september': {'en': 'September', 'hi': 'सितंबर'},
      'october': {'en': 'October', 'hi': 'अक्टूबर'},
      'november': {'en': 'November', 'hi': 'नवंबर'},
      'december': {'en': 'December', 'hi': 'दिसंबर'},

      // Days
      'sunday': {'en': 'Sunday', 'hi': 'रविवार'},
      'monday': {'en': 'Monday', 'hi': 'सोमवार'},
      'tuesday': {'en': 'Tuesday', 'hi': 'मंगलवार'},
      'wednesday': {'en': 'Wednesday', 'hi': 'बुधवार'},
      'thursday': {'en': 'Thursday', 'hi': 'गुरुवार'},
      'friday': {'en': 'Friday', 'hi': 'शुक्रवार'},
      'saturday': {'en': 'Saturday', 'hi': 'शनिवार'},

      // Report Screen
      'total_income': {'en': 'Total Income', 'hi': 'कुल आय'},
      'total_expense': {'en': 'Total Expense', 'hi': 'कुल खर्च'},
      'balance_report': {'en': 'Balance', 'hi': 'बचत'},
      'top_categories': {'en': 'Top Categories', 'hi': 'शीर्ष श्रेणियाँ'},
      'transactions': {'en': 'Transactions', 'hi': 'लेन-देन'},
      'no_transactions': {
        'en': 'No transactions for this period',
        'hi': 'इस अवधि में कोई लेन-देन नहीं'
      },
      'select_period': {
        'en': 'Select Period',
        'hi': 'अवधि चुनें'
      },
      'custom_period': {
        'en': 'Custom Period',
        'hi': 'कस्टम अवधि'
      },

      // Add Transaction Screen
      'add_transaction': {
        'en': 'Add Transaction',
        'hi': 'लेन-देन जोड़ें'
      },
      'edit_transaction': {
        'en': 'Edit Transaction',
        'hi': 'लेन-देन बदलें'
      },
      'select_date': {'en': 'Select Date', 'hi': 'तारीख चुनें'},
      'select_category': {'en': 'Select Category', 'hi': 'श्रेणी चुनें'},
      'select_payment': {'en': 'Select Payment', 'hi': 'भुगतान चुनें'},
      'description': {'en': 'Description', 'hi': 'विवरण'},
      'enter_amount': {'en': 'Enter Amount', 'hi': 'राशि दर्ज करें'},
      'amount_required': {
        'en': 'Amount is required',
        'hi': 'राशि आवश्यक है'
      },
      'title_required': {
        'en': 'Title is required',
        'hi': 'शीर्षक आवश्यक है'
      },

      // All Transactions Screen
      'all_transactions': {
        'en': 'All Transactions',
        'hi': 'सभी लेन-देन'
      },
      'filter_by': {'en': 'Filter by', 'hi': 'फ़िल्टर करें'},
      'sort_by': {'en': 'Sort by', 'hi': 'क्रमबद्ध करें'},
      'date_newest': {'en': 'Date (Newest)', 'hi': 'तारीख (नवीनतम)'},
      'date_oldest': {'en': 'Date (Oldest)', 'hi': 'तारीख (पुराना)'},
      'amount_high': {'en': 'Amount (High to Low)', 'hi': 'राशि (उच्च से निम्न)'},
      'amount_low': {'en': 'Amount (Low to High)', 'hi': 'राशि (निम्न से उच्च)'},
      'category_filter': {'en': 'Category', 'hi': 'श्रेणी'},
      'type_filter': {'en': 'Type', 'hi': 'प्रकार'},
      'payment_filter': {'en': 'Payment Mode', 'hi': 'भुगतान तरीका'},

      // Home Screen
      'welcome': {'en': 'Welcome', 'hi': 'स्वागत है'},
      'today_expense': {'en': "Today's Expense", 'hi': 'आज का खर्च'},
      'this_month': {'en': 'This Month', 'hi': 'इस महीने'},
      'last_month': {'en': 'Last Month', 'hi': 'पिछले महीने'},
      'recent_transactions': {
        'en': 'Recent Transactions',
        'hi': 'हाल के लेन-देन'
      },
      'view_all': {'en': 'View All', 'hi': 'सभी देखें'},
      'add_first_transaction': {
        'en': 'Add your first transaction',
        'hi': 'अपना पहला लेन-देन जोड़ें'
      },

      // ✅ Add more translations as needed
      'income_type': {'en': 'Income', 'hi': 'आय'},
      'expense_type': {'en': 'Expense', 'hi': 'खर्च'},
      'select_type': {'en': 'Select Type', 'hi': 'प्रकार चुनें'},
      'date': {'en': 'Date', 'hi': 'तारीख'},
      'time': {'en': 'Time', 'hi': 'समय'},
      'no_category': {'en': 'No Category', 'hi': 'कोई श्रेणी नहीं'},
      'all_categories': {'en': 'All Categories', 'hi': 'सभी श्रेणियाँ'},
      'income_categories': {'en': 'Income Categories', 'hi': 'आय श्रेणियाँ'},
      'expense_categories': {'en': 'Expense Categories', 'hi': 'खर्च श्रेणियाँ'},
      'select_month': {'en': 'Select Month', 'hi': 'महीना चुनें'},
      'select_year': {'en': 'Select Year', 'hi': 'साल चुनें'},
      'jan': {'en': 'Jan', 'hi': 'जन'},
      'feb': {'en': 'Feb', 'hi': 'फर'},
      'mar': {'en': 'Mar', 'hi': 'मार्च'},
      'apr': {'en': 'Apr', 'hi': 'अप्रै'},
      'jun': {'en': 'Jun', 'hi': 'जून'},
      'jul': {'en': 'Jul', 'hi': 'जुल'},
      'aug': {'en': 'Aug', 'hi': 'अग'},
      'sep': {'en': 'Sep', 'hi': 'सितं'},
      'oct': {'en': 'Oct', 'hi': 'अक्टू'},
      'nov': {'en': 'Nov', 'hi': 'नवं'},
      'dec': {'en': 'Dec', 'hi': 'दिसं'},
    };

    // ✅ Return translation or the key itself if not found
    return values[key]?[_isHindi ? 'hi' : 'en'] ?? key;
  }

  // ✅ Helper method to get language name
  String get currentLanguageName => _isHindi ? 'हिंदी' : 'English';

  // ✅ Helper method to get language code
  String get currentLanguageCode => _isHindi ? 'hi' : 'en';

  // ✅ Load saved language from SharedPreferences
  static Future<bool> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('appLanguage') ?? false; // Default to English (false)
    } catch (e) {
      return false; // Default to English on error
    }
  }

  // ✅ Clear language preference
  Future<void> clearLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('appLanguage');
    _isHindi = false; // Reset to default (English)
    notifyListeners();
  }
}