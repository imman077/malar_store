import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../utils/helpers.dart';

class JsonImportResult {
  final List<Product> products;
  final List<String> errors;
  final int skippedCount;
  final Map<String, String> categoryTaMap; // Map of category (EN) to Tamil name

  JsonImportResult({
    required this.products,
    required this.errors,
    required this.skippedCount,
    this.categoryTaMap = const {},
  });
}

class JsonImportService {
  /// Pick a JSON file from device storage
  static Future<String?> pickJsonFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // Important for web support
      );

      if (result != null && result.files.single.bytes != null) {
        // Use bytes for both web and mobile compatibility
        return utf8.decode(result.files.single.bytes!);
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// Parse and validate JSON content
  static Future<JsonImportResult> parseProductsJson(
    String jsonContent, 
    List<String> existingProductIds,
  ) async {
    final List<Product> products = [];
    final List<String> errors = [];
    final Map<String, String> categoryTaMap = {};
    int skippedCount = 0;

    try {
      final Map<String, dynamic> data = json.decode(jsonContent);

      if (!data.containsKey('products')) {
        errors.add('Invalid JSON format: missing "products" array');
        return JsonImportResult(
          products: [], 
          errors: errors, 
          skippedCount: 0,
        );
      }

      final List<dynamic> productsList = data['products'];

      for (int i = 0; i < productsList.length; i++) {
        final productData = productsList[i];
        
        try {
          // Validate required fields
          final validationError = _validateProductData(productData, i);
          if (validationError != null) {
            errors.add(validationError);
            skippedCount++;
            continue;
          }

          // Check for duplicate ID
          final String id = productData['id'] ?? Helpers.generateId();
          if (existingProductIds.contains(id)) {
            errors.add('Product ${i + 1}: ID "$id" already exists, skipped');
            skippedCount++;
            continue;
          }

          // Extract categoryTa if provided
          final String category = productData['category'];
          final String? categoryTa = productData['categoryTa'];
          if (categoryTa != null && categoryTa.isNotEmpty) {
            categoryTaMap[category] = categoryTa;
          }

          // Download image if URL provided
          String? imageBase64;
          if (productData['imageUrl'] != null && 
              productData['imageUrl'].toString().isNotEmpty) {
            imageBase64 = await _downloadImageAsBase64(
              productData['imageUrl'],
            );
          }

          // Create product with Tamil name if provided
          final String? nameTa = productData['nameTa'];
          
          final product = Product(
            id: id,
            name: productData['name'],
            nameTa: nameTa,
            category: category,
            price: (productData['price'] as num).toDouble(),
            quantity: productData['quantity'] as int,
            unit: productData['unit'] ?? 'kg',
            count: productData['count'] ?? 1,
            expiryDate: productData['expiryDate'],
            imageBase64: imageBase64,
          );

          products.add(product);
        } catch (e) {
          errors.add('Product ${i + 1}: ${e.toString()}');
          skippedCount++;
        }
      }
    } catch (e) {
      errors.add('Failed to parse JSON: ${e.toString()}');
    }

    return JsonImportResult(
      products: products,
      errors: errors,
      skippedCount: skippedCount,
      categoryTaMap: categoryTaMap,
    );
  }

  /// Validate product data
  static String? _validateProductData(Map<String, dynamic> data, int index) {
    final requiredFields = ['name', 'category', 'price', 'quantity', 'expiryDate'];
    
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        return 'Product ${index + 1}: Missing required field "$field"';
      }
    }

    // Validate price is a number
    if (data['price'] is! num) {
      return 'Product ${index + 1}: "price" must be a number';
    }

    // Validate quantity is an integer
    if (data['quantity'] is! int) {
      return 'Product ${index + 1}: "quantity" must be an integer';
    }

    // Validate date format (YYYY-MM-DD)
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(data['expiryDate'])) {
      return 'Product ${index + 1}: "expiryDate" must be in YYYY-MM-DD format';
    }

    return null;
  }

  /// Download image from URL and convert to base64
  static Future<String?> _downloadImageAsBase64(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        return base64Encode(bytes);
      }
      return null;
    } catch (e) {
      // Silently fail - product will be imported without image
      return null;
    }
  }
}
