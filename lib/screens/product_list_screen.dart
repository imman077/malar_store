import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_notification.dart';
import '../providers/store_provider.dart';
import '../providers/language_provider.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';
import '../utils/app_router.dart';
import '../utils/helpers.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card.dart';
import 'product_form_screen.dart';
import '../providers/app_provider.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final allProducts = ref.watch(productsProvider);
    final filterStatus = ref.watch(productFilterProvider);
    
    String t(String key) => TranslationService.translate(key, locale);

    // Filter products
    var filteredProducts = allProducts.where((product) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!product.name.toLowerCase().contains(query) &&
            !product.category.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Status filter
      if (filterStatus == 'expired' && !product.isExpired) return false;
      if (filterStatus == 'expiringSoon' && !product.isExpiringSoon) return false;
      if (filterStatus == 'fresh' && !product.isFresh) return false;

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Search Bar with Add Button
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: t('search'),
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: BorderSide(color: AppColors.lightGray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: BorderSide(color: AppColors.lightGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Add Product Button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: IconButton(
                    onPressed: () => AppRouter.navigateToAddProduct(context),
                    icon: const Icon(LucideIcons.plus, color: AppColors.white),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(t('all'), 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip(t('expired'), 'expired'),
                  const SizedBox(width: 8),
                  _buildFilterChip(t('expiringSoon'), 'expiringSoon'),
                  const SizedBox(width: 8),
                  _buildFilterChip(t('fresh'), 'fresh'),
                ],
              ),
            ),
          ),

          // Product List
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      t('noItems'),
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: 14,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(storeProvider.notifier).refresh();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return ProductCard(
                          product: product,
                          locale: locale,
                          onEdit: () {
                            AppRouter.navigateToEditProduct(context, product);
                          },
                          onDelete: () {
                            _showDeleteDialog(context, product.id, t);
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final currentFilter = ref.watch(productFilterProvider);
    final isSelected = currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(productFilterProvider.notifier).setFilter(value);
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.lightGray,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.black,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String productId,
    String Function(String) t,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete')),
        content: Text(t('deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () {
              final product = ref.read(productsProvider).firstWhere((p) => p.id == productId);
              
              // Mobile notification
              final locale = ref.read(languageProvider);
              final notificationTitle = TranslationService.translate('productDeleted', locale);
              final notificationBody = "${product.name} deleted successfully";
              NotificationService.showNotification(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: notificationTitle,
                body: notificationBody,
              );
              
              // Add to notification history
              ref.read(notificationProvider.notifier).addNotification(
                AppNotification(
                  id: Helpers.generateId(),
                  title: notificationTitle,
                  body: notificationBody,
                  timestamp: DateTime.now(),
                  type: 'product_delete',
                ),
              );
              
              ref.read(storeProvider.notifier).deleteProduct(productId);
              Navigator.pop(context);
            },
            child: Text(
              t('delete'),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}
