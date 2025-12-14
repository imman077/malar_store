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
  static const String notifications = 'app_notifications';
  static const String categories = 'categories';
}

// Product Categories
class ProductCategories {
  static const List<String> categories = [
    'Fruits',
    'Vegetables',
    'Masala',
    'Biscuits',
    'Other',
  ];
  
  static const List<String> categoriesTamil = [
    'பழங்கள்',
    'காய்கறிகள்',
    'மசாலா',
    'பிஸ்கட்',
    'மற்றவை',
  ];
}

// Date Formats
class DateFormats {
  static const String display = 'dd/MM/yyyy';
  static const String storage = 'yyyy-MM-dd';
}

// App Spacing - Standardized padding/margin
class AppSpacing {
  static const double screenPadding = 16.0; // Standard screen padding
  static const double cardPadding = 12.0; // Padding inside cards
  static const double sectionSpacing = 16.0; // Space between sections
  static const double itemSpacing = 12.0; // Space between items
  static const double smallSpacing = 8.0; // Small gaps
}

// App Border Radius - Professional, subtle rounding
class AppRadius {
  static const double card = 8.0; // Cards
  static const double dialog = 12.0; // Dialogs/Modals
  static const double button = 8.0; // Buttons
  static const double input = 8.0; // Input fields
  static const double chip = 20.0; // Filter chips/pills
}

// Expiry Status
enum ExpiryStatus {
  expired,
  expiringSoon,
  fresh,
}
