import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class ProductFormState {
  final String? id;
  final String name;
  final String category;
  final String customCategory;
  final String price;
  final String quantity;
  final String unit;
  final DateTime? expiryDate;
  final String? imageBase64;

  ProductFormState({
    this.id,
    this.name = '',
    this.category = '',
    this.customCategory = '',
    this.price = '',
    this.quantity = '',
    this.unit = 'kg',
    this.expiryDate,
    this.imageBase64,
  });

  ProductFormState copyWith({
    String? id,
    String? name,
    String? category,
    String? customCategory,
    String? price,
    String? quantity,
    String? unit,
    DateTime? expiryDate,
    String? imageBase64,
  }) {
    return ProductFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier() : super(ProductFormState());

  void setProduct(Product? product) {
    if (product != null) {
      // Check if the category is a standard one
      final isStandard = ProductCategories.categories.contains(product.category) || 
                         ProductCategories.categoriesTamil.contains(product.category);
      
      final category = isStandard ? product.category : 'Other';
      final customCategory = isStandard ? '' : product.category;

      state = ProductFormState(
        id: product.id,
        name: product.name,
        category: category,
        customCategory: customCategory,
        price: product.price.toString(),
        quantity: product.quantity.toString(),
        unit: product.unit,
        expiryDate: Helpers.parseDate(product.expiryDate),
        imageBase64: product.imageBase64,
      );
    } else {
      reset();
    }
  }

  void updateName(String value) => state = state.copyWith(name: value);
  void updateCategory(String? value) => state = state.copyWith(category: value ?? '');
  void updateCustomCategory(String value) => state = state.copyWith(customCategory: value);
  void updatePrice(String value) => state = state.copyWith(price: value);
  void updateQuantity(String value) => state = state.copyWith(quantity: value);
  void updateUnit(String value) => state = state.copyWith(unit: value);
  void updateExpiryDate(DateTime? value) => state = state.copyWith(expiryDate: value);
  void updateImage(String? value) => state = state.copyWith(imageBase64: value);

  void reset() {
    state = ProductFormState(
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      unit: 'kg',
    );
  }

  Product? getProduct() {
    if (state.category.isEmpty) return null;
    if (state.expiryDate == null) return null;

    // Use custom category if "Other" is selected
    final finalCategory = state.category == 'Other' || state.category == 'மற்றவை'
        ? state.customCategory.isNotEmpty ? state.customCategory : state.category
        : state.category;

    return Product(
      id: state.id ?? Helpers.generateId(),
      name: state.name,
      category: finalCategory,
      price: double.tryParse(state.price) ?? 0.0,
      quantity: int.tryParse(state.quantity) ?? 0,
      unit: state.unit,
      expiryDate: Helpers.formatDateForStorage(state.expiryDate!),
      imageBase64: state.imageBase64,
    );
  }
}

final productFormProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>((ref) {
  return ProductFormNotifier();
});
