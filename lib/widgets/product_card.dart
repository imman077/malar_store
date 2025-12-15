import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/product.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback? onDelete; // Made optional
  final String locale;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    this.onDelete, // Optional parameter
    required this.locale,
  });

  Color _getStatusColor() {
    switch (product.expiryStatus) {
      case ExpiryStatus.expired:
        return AppColors.red;
      case ExpiryStatus.expiringSoon:
        return AppColors.orange;
      case ExpiryStatus.fresh:
        return AppColors.green;
    }
  }

  String _getTranslatedCategory(WidgetRef ref) {
    // Get all dynamic categories
    final allCats = StorageService.getAllCategories(); 
    
    // Try to find if product.category matches any known Category
    for (var cat in allCats) {
      if (cat.nameEn == product.category || cat.nameTa == product.category) {
        return locale == 'ta' ? cat.nameTa : cat.nameEn;
      }
    }
    
    // Fallback: Use the old static map just in case
    final categoryMap = {
      'Vegetables': 'காய்கறிகள்',
      'Masala': 'மசாலா',
      'Other': 'மற்றவை',
      'காய்கறிகள்': 'Vegetables',
      'மசாலா': 'Masala',
      'மற்றவை': 'Other',
    };

    if (categoryMap.containsKey(product.category)) {
      final translated = categoryMap[product.category];
       if (locale == 'ta' && translated != null && translated.contains(RegExp(r'[\u0B80-\u0BFF]'))) {
        return translated;
      } else if (locale == 'en' && translated != null && !translated.contains(RegExp(r'[\u0B80-\u0BFF]'))) {
        return translated;
      }
    }
    
    return product.category;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Uint8List? imageBytes = Helpers.decodeBase64ToImage(product.imageBase64);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.itemSpacing),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.lightGray, width: 1),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    LucideIcons.package,
                    color: AppColors.gray,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.getLocalizedName(locale),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getTranslatedCategory(ref),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      Helpers.formatCurrency(product.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      product.unit == 'pcs' 
                          ? '${product.count} ${locale == 'ta' ? 'எண்' : 'Pcs'}'
                          : '${product.quantity}${product.unit} × ${product.count}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status Dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Action Buttons
          Column(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.edit, size: 20),
                onPressed: onEdit,
                color: AppColors.primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (onDelete != null) ...[
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 20),
                  onPressed: onDelete,
                  color: AppColors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
