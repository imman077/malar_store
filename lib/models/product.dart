import '../utils/helpers.dart';
import '../utils/constants.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int quantity;
  final String unit; // 'kg' or 'g' or 'Qty'
  final String expiryDate; // YYYY-MM-DD format
  final String? imageBase64;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    this.unit = 'kg', // Default to kg
    required this.expiryDate,
    this.imageBase64,
  });

  // Get expiry status
  ExpiryStatus get expiryStatus => Helpers.getExpiryStatus(expiryDate);

  // Check if product is expired
  bool get isExpired => expiryStatus == ExpiryStatus.expired;

  // Check if product is expiring soon
  bool get isExpiringSoon => expiryStatus == ExpiryStatus.expiringSoon;

  // Check if product is fresh
  bool get isFresh => expiryStatus == ExpiryStatus.fresh;

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate,
      'imageBase64': imageBase64,
    };
  }

  // Create from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      unit: json['unit'] as String? ?? 'kg',
      expiryDate: json['expiryDate'] as String,
      imageBase64: json['imageBase64'] as String?,
    );
  }

  // Copy with method for updates
  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? quantity,
    String? unit,
    String? expiryDate,
    String? imageBase64,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}
