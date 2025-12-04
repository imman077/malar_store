import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/store_provider.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/app_router.dart';
import '../widgets/stats_card.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card.dart';
import 'product_form_screen.dart';
import '../providers/app_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final products = ref.watch(productsProvider);
    final expiredCount = ref.watch(expiredProductsCountProvider);
    final expiringSoonCount = ref.watch(expiringSoonProductsCountProvider);
    final freshCount = ref.watch(freshProductsCountProvider);
    
    String t(String key) => TranslationService.translate(key, locale);

    final recentProducts = products.take(5).toList();
    final hasAlerts = expiredCount > 0 || expiringSoonCount > 0;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(storeProvider.notifier).refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Banner
            if (hasAlerts)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: expiredCount > 0 ? AppColors.red : AppColors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      color: AppColors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        expiredCount > 0
                            ? t('alertExpired')
                            : t('alertExpiringSoon'),
                        style: GoogleFonts.hindMadurai(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to items screen with filter
                        ref.read(productFilterProvider.notifier).setFilter(
                          expiredCount > 0 ? 'expired' : 'expiringSoon'
                        );
                        ref.read(navigationProvider.notifier).setIndex(1);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        t('review'),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: t('expiredItems'),
                    count: expiredCount.toString(),
                    icon: LucideIcons.xCircle,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: t('freshStock'),
                    count: freshCount.toString(),
                    icon: LucideIcons.checkCircle,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatsCard(
              title: t('expiringSoonItems'),
              count: expiringSoonCount.toString(),
              icon: LucideIcons.clock,
              color: AppColors.orange,
              isFullWidth: true,
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              t('quickActions'),
              style: GoogleFonts.hindMadurai(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionButton(
                    context,
                    icon: LucideIcons.plus,
                    label: t('addProduct'),
                    color: AppColors.primary,
                    onTap: () {
                      AppRouter.navigateToAddProduct(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  // _buildQuickActionButton(
                  //   context,
                  //   icon: LucideIcons.scan,
                  //   label: t('scan'),
                  //   color: AppColors.orange,
                  //   onTap: () {
                  //     // Scan functionality
                  //   },
                  // ),
                  const SizedBox(width: 12),
                  _buildQuickActionButton(
                    context,
                    icon: LucideIcons.users,
                    label: t('credits'),
                    color: AppColors.red,
                    onTap: () {
                      ref.read(navigationProvider.notifier).setIndex(3);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('recentItems'),
                  style: GoogleFonts.hindMadurai(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                if (products.length > 5)
                  TextButton(
                    onPressed: () {
                      // Navigate to all items
                      ref.read(productFilterProvider.notifier).setFilter('all');
                      ref.read(navigationProvider.notifier).setIndex(1);
                    },
                    child: Text(
                      t('all'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentProducts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    t('noItems'),
                    style: TextStyle(
                      color: AppColors.gray,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...recentProducts.map((product) => ProductCard(
                    product: product,
                    locale: locale,
                    onEdit: () {
                      AppRouter.navigateToEditProduct(context, product);
                    },
                    onDelete: () {
                      _showDeleteDialog(context, ref, product.id, t);
                    },
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
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
