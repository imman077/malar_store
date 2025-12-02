import '../utils/helpers.dart';
import '../utils/constants.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double mrp;
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final String barcode;
  final String expiryDate; // YYYY-MM-DD format
  final String notes;
  final String? imageBase64;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.mrp,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.barcode,
    required this.expiryDate,
    required this.notes,
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
      'mrp': mrp,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'barcode': barcode,
      'expiryDate': expiryDate,
      'notes': notes,
      'imageBase64': imageBase64,
    };
  }

  // Create from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      mrp: (json['mrp'] as num).toDouble(),
      costPrice: (json['costPrice'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      barcode: json['barcode'] as String,
      expiryDate: json['expiryDate'] as String,
      notes: json['notes'] as String,
      imageBase64: json['imageBase64'] as String?,
    );
  }

  // Copy with method for updates
  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? mrp,
    double? costPrice,
    double? sellingPrice,
    int? quantity,
    String? barcode,
    String? expiryDate,
    String? notes,
    String? imageBase64,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      mrp: mrp ?? this.mrp,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      barcode: barcode ?? this.barcode,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}
