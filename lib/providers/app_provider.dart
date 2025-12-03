import 'package:flutter_riverpod/flutter_riverpod.dart';

// Navigation Provider
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setIndex(int index) {
    state = index;
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});

// Product Filter Provider
class ProductFilterNotifier extends StateNotifier<String> {
  ProductFilterNotifier() : super('all');

  void setFilter(String filter) {
    state = filter;
  }
}

final productFilterProvider = StateNotifierProvider<ProductFilterNotifier, String>((ref) {
  return ProductFilterNotifier();
});
