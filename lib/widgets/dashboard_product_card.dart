import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/product.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class DashboardProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;
  final String locale;

  const DashboardProductCard({
    super.key,
    required this.product,
    required this.onTap,
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
    final allCats = StorageService.getAllCategories();
    
    for (var cat in allCats) {
      if (cat.nameEn == product.category || cat.nameTa == product.category) {
        return locale == 'ta' ? cat.nameTa : cat.nameEn;
      }
    }
    
    return product.category;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Uint8List? imageBytes = Helpers.decodeBase64ToImage(product.imageBase64);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.smallSpacing),
        padding: const EdgeInsets.all(AppSpacing.smallSpacing),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.lightGray, width: 1),
        ),
        child: Row(
          children: [
            // Product Image - Smaller
            Container(
              width: 50,
              height: 50,
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
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            // Product Details - Compact
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.getLocalizedName(locale),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        Helpers.formatCurrency(product.price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product.unit == 'pcs' 
                              ? '${product.count} ${locale == 'ta' ? 'எண்' : 'Pcs'}'
                              : '${product.quantity}${product.unit}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status Dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Arrow Icon
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.gray,
            ),
          ],
        ),
      ),
    );
  }
}
