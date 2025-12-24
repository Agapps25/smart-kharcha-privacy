import 'dart:io';
import 'package:flutter/services.dart';

class SecurityUtils {
  // Input validation
  static bool isValidAmount(String amount) {
    try {
      final value = double.parse(amount);
      return value > 0 && value <= 1000000000; // Max 1 billion
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidTitle(String title) {
    final trimmed = title.trim();
    return trimmed.isNotEmpty && trimmed.length <= 100;
  }
  
  static bool isValidDescription(String? description) {
    if (description == null) return true;
    return description.length <= 500;
  }
  
  // Input sanitization
  static String sanitizeInput(String input) {
    return input.replaceAll(RegExp(r'[<>{}[\]]'), '');
  }
  
  // Date validation
  static bool isValidDate(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now.add(const Duration(days: 1))) && 
           date.isAfter(DateTime(2020, 1, 1));
  }
  
  // File validation for exports
  static bool isValidFilePath(String path) {
    try {
      final file = File(path);
      return file.existsSync() && file.lengthSync() < 10 * 1024 * 1024; // 10MB limit
    } catch (e) {
      return false;
    }
  }
  
  // Platform-specific security
  static Future<void> secureApp() async {
    if (Platform.isAndroid) {
      // Android-specific security
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    
    // Prevent screenshot in sensitive screens (optional)
    // await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}