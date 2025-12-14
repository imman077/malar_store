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
    final categories = StorageService.getAllCategories();
    
    // Sort categories: Other/மற்றவை always last, rest alphabetically
    categories.sort((a, b) {
      final aIsOther = a.nameEn == 'Other' || a.nameTa == 'மற்றவை';
      final bIsOther = b.nameEn == 'Other' || b.nameTa == 'மற்றவை';
      
      if (aIsOther && !bIsOther) return 1; // a (Other) comes after b
      if (!aIsOther && bIsOther) return -1; // b (Other) comes after a
      
      // Both are not Other, sort alphabetically by English name
      return a.nameEn.compareTo(b.nameEn);
    });
    
    state = categories;
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
