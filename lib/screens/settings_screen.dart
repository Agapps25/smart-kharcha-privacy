import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/language_service.dart';
import '../services/transaction_service.dart';
import '../services/export_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  static const String appName = 'Smart Kharcha';
  static const String appVersion = '1.0.0';
  static const String developerEmail = 'agappsolutions25@gmail.com';

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final txService = context.read<TransactionService>();
    final export = ExportService();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('settings')),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // -------- GENERAL --------
          _section(lang.translate('general'), context),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language, color: Colors.blue),
            ),
            title: Text(
              lang.translate('language'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              lang.isHindi ? 'हिंदी' : 'English',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Switch(
              value: lang.isHindi,
              onChanged: (_) => lang.toggleLanguage(),
              activeThumbColor: Colors.blue,
              activeTrackColor: Colors.blue.withAlpha(128),
            ),
          ),
          const Divider(height: 1),

          // -------- DATA & EXPORT --------
          _section(lang.translate('export_pdf'), context), // Changed from 'data_export'
          
          // Export to PDF
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
            title: Text(
              lang.translate('export_pdf'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              lang.isHindi ? 'PDF रिपोर्ट डाउनलोड करें' : 'Download PDF report',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            onTap: () => _exportPDF(context, lang, txService, export),
          ),

          // Export to Excel
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.table_chart, color: Colors.green),
            ),
            title: Text(
              lang.translate('export_excel'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              lang.isHindi ? 'Excel/CSV फाइल डाउनलोड करें' : 'Download Excel/CSV file',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            onTap: () => _exportExcel(context, lang, txService, export),
          ),

          // Clear All Data
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever, color: Colors.orange),
            ),
            title: Text(
              lang.translate('clear_data'),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            subtitle: Text(
              lang.isHindi 
                ? 'सभी लेन-देन स्थायी रूप से हटाएं'
                : 'Permanently delete all transactions',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            onTap: () => _confirmClearAll(context, lang, txService),
          ),
          const Divider(height: 1),

          // -------- SUPPORT & LEGAL --------
          _section(lang.translate('support'), context),
          
          // Contact Us - ✅ FIXED EMAIL ISSUE
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.email, color: Colors.blue),
            ),
            title: Text(
              lang.translate('contact_us'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              lang.isHindi ? 'प्रतिक्रिया या समस्या बताएं' : 'Send feedback or report issue',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            onTap: () => _contactUs(context, lang),
          ),

          // Privacy Policy
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.privacy_tip, color: Colors.purple),
            ),
            title: Text(
              lang.translate('privacy_policy'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              lang.isHindi ? 'ऐप के अंदर देखें' : 'View in app',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            onTap: () => _showPrivacyPolicy(context, lang),
          ),

          // Terms of Service
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description, color: Colors.orange),
            ),
            title: Text(
              lang.translate('terms_of_service'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              lang.isHindi ? 'ऐप के अंदर देखें' : 'View in app',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            onTap: () => _showTermsOfService(context, lang),
          ),

          const Divider(height: 1),

          // -------- APP INFO --------
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                // App Name & Version
                Text(
                  appName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                
                // App Version
                Text(
                  '${lang.isHindi ? 'संस्करण' : 'Version'} $appVersion',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Copyright
                Text(
                  '© ${DateTime.now().year} $appName',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                
                // About button
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showAboutDialog(context, lang),
                  child: Text(
                    lang.isHindi ? 'ऐप के बारे में' : 'About App',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- HELPER FUNCTIONS ----------

  Widget _section(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Export to PDF
  Future<void> _exportPDF(
    BuildContext context,
    LanguageService lang,
    TransactionService txService,
    ExportService export,
  ) async {
    final transactions = txService.allTransactions;
    
    if (transactions.isEmpty) {
      _showSnackBar(
        context,
        lang.translate('no_data'),
        Colors.orange,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.blue.shade600),
            const SizedBox(width: 20),
            Text(lang.isHindi ? 'PDF बन रहा है...' : 'Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      final result = await export.exportToPDFBytes(
        transactions,
        lang.translate('app_title'),
      );

      if (context.mounted) Navigator.pop(context);

      if (result != null && context.mounted) {
        final fileName = '${appName}_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
        
        // Show options: Share or Save
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: Text(lang.isHindi ? 'शेयर करें' : 'Share'),
                subtitle: Text(lang.isHindi ? 'दूसरे ऐप्स के साथ शेयर करें' : 'Share with other apps'),
                onTap: () async {
                  Navigator.pop(context);
                  await export.shareFile(result, fileName);
                  _showSnackBar(
                    context,
                    lang.translate('export_success'),
                    Colors.green,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.save, color: Colors.green),
                title: Text(lang.isHindi ? 'डिवाइस में सेव करें' : 'Save to Device'),
                subtitle: Text(lang.isHindi ? 'डाउनलोड फोल्डर में सेव' : 'Save to Downloads folder'),
                onTap: () async {
                  Navigator.pop(context);
                  final savedPath = await export.saveFileToDevice(result, fileName);
                  if (savedPath != null && context.mounted) {
                    _showSnackBar(
                      context,
                      lang.isHindi ? 'फाइल सेव हो गई: $savedPath' : 'File saved to: $savedPath',
                      Colors.green,
                    );
                  }
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar(
          context,
          lang.isHindi ? 'PDF बनाने में त्रुटि' : 'Error generating PDF',
          Colors.red,
        );
      }
    }
  }

  // Export to Excel
  Future<void> _exportExcel(
    BuildContext context,
    LanguageService lang,
    TransactionService txService,
    ExportService export,
  ) async {
    final transactions = txService.allTransactions;
    
    if (transactions.isEmpty) {
      _showSnackBar(
        context,
        lang.translate('no_data'),
        Colors.orange,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.green.shade600),
            const SizedBox(width: 20),
            Text(lang.isHindi ? 'CSV बन रहा है...' : 'Generating CSV...'),
          ],
        ),
      ),
    );

    try {
      final result = await export.exportToCSVBytes(transactions);

      if (context.mounted) Navigator.pop(context);

      if (result != null && context.mounted) {
        final fileName = '${appName}_Data_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
        
        // Show options: Share or Save
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: Text(lang.isHindi ? 'शेयर करें' : 'Share'),
                subtitle: Text(lang.isHindi ? 'दूसरे ऐप्स के साथ शेयर करें' : 'Share with other apps'),
                onTap: () async {
                  Navigator.pop(context);
                  await export.shareFile(result, fileName);
                  _showSnackBar(
                    context,
                    lang.translate('export_success'),
                    Colors.green,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.save, color: Colors.green),
                title: Text(lang.isHindi ? 'डिवाइस में सेव करें' : 'Save to Device'),
                subtitle: Text(lang.isHindi ? 'डाउनलोड फोल्डर में सेव' : 'Save to Downloads folder'),
                onTap: () async {
                  Navigator.pop(context);
                  final savedPath = await export.saveFileToDevice(result, fileName);
                  if (savedPath != null && context.mounted) {
                    _showSnackBar(
                      context,
                      lang.isHindi ? 'फाइल सेव हो गई: $savedPath' : 'File saved to: $savedPath',
                      Colors.green,
                    );
                  }
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar(
          context,
          lang.isHindi ? 'CSV बनाने में त्रुटि' : 'Error generating CSV',
          Colors.red,
        );
      }
    }
  }

  // ✅ FIXED: Contact Us Email Launch
  Future<void> _contactUs(BuildContext context, LanguageService lang) async {
    try {
      final subject = Uri.encodeComponent('$appName - Feedback/Issue');
      final body = Uri.encodeComponent('''
App Version: $appVersion
Platform: ${Platform.isAndroid ? 'Android' : 'iOS'}

Type: [Bug/Feedback/Suggestion/Other]

Description:


''');
      
      final uri = Uri.parse('mailto:$developerEmail?subject=$subject&body=$body');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: Copy email to clipboard
        await _copyToClipboard(context, lang, developerEmail);
      }
    } catch (e) {
      if (context.mounted) {
        await _copyToClipboard(context, lang, developerEmail);
      }
    }
  }

  // Copy to clipboard fallback
  Future<void> _copyToClipboard(BuildContext context, LanguageService lang, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      _showSnackBar(
        context,
        lang.isHindi ? 'ईमेल कॉपी हो गया: $developerEmail' : 'Email copied: $developerEmail',
        Colors.blue,
      );
    }
  }

  // Show Privacy Policy Dialog
  void _showPrivacyPolicy(BuildContext context, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('privacy_policy')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.translate('privacy_policy'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lang.isHindi
                  ? '''
1. डेटा संग्रहण
   • यह ऐप आपका कोई व्यक्तिगत डेटा संग्रहित नहीं करता।
   • सभी लेन-देन डेटा आपके डिवाइस पर स्थानीय रूप से संग्रहित होता है।

2. इंटरनेट अनुमति
   • इंटरनेट अनुमति सिर्फ ईमेल भेजने और वेब लिंक खोलने के लिए उपयोग की जाती है।

3. तीसरे पक्ष
   • हम आपका डेटा किसी तीसरे पक्ष के साथ साझा नहीं करते।

4. संपर्क
   • प्रश्नों के लिए: $developerEmail
                  '''
                  : '''
1. Data Collection
   • This app does not collect any personal data.
   • All transaction data is stored locally on your device.

2. Internet Permission
   • Internet permission is only used for sending emails and opening web links.

3. Third Parties
   • We do not share your data with any third parties.

4. Contact
   • For questions: $developerEmail
                  ''',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('ok')),
          ),
        ],
      ),
    );
  }

  // Show Terms of Service Dialog
  void _showTermsOfService(BuildContext context, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('terms_of_service')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.translate('terms_of_service'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lang.isHindi
                  ? '''
1. सेवा का उपयोग
   • यह ऐप व्यक्तिगत खर्च ट्रैकिंग के लिए है।
   • व्यावसायिक उपयोग के लिए लाइसेंस की आवश्यकता है।

2. जिम्मेदारी
   • डेटा हानि के लिए हम जिम्मेदार नहीं हैं।
   • नियमित बैकअप लेने की सलाह दी जाती है।

3. सेवा परिवर्तन
   • हम बिना सूचना के सेवा बदल सकते हैं।

4. संपर्क
   • प्रश्नों के लिए: $developerEmail
                  '''
                  : '''
1. Service Usage
   • This app is for personal expense tracking.
   • Commercial use requires a license.

2. Liability
   • We are not responsible for data loss.
   • Regular backups are recommended.

3. Service Changes
   • We may change the service without notice.

4. Contact
   • For questions: $developerEmail
                  ''',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('ok')),
          ),
        ],
      ),
    );
  }

  // Show About Dialog
  void _showAboutDialog(BuildContext context, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.isHindi ? 'ऐप के बारे में' : 'About App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text('${lang.isHindi ? 'संस्करण' : 'Version'}: $appVersion'),
            const SizedBox(height: 8),
            Text(
              lang.isHindi 
                ? 'सभी खर्चों को ट्रैक करने के लिए सरल और आसान ऐप।'
                : 'A simple and easy app to track all your expenses.'
            ),
            const SizedBox(height: 12),
            Text(
              lang.isHindi 
                ? '© ${DateTime.now().year} सर्वाधिकार सुरक्षित'
                : '© ${DateTime.now().year} All rights reserved',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('ok')),
          ),
        ],
      ),
    );
  }

  // Clear All Data Confirmation
  void _confirmClearAll(
    BuildContext context,
    LanguageService lang,
    TransactionService txService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('confirm')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.translate('clear_warning')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lang.isHindi 
                        ? 'कुल लेन-देन: ${txService.allTransactions.length}'
                        : 'Total Transactions: ${txService.allTransactions.length}',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.isHindi 
                ? 'यह कार्य पूर्ववत नहीं किया जा सकता'
                : 'This action cannot be undone',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.translate('cancel'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(color: Colors.red),
                      const SizedBox(width: 20),
                      Text(lang.isHindi ? 'डेटा हट रहा है...' : 'Deleting data...'),
                    ],
                  ),
                ),
              );

              await txService.clearAll();
              
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                
                _showSnackBar(
                  context,
                  lang.isHindi 
                    ? 'सभी लेन-देन हटाए गए' 
                    : 'All transactions deleted',
                  Colors.red,
                );
              }
            },
            child: Text(
              lang.translate('delete_all'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Show SnackBar
  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}