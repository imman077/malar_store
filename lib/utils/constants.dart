import 'package:flutter/material.dart';

// App Colors
class AppColors {
  static const Color primary = Color(0xFF059669); // Emerald Green
  static const Color background = Color(0xFFF9FAFB); // Light Gray
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color red = Color(0xFFDC2626);
  static const Color orange = Color(0xFFF97316);
  static const Color green = Color(0xFF059669);
  static const Color gray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFE5E7EB);
}

// Storage Keys
class StorageKeys {
  static const String products = 'products';
  static const String credits = 'credits';
  static const String language = 'language';
}

// Product Categories
class ProductCategories {
  static const List<String> categories = [
    'Vegetables',
    'Masala',
    'Other',
  ];
  
  static const List<String> categoriesTamil = [
    'காய்கறிகள்',
    'மசாலா',
    'மற்றவை',
  ];
}

// Date Formats
class DateFormats {
  static const String display = 'dd/MM/yyyy';
  static const String storage = 'yyyy-MM-dd';
}

// Expiry Status
enum ExpiryStatus {
  expired,
  expiringSoon,
  fresh,
}
