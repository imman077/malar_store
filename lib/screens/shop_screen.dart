import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/store_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/category_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/shop_product_card.dart';
import '../utils/constants.dart';
import '../utils/app_router.dart';
import '../models/product.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _quantityController = TextEditingController();
  String _selectedUnit = 'kg'; // Default

  @override
  void dispose() {
    _quantityController.dispose();
    try {
        _tabController.dispose();
    } catch(e) {
        // absorb
    }
    super.dispose();
  }

  void _showAddToCartDialog(Product product, String displayName) {
    _quantityController.text = '1';
    _selectedUnit = 'kg'; // Reset to default or based on product type
    // If product unit is 'Qty' or not standard, handle that
    // But for simplicity, start with kg/g logic

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(displayName, style: GoogleFonts.hindMadurai(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Quantity Input
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Unit Selector
                      ToggleButtons(
                        isSelected: [_selectedUnit == 'kg', _selectedUnit == 'g'],
                        onPressed: (index) {
                          setState(() {
                            _selectedUnit = index == 0 ? 'kg' : 'g';
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        children: const [
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('kg')),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('g')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick add buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                        _quickAddBtn('0.25', setState),
                        _quickAddBtn('0.5', setState),
                        _quickAddBtn('1', setState),
                        _quickAddBtn('2', setState),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(_quantityController.text) ?? 0;
                    if (qty > 0) {
                      ref.read(cartProvider.notifier).addItem(product, qty, _selectedUnit);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${qty}${_selectedUnit} added!'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _quickAddBtn(String val, StateSetter setState) {
      return InkWell(
          onTap: () {
              setState(() {
                  _quantityController.text = val;
              });
          },
          child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
              ),
              child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final allProducts = ref.watch(productsProvider);
    final locale = ref.watch(languageProvider);
    final cartItems = ref.watch(cartProvider);
    
    // Sort categories or ensure 'Other' is last logic? 
    // Usually sorted by ID or creation, let's trust provider order.
    
    // Create Default Tab Controller if needed, but we need dynamic length.
    // So we use DefaultTabController widget wrapping Scaffold.
    
    if (categories.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: categories.length + 1, // +1 for "All" tab? Or just categories. Let's do All + Categories
      child: Scaffold(
        appBar: AppBar(
          title: Text('Shop', style: GoogleFonts.hindMadurai(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              const Tab(text: 'All'), // General tab
              ...categories.map((c) => Tab(text: locale == 'ta' ? c.nameTa : c.nameEn)),
            ],
          ),
          actions: [
             // Search logic could go here or floating search bar
          ],
        ),
        body: TabBarView(
          children: [
            // All Products Tab
            _buildProductGrid(allProducts, null, locale),
            
            // Category Tabs
            ...categories.map((c) {
                // Filter products that match this category
                // Matching logic: product.category == nameEn OR nameTa
                return _buildProductGrid(allProducts, c.id, locale); 
                // Wait, product stores Name string. So match NameEn/NameTa.
            }),
          ],
        ),
        floatingActionButton: cartItems.isNotEmpty ? FloatingActionButton.extended(
            onPressed: () {
                AppRouter.navigateToCart(context);
            }, 
            icon: const Icon(LucideIcons.shoppingBag),
            label: Text('${cartItems.length} Items | ₹${ref.read(cartProvider.notifier).totalAmount.toStringAsFixed(0)}'),
            backgroundColor: AppColors.primary,
        ) : null,
      ),
    );
  }

  Widget _buildProductGrid(List<Product> allProducts, String? categoryId, String locale) {
      // Filter logic
      List<Product> products = allProducts;
      if (categoryId != null) {
          // Find category object to get names
          final cat = ref.read(categoryProvider).firstWhere((c) => c.id == categoryId);
          products = allProducts.where((p) => p.category == cat.nameEn || p.category == cat.nameTa).toList();
      }
      
      if (products.isEmpty) {
          return Center(child: Text(locale == 'ta' ? 'பொருட்கள் இல்லை' : 'No items found'));
      }

      return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Taller cards
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
              final product = products[index];
              
              // Resolve display name for visual card (use static helper or new logic)
              // For simplicity, we assume we want translated category but Product Name is user entry (usually English/Tamil mix).
              // Let's just use Product Name.
              
              return ShopProductCard(
                  product: product,
                  displayName: product.name,
                  onTap: () => _showAddToCartDialog(product, product.name),
              );
          },
      );
  }
}
