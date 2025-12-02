import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../utils/helpers.dart';

class ProductFormState {
  final String? id;
  final String name;
  final String category;
  final String mrp;
  final String costPrice;
  final String sellingPrice;
  final String quantity;
  final String barcode;
  final DateTime? expiryDate;
  final String notes;
  final String? imageBase64;

  ProductFormState({
    this.id,
    this.name = '',
    this.category = '',
    this.mrp = '',
    this.costPrice = '',
    this.sellingPrice = '',
    this.quantity = '',
    this.barcode = '',
    this.expiryDate,
    this.notes = '',
    this.imageBase64,
  });

  ProductFormState copyWith({
    String? id,
    String? name,
    String? category,
    String? mrp,
    String? costPrice,
    String? sellingPrice,
    String? quantity,
    String? barcode,
    DateTime? expiryDate,
    String? notes,
    String? imageBase64,
  }) {
    return ProductFormState(
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

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier() : super(ProductFormState());

  void setProduct(Product? product) {
    if (product != null) {
      state = ProductFormState(
        id: product.id,
        name: product.name,
        category: product.category,
        mrp: product.mrp.toString(),
        costPrice: product.costPrice.toString(),
        sellingPrice: product.sellingPrice.toString(),
        quantity: product.quantity.toString(),
        barcode: product.barcode,
        expiryDate: Helpers.parseDate(product.expiryDate),
        notes: product.notes,
        imageBase64: product.imageBase64,
      );
    } else {
      reset();
    }
  }

  void updateName(String value) => state = state.copyWith(name: value);
  void updateCategory(String? value) => state = state.copyWith(category: value ?? '');
  void updateMrp(String value) => state = state.copyWith(mrp: value);
  void updateCostPrice(String value) => state = state.copyWith(costPrice: value);
  void updateSellingPrice(String value) => state = state.copyWith(sellingPrice: value);
  void updateQuantity(String value) => state = state.copyWith(quantity: value);
  void updateBarcode(String value) => state = state.copyWith(barcode: value);
  void updateExpiryDate(DateTime? value) => state = state.copyWith(expiryDate: value);
  void updateNotes(String value) => state = state.copyWith(notes: value);
  void updateImage(String? value) => state = state.copyWith(imageBase64: value);

  void reset() {
    state = ProductFormState(
      expiryDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  Product? getProduct() {
    if (state.category.isEmpty) return null;
    if (state.expiryDate == null) return null;

    return Product(
      id: state.id ?? Helpers.generateId(),
      name: state.name,
      category: state.category,
      mrp: double.tryParse(state.mrp) ?? 0.0,
      costPrice: double.tryParse(state.costPrice) ?? 0.0,
      sellingPrice: double.tryParse(state.sellingPrice) ?? 0.0,
      quantity: int.tryParse(state.quantity) ?? 0,
      barcode: state.barcode,
      expiryDate: Helpers.formatDateForStorage(state.expiryDate!),
      notes: state.notes,
      imageBase64: state.imageBase64,
    );
  }
}

final productFormProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>((ref) {
  return ProductFormNotifier();
});
