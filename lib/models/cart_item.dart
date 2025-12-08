import '../models/product.dart';

class CartItem {
  final Product product;
  final double quantity; // e.g. 1.5
  final String unit; // 'kg', 'g', 'qty'
  final double totalPrice;

  CartItem({
    required this.product,
    required this.quantity,
    required this.unit,
    required this.totalPrice,
  });

  CartItem copyWith({
    Product? product,
    double? quantity,
    String? unit,
    double? totalPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
