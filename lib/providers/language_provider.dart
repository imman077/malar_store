import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

// Language State
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('ta') {
    _loadLanguage();
  }

  // Load saved language preference
  Future<void> _loadLanguage() async {
    final savedLanguage = StorageService.loadLanguage();
    state = savedLanguage;
  }

  // Toggle language between Tamil and English
  Future<void> toggleLanguage() async {
    final newLanguage = state == 'ta' ? 'en' : 'ta';
    state = newLanguage;
    await StorageService.saveLanguage(newLanguage);
  }

  // Set specific language
  Future<void> setLanguage(String locale) async {
    state = locale;
    await StorageService.saveLanguage(locale);
  }
}

// Language Provider
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});
