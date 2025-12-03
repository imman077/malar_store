import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/credit_note.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

// Store State
class StoreState {
  final List<Product> products;
  final List<CreditNote> creditNotes;
  final bool isLoading;

  StoreState({
    required this.products,
    required this.creditNotes,
    this.isLoading = false,
  });

  StoreState copyWith({
    List<Product>? products,
    List<CreditNote>? creditNotes,
    bool? isLoading,
  }) {
    return StoreState(
      products: products ?? this.products,
      creditNotes: creditNotes ?? this.creditNotes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Store Notifier
class StoreNotifier extends StateNotifier<StoreState> {
  StoreNotifier()
      : super(StoreState(
          products: [],
          creditNotes: [],
          isLoading: true,
        )) {
    _loadData();
  }

  // Load data from storage
  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    final products = await StorageService.loadProducts();
    final credits = await StorageService.loadCreditNotes();
    state = StoreState(
      products: products,
      creditNotes: credits,
      isLoading: false,
    );
  }

  // Product Methods
  Future<void> addProduct(Product product) async {
    final updatedProducts = [...state.products, product];
    state = state.copyWith(products: updatedProducts);
    await StorageService.saveProducts(updatedProducts);

    // Trigger immediate notification based on product status
    if (product.isExpired) {
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Expired',
        body: '${product.name} is expired!',
      );
    } else if (product.isExpiringSoon) {
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Expiring Soon',
        body: '${product.name} is expiring soon!',
      );
      
      // Schedule daily reminder at 9 AM for expiring products
      await NotificationService.scheduleDailyExpiringProductNotification(
        id: product.id.hashCode,
        productName: product.name,
        hour: 9, // 9 AM
      );
    } else {
      // Fresh item - just notify it was added
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Item Added',
        body: '${product.name} is added successfully.',
      );
    }
  }

  Future<void> updateProduct(Product product) async {
    final updatedProducts = state.products.map((p) {
      return p.id == product.id ? product : p;
    }).toList();
    state = state.copyWith(products: updatedProducts);
    await StorageService.saveProducts(updatedProducts);
  }

  Future<void> deleteProduct(String productId) async {
    final updatedProducts = state.products.where((p) => p.id != productId).toList();
    state = state.copyWith(products: updatedProducts);
    await StorageService.saveProducts(updatedProducts);
  }

  // Credit Note Methods
  Future<void> addCredit(CreditNote credit) async {
    final updatedCredits = [...state.creditNotes, credit];
    state = state.copyWith(creditNotes: updatedCredits);
    await StorageService.saveCreditNotes(updatedCredits);

    // Trigger immediate notification
    await NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Credit Added',
      body: '${credit.customerName} is pending ₹${credit.pendingAmount.toStringAsFixed(2)}.',
    );

    // Schedule 12-hour recurring reminder if credit is not paid
    if (!credit.isPaid && credit.pendingAmount > 0) {
      await NotificationService.schedule12HourCreditReminder(
        id: credit.id.hashCode,
        customerName: credit.customerName,
        pendingAmount: credit.pendingAmount,
      );
    }
  }

  Future<void> updateCredit(CreditNote credit) async {
    final updatedCredits = state.creditNotes.map((c) {
      return c.id == credit.id ? credit : c;
    }).toList();
    state = state.copyWith(creditNotes: updatedCredits);
    await StorageService.saveCreditNotes(updatedCredits);
  }

  Future<void> deleteCredit(String creditId) async {
    final updatedCredits = state.creditNotes.where((c) => c.id != creditId).toList();
    state = state.copyWith(creditNotes: updatedCredits);
    await StorageService.saveCreditNotes(updatedCredits);
  }

  // Mark credit as paid
  Future<void> markCreditAsPaid(String creditId) async {
    final credit = state.creditNotes.firstWhere((c) => c.id == creditId);
    final updatedCredit = credit.copyWith(
      isPaid: true,
      amountPaid: credit.totalAmount,
    );
    await updateCredit(updatedCredit);
    
    // Cancel the recurring reminder
    await NotificationService.cancelNotification(credit.id.hashCode);
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadData();
  }
}

// Store Provider
final storeProvider = StateNotifierProvider<StoreNotifier, StoreState>((ref) {
  return StoreNotifier();
});

// Derived Providers for easy access
final productsProvider = Provider<List<Product>>((ref) {
  return ref.watch(storeProvider).products;
});

final creditNotesProvider = Provider<List<CreditNote>>((ref) {
  return ref.watch(storeProvider).creditNotes;
});

// Expired products count
final expiredProductsCountProvider = Provider<int>((ref) {
  final products = ref.watch(productsProvider);
  return products.where((p) => p.isExpired).length;
});

// Expiring soon products count
final expiringSoonProductsCountProvider = Provider<int>((ref) {
  final products = ref.watch(productsProvider);
  return products.where((p) => p.isExpiringSoon).length;
});

// Fresh products count
final freshProductsCountProvider = Provider<int>((ref) {
  final products = ref.watch(productsProvider);
  return products.where((p) => p.isFresh).length;
});

// Pending credits count
final pendingCreditsCountProvider = Provider<int>((ref) {
  final credits = ref.watch(creditNotesProvider);
  return credits.where((c) => !c.isPaid).length;
});
