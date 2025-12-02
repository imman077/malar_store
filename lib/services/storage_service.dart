import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/credit_note.dart';
import '../utils/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Save Products
  static Future<bool> saveProducts(List<Product> products) async {
    try {
      final jsonList = products.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      return await prefs.setString(StorageKeys.products, jsonString);
    } catch (e) {
      print('Error saving products: $e');
      return false;
    }
  }

  // Load Products
  static Future<List<Product>> loadProducts() async {
    try {
      final jsonString = prefs.getString(StorageKeys.products);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error loading products: $e');
      return [];
    }
  }

  // Save Credit Notes
  static Future<bool> saveCreditNotes(List<CreditNote> credits) async {
    try {
      final jsonList = credits.map((c) => c.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      return await prefs.setString(StorageKeys.credits, jsonString);
    } catch (e) {
      print('Error saving credit notes: $e');
      return false;
    }
  }

  // Load Credit Notes
  static Future<List<CreditNote>> loadCreditNotes() async {
    try {
      final jsonString = prefs.getString(StorageKeys.credits);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => CreditNote.fromJson(json)).toList();
    } catch (e) {
      print('Error loading credit notes: $e');
      return [];
    }
  }

  // Save Language Preference
  static Future<bool> saveLanguage(String locale) async {
    try {
      return await prefs.setString(StorageKeys.language, locale);
    } catch (e) {
      print('Error saving language: $e');
      return false;
    }
  }

  // Load Language Preference
  static String loadLanguage() {
    try {
      return prefs.getString(StorageKeys.language) ?? 'ta'; // Default to Tamil
    } catch (e) {
      print('Error loading language: $e');
      return 'ta';
    }
  }

  // Clear all data
  static Future<bool> clearAll() async {
    try {
      return await prefs.clear();
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
}
