import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _languageSelected = false;

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    
    // ✅ Get current language and save it
    final lang = Provider.of<LanguageService>(context, listen: false);
    await prefs.setBool('appLanguage', lang.isHindi);
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _selectLanguage(bool isHindi) {
    final lang = Provider.of<LanguageService>(context, listen: false);
    // ✅ Now correctly sets the language (not toggle)
    lang.setLanguage(isHindi);
    setState(() {
      _languageSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Language selection page
    if (!_languageSelected) {
      return _buildLanguageSelectionPage(lang, theme, isDarkMode);
    }

    // ✅ Get correct language for descriptions
    final bool isHindi = lang.isHindi; // Store in variable for use in build

    final List<Map<String, dynamic>> pages = [
      {
        'title': lang.translate('app_title'),
        'desc': isHindi 
            ? 'अपने खर्चों को हिंदी या अंग्रेजी में स्मार्ट तरीके से ट्रैक करें'
            : 'Track your expenses smartly in Hindi or English',
        'icon': Icons.waving_hand,
        'color': Colors.blue,
      },
      {
        'title': isHindi ? 'लेन-देन कैसे जोड़ें' : 'How to Add Transactions',
        'desc': isHindi
            ? '+ बटन दबाएं → आय/खर्च चुनें → राशि डालें → सेव करें'
            : 'Tap + button → Select Income/Expense → Enter amount → Save',
        'icon': Icons.add_circle,
        'color': Colors.green,
      },
      {
        'title': isHindi ? 'मुख्य सुविधाएं' : 'Key Features',
        'desc': isHindi
            ? '• मासिक रिपोर्ट देखें\n• PDF/Excel में निर्यात करें\n• हिंदी/अंग्रेजी स्विच करें'
            : '• View monthly reports\n• Export to PDF/Excel\n• Hindi/English switch',
        'icon': Icons.star,
        'color': Colors.orange,
      },
      {
        'title': isHindi ? 'आपका डेटा सुरक्षित' : 'Your Data is Safe',
        'desc': isHindi
            ? '• सारा डेटा आपके फोन पर\n• कोई डेटा संग्रहण नहीं\n• कभी भी निर्यात करें'
            : '• All data on your device\n• No data collection\n• Export anytime',
        'icon': Icons.security,
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            if (_currentPage < pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      lang.translate('skip'),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Page Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  final Color pageColor = page['color'] as Color;
                  final IconData pageIcon = page['icon'] as IconData;
                  final String pageTitle = page['title'] as String;
                  final String pageDesc = page['desc'] as String;
                  
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: pageColor.withAlpha(30),
                          child: Icon(
                            pageIcon,
                            size: 50,
                            color: pageColor,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // ✅ FIXED: Title with better dark mode visibility
                        Text(
                          pageTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // ✅ FIXED: Description with better dark mode visibility
                        Text(
                          pageDesc,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page Indicators & Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Dots
                  Row(
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index 
                              ? theme.primaryColor 
                              : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next/Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == pages.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _currentPage == pages.length - 1
                          ? lang.translate('get_started')
                          : lang.translate('next'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Language Selection Page with better dark mode visibility
  Widget _buildLanguageSelectionPage(LanguageService lang, ThemeData theme, bool isDarkMode) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ FIXED: Title with better contrast
              Text(
                'Select Language / भाषा चुनें',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // ✅ FIXED: Subtitle with better contrast
              Text(
                'Choose your preferred language for the app',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              
              // English Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ElevatedButton(
                  onPressed: () => _selectLanguage(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    elevation: 4,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'English',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Continue in English',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.blue.shade200 : Colors.blue.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Hindi Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ElevatedButton(
                  onPressed: () => _selectLanguage(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF5F5F5),
                    foregroundColor: const Color(0xFFE65100),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(
                        color: Color(0xFFE65100),
                        width: 2,
                      ),
                    ),
                    elevation: 4,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'हिंदी',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? const Color(0xFFFF8A65) : const Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'हिंदी में जारी रखें',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? const Color(0xFFFFAB91) : const Color(0xFFE65100).withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Skip for now
              TextButton(
                onPressed: () {
                  _selectLanguage(false); // Default to English
                },
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}