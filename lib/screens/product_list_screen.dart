import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_notification.dart';
import '../models/category.dart';
import '../providers/store_provider.dart';
import '../providers/language_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/category_provider.dart';
import '../services/notification_service.dart';
import '../services/translation_service.dart';
import '../services/json_import_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/app_router.dart';
import '../utils/helpers.dart';
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
                // Import JSON Button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.gray,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: IconButton(
                    onPressed: () => _handleJsonImport(context, ref, t),
                    icon: const Icon(LucideIcons.upload, color: AppColors.white),
                    padding: EdgeInsets.zero,
                    tooltip: t('importJson'),
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
              final notificationBody = "${product.getLocalizedName(locale)} ${TranslationService.translate('deletedSuccessfully', locale)}";
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

  Future<void> _handleJsonImport(
    BuildContext context,
    WidgetRef ref,
    String Function(String) t,
  ) async {
    // Pick JSON file
    final jsonContent = await JsonImportService.pickJsonFile();
    
    if (jsonContent == null) {
      return; // User cancelled
    }

    if (!context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(t('importing')),
          ],
        ),
      ),
    );

    // Parse JSON
    final existingIds = ref.read(productsProvider).map((p) => p.id).toList();
    final result = await JsonImportService.parseProductsJson(jsonContent, existingIds);

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog

    // Check results
    if (result.products.isEmpty && result.errors.isEmpty) {
      _showSnackBar(context, t('noProductsFound'), isError: true);
      return;
    }

    if (result.products.isEmpty && result.errors.isNotEmpty) {
      _showImportErrorDialog(context, result.errors, t);
      return;
    }

    // Show preview dialog
    _showImportPreviewDialog(context, ref, result, t);
  }

  void _showImportPreviewDialog(
    BuildContext context,
    WidgetRef ref,
    JsonImportResult result,
    String Function(String) t,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('importPreview')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product count
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.package, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('productCount'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray,
                            ),
                          ),
                          Text(
                            '${result.products.length}',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Skipped count if any
              if (result.skippedCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: AppColors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${result.skippedCount} ${t('productsSkipped')}',
                          style: const TextStyle(color: AppColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Product list preview
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...result.products.take(5).map((product) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(LucideIcons.check, size: 16, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.gray),
                    ),
                  ],
                ),
              )),
              if (result.products.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... +${result.products.length - 5} more',
                    style: const TextStyle(color: AppColors.gray),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Auto-add new categories from imported products
              final existingCategories = StorageService.getAllCategories();
              final existingCategoryNames = existingCategories
                  .map((c) => c.nameEn.toLowerCase())
                  .toSet();
              
              for (final product in result.products) {
                final categoryName = product.category.trim();
                if (categoryName.isNotEmpty && 
                    !existingCategoryNames.contains(categoryName.toLowerCase())) {
                  // Get Tamil name from categoryTaMap, or use English as fallback
                  final tamilName = result.categoryTaMap[categoryName] ?? categoryName;
                  
                  // Add new category
                  final newCategory = Category(
                    id: Helpers.generateId(),
                    nameEn: categoryName,
                    nameTa: tamilName,
                  );
                  await StorageService.addCategory(newCategory);
                  existingCategoryNames.add(categoryName.toLowerCase());
                }
              }
              
              // Refresh category provider
              ref.read(categoryProvider.notifier).loadCategories();
              
              // Import products
              final count = await ref.read(storeProvider.notifier).addProducts(result.products);
              
              if (context.mounted) {
                _showSnackBar(
                  context,
                  '$count ${t('productsImported')}',
                  isError: false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: Text(t('confirmImport')),
          ),
        ],
      ),
    );
  }

  void _showImportErrorDialog(
    BuildContext context,
    List<String> errors,
    String Function(String) t,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: AppColors.red),
            const SizedBox(width: 8),
            Text(t('importError')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.take(10).map((error) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• $error',
                style: const TextStyle(fontSize: 13),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}
