import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/storage_service.dart';

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super([]) {
    loadCategories();
  }

  void loadCategories() {
    state = StorageService.getAllCategories();
  }

  Future<void> addCategory(Category category) async {
    await StorageService.addCategory(category);
    loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await StorageService.updateCategory(category);
    loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await StorageService.deleteCategory(id);
    loadCategories();
  }
}
