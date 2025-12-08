import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String locale;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
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

  String _getTranslatedCategory() {
    // Category mapping between English and Tamil
    final categoryMap = {
      // English to Tamil
      'Vegetables': 'காய்கறிகள்',
      'Masala': 'மசாலா',
      'Other': 'மற்றவை',
      // Tamil to English
      'காய்கறிகள்': 'Vegetables',
      'மசாலா': 'Masala',
      'மற்றவை': 'Other',
    };

    // If it's a predefined category, translate it
    if (categoryMap.containsKey(product.category)) {
      final translatedCategory = categoryMap[product.category];
      // Return translated version if locale matches, otherwise return as-is
      if (locale == 'ta' && translatedCategory != null && translatedCategory.contains(RegExp(r'[\u0B80-\u0BFF]'))) {
        return translatedCategory;
      } else if (locale == 'en' && translatedCategory != null && !translatedCategory.contains(RegExp(r'[\u0B80-\u0BFF]'))) {
        return translatedCategory;
      }
    }
    
    // For custom categories or if already in correct language, return as-is
    return product.category;
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? imageBytes = Helpers.decodeBase64ToImage(product.imageBase64);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
                  product.name,
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
                  _getTranslatedCategory(),
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
                      '${locale == 'ta' ? 'சரக்கு' : 'Stock'}: ${product.quantity}',
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
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 20),
                onPressed: onDelete,
                color: AppColors.red,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
