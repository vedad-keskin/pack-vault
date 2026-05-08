import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations_en.dart';
import 'translations_bs.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  String _currentLanguage = 'en';

  LanguageService() {
    _loadLanguage();
  }

  String get currentLanguage => _currentLanguage;

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLanguage == langCode) return;
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, langCode);
    notifyListeners();
  }

  String translate(String key) {
    if (_currentLanguage == 'bs') {
      return bsTranslations[key] ?? enTranslations[key] ?? key;
    }
    return enTranslations[key] ?? key;
  }
}
