import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'nativeName': 'English', 'code': 'en'},
    {'name': 'Arabic', 'nativeName': 'العربية', 'code': 'ar'},
    {'name': 'French', 'nativeName': 'Français', 'code': 'fr'},
    {'name': 'Spanish', 'nativeName': 'Español', 'code': 'es'},
    {'name': 'German', 'nativeName': 'Deutsch', 'code': 'de'},
    {'name': 'Italian', 'nativeName': 'Italiano', 'code': 'it'},
    {'name': 'Portuguese', 'nativeName': 'Português', 'code': 'pt'},
    {'name': 'Russian', 'nativeName': 'Русский', 'code': 'ru'},
    {'name': 'Chinese', 'nativeName': '中文', 'code': 'zh'},
    {'name': 'Japanese', 'nativeName': '日本語', 'code': 'ja'},
    {'name': 'Korean', 'nativeName': '한국어', 'code': 'ko'},
    {'name': 'Hindi', 'nativeName': 'हिन्दी', 'code': 'hi'},
    {'name': 'Turkish', 'nativeName': 'Türkçe', 'code': 'tr'},
    {'name': 'Dutch', 'nativeName': 'Nederlands', 'code': 'nl'},
    {'name': 'Swedish', 'nativeName': 'Svenska', 'code': 'sv'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Language',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.language, color: AppColors.charcoal, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select your preferred language for the app',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Language List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _languages.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = _selectedLanguage == language['name'];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  title: Text(
                    language['name']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.charcoal,
                    ),
                  ),
                  subtitle: Text(
                    language['nativeName']!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral600,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryColor,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLanguage = language['name']!;
                    });
                    _showLanguageChangeDialog(language['name']!);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageChangeDialog(String language) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Change Language',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Change app language to $language? The app will restart to apply changes.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedLanguage = 'English'; // Revert
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language changed to $language')),
              );
              // In a real app, you would apply the language change here
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
