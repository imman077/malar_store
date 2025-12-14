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
import '../utils/helpers.dart';
import '../utils/app_router.dart';
import '../models/product.dart';
import '../models/category.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId; // null = All
  String _selectedUnit = 'kg'; // Default

  void _showAddToCartDialog(Product product, String displayName) {
    final locale = ref.read(languageProvider);
    final isPiecesProduct = product.unit == 'pcs';
    String quantityText = '1'; // Local state for dialog
    _selectedUnit = product.unit == 'g' ? 'g' : 'kg'; // Use product's unit as default

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with product image
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          // Product image
                          if (product.imageBase64 != null)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.white,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  Helpers.decodeBase64ToImage(product.imageBase64)!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          if (product.imageBase64 != null) const SizedBox(width: 16),
                          // Product name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.hindMadurai(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPiecesProduct) ...[
                            // PIECES PRODUCT
                            Text(
                              locale == 'ta' ? 'எத்தனை எண்?' : 'How many pieces?',
                              style: GoogleFonts.hindMadurai(
                                color: AppColors.gray,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Counter with +/- buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Minus button
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      final current = double.tryParse(quantityText) ?? 1;
                                      if (current > 1) {
                                        setState(() {
                                          quantityText = (current - 1).toStringAsFixed(0);
                                        });
                                      }
                                    },
                                    icon: const Icon(LucideIcons.minus, size: 18),
                                    color: AppColors.primary,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Quantity display
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller: TextEditingController(text: quantityText)..selection = TextSelection.fromPosition(TextPosition(offset: quantityText.length)),
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                    onChanged: (v) => setState(() => quantityText = v),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Plus button
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      final current = double.tryParse(quantityText) ?? 0;
                                      setState(() {
                                        quantityText = (current + 1).toStringAsFixed(0);
                                      });
                                    },
                                    icon: const Icon(LucideIcons.plus, size: 18),
                                    color: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Quick add buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _quickAddBtn('1', setState, quantityText, (v) => quantityText = v),
                                _quickAddBtn('2', setState, quantityText, (v) => quantityText = v),
                                _quickAddBtn('5', setState, quantityText, (v) => quantityText = v),
                                _quickAddBtn('10', setState, quantityText, (v) => quantityText = v),
                              ],
                            ),
                          ] else ...[
                            // WEIGHT/VOLUME PRODUCT
                            Text(
                              locale == 'ta' ? 'எவ்வளவு வேண்டும்?' : 'How much do you need?',
                              style: GoogleFonts.hindMadurai(
                                color: AppColors.gray,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Quantity input
                            TextField(
                              controller: TextEditingController(text: quantityText)..selection = TextSelection.fromPosition(TextPosition(offset: quantityText.length)),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(color: AppColors.gray.withOpacity(0.3)),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                              ),
                              onChanged: (v) => setState(() => quantityText = v),
                            ),
                            const SizedBox(height: 16),
                            // Unit selector
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _unitToggleButton(
                                      label: locale == 'ta' ? 'கிலோ' : 'Kg',
                                      isSelected: _selectedUnit == 'kg',
                                      onTap: () => setState(() => _selectedUnit = 'kg'),
                                    ),
                                  ),
                                  Expanded(
                                    child: _unitToggleButton(
                                      label: locale == 'ta' ? 'கிராம்' : 'g',
                                      isSelected: _selectedUnit == 'g',
                                      onTap: () => setState(() => _selectedUnit = 'g'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Quick add buttons
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                _quickAddBtn('0.25', setState, quantityText, (v) => quantityText = v),
                                _quickAddBtn('0.5', setState, quantityText, (v) => quantityText = v),
                                _quickAddBtn('1', setState, quantityText, (v) => quantityText = v),
                                _quickAddBtn('2', setState, quantityText, (v) => quantityText = v),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: AppColors.gray.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                locale == 'ta' ? 'ரத்து' : 'Cancel',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                final qty = double.tryParse(quantityText) ?? 0;
                                if (qty > 0) {
                                  final unit = isPiecesProduct ? 'pcs' : _selectedUnit;
                                  ref.read(cartProvider.notifier).addItem(product, qty, unit);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isPiecesProduct 
                                          ? '${qty.toInt()} ${locale == 'ta' ? 'எண் சேர்க்கப்பட்டது!' : 'Pcs added!'}'
                                          : '$qty$unit ${locale == 'ta' ? 'சேர்க்கப்பட்டது!' : 'added!'}',
                                        style: GoogleFonts.hindMadurai(),
                                      ),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                locale == 'ta' ? 'கூடையில் சேர்' : 'Add to Cart',
                                style: GoogleFonts.hindMadurai(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _unitToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.hindMadurai(
                color: isSelected ? Colors.white : AppColors.gray,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAddBtn(String val, StateSetter setState, String currentQuantity, Function(String) onUpdate) {
      return InkWell(
          onTap: () {
              setState(() {
                  onUpdate(val);
              });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(20),
                  color: currentQuantity == val ? AppColors.primary : Colors.transparent,
              ),
              child: Text(
                val, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: currentQuantity == val ? Colors.white : AppColors.primary,
                  fontSize: 12,
                ),
              ),
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(categoryProvider);
    final allProducts = ref.watch(productsProvider);
    final locale = ref.watch(languageProvider);
    final cartItems = ref.watch(cartProvider);
    
    // Sort categories: Other/மற்றவை always last, rest alphabetically
    final categories = List<Category>.from(allCategories);
    categories.sort((a, b) {
      final aIsOther = a.nameEn == 'Other' || a.nameTa == 'மற்றவை';
      final bIsOther = b.nameEn == 'Other' || b.nameTa == 'மற்றவை';
      
      if (aIsOther && !bIsOther) return 1;
      if (!aIsOther && bIsOther) return -1;
      
      return a.nameEn.compareTo(b.nameEn);
    });
    
    if (categories.isEmpty) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.white,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: locale == 'ta' ? 'தேடு' : 'Search',
                  prefixIcon: const Icon(LucideIcons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.lightGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.lightGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
            ),
            
            // Category Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(locale == 'ta' ? 'அனைத்தும்' : 'All', null, locale),
                    const SizedBox(width: 8),
                    ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        locale == 'ta' ? c.nameTa : c.nameEn,
                        c.id,
                        locale,
                      ),
                    )),
                  ],
                ),
              ),
            ),
            
            // Product Grid
            Expanded(
              child: _buildProductGrid(allProducts, _selectedCategoryId, locale),
            ),
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
      );
  }

  Widget _buildFilterChip(String label, String? categoryId, String locale) {
    final isSelected = _selectedCategoryId == categoryId;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategoryId = categoryId;
        });
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.lightGray,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.black,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildProductGrid(List<Product> allProducts, String? categoryId, String locale) {
      // Filter logic
      List<Product> products = allProducts;
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        products = products.where((p) {
          return p.name.toLowerCase().contains(query) ||
                 p.category.toLowerCase().contains(query);
        }).toList();
      }
      
      // Category filter
      if (categoryId != null) {
          // Find category object to get names
          final cat = ref.read(categoryProvider).firstWhere((c) => c.id == categoryId);
          
          final isOther = cat.nameEn == 'Other' || cat.nameTa == 'மற்றவை';

          if (isOther) {
             // Show products that are NOT in standard categories (excluding current "Other")
             // actually we just check if it matches any standard category name, if NOT then it's Other
             products = products.where((p) {
                 final isStandard = ProductCategories.categories.contains(p.category) || 
                                    ProductCategories.categoriesTamil.contains(p.category);
                 
                 // If it is standard but NOT "Other", then it belongs to that specific tab, not here.
                 // "Other" is a standard category string, but if user saved "Other", it goes here.
                 // If user saved "Soap" (custom), isStandard is false, so it goes here.
                 
                 if (p.category == 'Other' || p.category == 'மற்றவை') return true;
                 return !isStandard; 
             }).toList();
          } else {
             products = products.where((p) => p.category == cat.nameEn || p.category == cat.nameTa).toList();
          }
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
