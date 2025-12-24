import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ ADD THIS BACK
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/transaction.dart';
import 'services/transaction_service.dart';
import 'services/language_service.dart';
import 'services/error_service.dart';
import 'utils/security_utils.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔹 Initialize Hive
    await Hive.initFlutter();

    // 🔹 Register Hive adapters
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(PaymentMethodAdapter());
    Hive.registerAdapter(TransactionModelAdapter());

    // 🔹 Open Hive box
    await Hive.openBox<TransactionModel>('transactions_box');

    // 🔹 Apply security settings
    await SecurityUtils.secureApp();

    // 🔹 System UI style (DARK MODE COMPATIBLE)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    runApp(const MyApp());
  } catch (error, stackTrace) {
    ErrorService.logError(error, stackTrace, context: 'App Initialization');

    runApp(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'App failed to start.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Please restart the app.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 20),
                    Text(
                      'Error loading app',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final hasSeenOnboarding = data['hasSeenOnboarding'] as bool;
        final savedLanguage = data['savedLanguage'] as bool;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TransactionService()),
            ChangeNotifierProvider(
              create: (_) => LanguageService()..initialize(savedLanguage),
            ),
          ],
          child: Consumer<LanguageService>(
            builder: (context, langService, _) {
              return MaterialApp(
                title: langService.translate('app_title'),
                debugShowCheckedModeBanner: false,
                
                // 🎨 THEMES
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.system,
                
                // ✅ Splash Screen से start करें
                home: SplashScreen(
                  hasSeenOnboarding: hasSeenOnboarding,
                ),
                
                // 🌍 Global error UI
                builder: (context, child) {
                  ErrorWidget.builder = (errorDetails) {
                    ErrorService.logError(
                      errorDetails.exception,
                      errorDetails.stack ?? StackTrace.current,
                      context: 'Flutter Error Widget',
                    );

                    return Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 64,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Something went wrong',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getErrorMessage(errorDetails.exception),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(178),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SplashScreen(
                                        hasSeenOnboarding: hasSeenOnboarding,
                                      ),
                                    ),
                                    (_) => false,
                                  );
                                },
                                child: Text(langService.translate('ok')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  };

                  return child!;
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _initializeApp() async {
    // 🔹 Load preferences
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final savedLanguage = prefs.getBool('appLanguage') ?? false;
    
    return {
      'hasSeenOnboarding': hasSeenOnboarding,
      'savedLanguage': savedLanguage,
    };
  }

  String _getErrorMessage(dynamic exception) {
    final errorStr = exception.toString();
    return errorStr.length > 100 ? '${errorStr.substring(0, 100)}...' : errorStr;
  }
}