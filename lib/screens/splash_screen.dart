import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/language_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool hasSeenOnboarding;

  const SplashScreen({
    super.key,
    required this.hasSeenOnboarding,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // 2 seconds splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Navigate to appropriate screen
    if (widget.hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51), // ✅ withAlpha instead of withOpacity
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 70,
                  color: Colors.blue,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // App Name
              Text(
                lang.translate('app_title'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Tagline
              Text(
                lang.isHindi ? 'स्मार्ट खर्चा प्रबंधन' : 'Smart Expense Manager',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withAlpha(204), // ✅ withAlpha instead of withOpacity
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Loading Indicator
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              
              const SizedBox(height: 20),
              
              // Loading Text
              Text(
                lang.isHindi ? 'लोड हो रहा है...' : 'Loading...',
                style: TextStyle(
                  color: Colors.white.withAlpha(153), // ✅ withAlpha instead of withOpacity
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}