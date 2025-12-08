import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product, double quantity, String unit) {
    // Calculate price logic
    // If unit is kg: price = product.price * quantity
    // If unit is g: price = product.price * (quantity / 1000)
    // If unit is qty: price = product.price * quantity (assuming product price is per item if standard unit is Qty/count)
    
    // Check product base unit
    double price = 0.0;
    
    // Simple logic:
    // If user selected 'g', convert to kg for price calc if base is kg
    // If user selected 'kg', use as is
    
    // We assume product.price is per 'kg' (default) or 'qty' (if implicit)
    // If Store unit is 'kg':
    if (unit == 'kg') {
       price = product.price * quantity;
    } else if (unit == 'g') {
       price = product.price * (quantity / 1000.0);
    } else {
       // 'qty' or count, assuming price is per piece
       price = product.price * quantity;
    }

    // Check if item already exists (same product AND same unit?)
    // Actually, usually we merge if same unit, or just list as separate?
    // Let's assume merging if same product ID
    
    final existingIndex = state.indexWhere((item) => item.product.id == product.id && item.unit == unit);
    
    if (existingIndex != -1) {
      // Update existing
      final existingItem = state[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      final newPrice = existingItem.totalPrice + price;
      
      final updatedItem = existingItem.copyWith(
        quantity: newQuantity,
        totalPrice: newPrice,
      );
      
      state = [
        ...state.sublist(0, existingIndex),
        updatedItem,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // Add new
      final newItem = CartItem(
        product: product,
        quantity: quantity,
        unit: unit,
        totalPrice: price,
      );
      state = [...state, newItem];
    }
  }

  void removeItem(CartItem item) {
    state = state.where((i) => i != item).toList();
  }

  void clearCaer() {
    state = [];
  }
  
  double get totalAmount {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
}
