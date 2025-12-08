import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/credit_note.dart';
import '../models/app_notification.dart';
import '../utils/constants.dart';

class StorageService {
  static late Box _box;
  static const _secureStorage = FlutterSecureStorage();

  // Initialize Hive and Secure Storage
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('malar_store_box');
  }

  // --- Secure Storage Methods ---

  static Future<void> writeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> readSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  // --- Hive Storage Methods (replacing SharedPreferences) ---

  // Save Products
  static Future<bool> saveProducts(List<Product> products) async {
    try {
      final jsonList = products.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _box.put(StorageKeys.products, jsonString);
      return true;
    } catch (e) {
      print('Error saving products: $e');
      return false;
    }
  }

  // Load Products
  static Future<List<Product>> loadProducts() async {
    try {
      final jsonString = _box.get(StorageKeys.products);
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
      await _box.put(StorageKeys.credits, jsonString);
      return true;
    } catch (e) {
      print('Error saving credit notes: $e');
      return false;
    }
  }

  // Load Credit Notes
  static Future<List<CreditNote>> loadCreditNotes() async {
    try {
      final jsonString = _box.get(StorageKeys.credits);
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
      await _box.put(StorageKeys.language, locale);
      return true;
    } catch (e) {
      print('Error saving language: $e');
      return false;
    }
  }

  // Load Language Preference
  static String loadLanguage() {
    try {
      return _box.get(StorageKeys.language, defaultValue: 'ta') as String;
    } catch (e) {
      print('Error loading language: $e');
      return 'ta';
    }
  }

  // Save Notifications
  static Future<bool> saveNotifications(List<AppNotification> notifications) async {
    try {
      final jsonList = notifications.map((n) => n.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _box.put(StorageKeys.notifications, jsonString);
      return true;
    } catch (e) {
      print('Error saving notifications: $e');
      return false;
    }
  }

  // Load Notifications
  static Future<List<AppNotification>> loadNotifications() async {
    try {
      final jsonString = _box.get(StorageKeys.notifications);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      print('Error loading notifications: $e');
      return [];
    }
  }

  // Clear all data (Note: Clears Hive box, optional to clear secure storage too)
  static Future<bool> clearAll() async {
    try {
      await _box.clear();
      // await _secureStorage.deleteAll(); // Uncomment if you want to clear secure data too
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
}
