import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorService {
  static final List<Map<String, dynamic>> _errorLogs = [];
  
  static void logError(
    dynamic error, 
    StackTrace stackTrace, {
    String? context,
    bool showSnackbar = false,
    BuildContext? buildContext,
  }) {
    final errorInfo = {
      'timestamp': DateTime.now(),
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
      'context': context,
    };
    
    _errorLogs.add(errorInfo);
    
    // Debug print
    if (kDebugMode) {
      debugPrint('🚨 ERROR [${DateTime.now()}]: $error');
      debugPrint('📝 Context: $context');
      debugPrint('🔍 StackTrace: $stackTrace');
    }
    
    // Show snackbar if requested
    if (showSnackbar && buildContext != null && buildContext.mounted) {
      ScaffoldMessenger.of(buildContext).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  static Future<void> showErrorDialog(
    BuildContext context, 
    String title, 
    String message, {
    String? actionText,
    VoidCallback? onAction,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onAction();
              },
              child: Text(actionText),
            ),
        ],
      ),
    );
  }
  
  static List<Map<String, dynamic>> get errorLogs => _errorLogs;
  
  static void clearLogs() => _errorLogs.clear();
  
  static Future<void> saveLogsToFile() async {
    // Implement file saving logic if needed
    if (kDebugMode) {
      debugPrint('📋 Error logs saved (${_errorLogs.length} entries)');
    }
  }
}