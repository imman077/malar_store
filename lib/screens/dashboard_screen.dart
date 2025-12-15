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
import '../utils/helpers.dart';
import '../utils/app_router.dart';
import '../widgets/stats_card.dart';
import '../widgets/dashboard_product_card.dart';
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
            // Greeting Section
            _buildGreetingSection(context, t),
            const SizedBox(height: 16),
            
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

            // Stats Cards - 3 in a row
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: t('expiredItems'),
                    count: expiredCount.toString(),
                    icon: LucideIcons.xCircle,
                    color: AppColors.red,
                    onTap: () {
                      ref.read(productFilterProvider.notifier).setFilter('expired');
                      ref.read(navigationProvider.notifier).setIndex(1);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatsCard(
                    title: t('freshStock'),
                    count: freshCount.toString(),
                    icon: LucideIcons.checkCircle,
                    color: AppColors.green,
                    onTap: () {
                      ref.read(productFilterProvider.notifier).setFilter('fresh');
                      ref.read(navigationProvider.notifier).setIndex(1);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatsCard(
                    title: t('expiringSoonItems'),
                    count: expiringSoonCount.toString(),
                    icon: LucideIcons.clock,
                    color: AppColors.orange,
                    onTap: () {
                      ref.read(productFilterProvider.notifier).setFilter('expiringSoon');
                      ref.read(navigationProvider.notifier).setIndex(1);
                    },
                  ),
                ),
              ],
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
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: LucideIcons.plus,
                    label: t('addProduct'),
                    color: AppColors.primary,
                    onTap: () {
                      AppRouter.navigateToAddProduct(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: LucideIcons.users,
                    label: t('credits'),
                    color: AppColors.red,
                    onTap: () {
                      ref.read(navigationProvider.notifier).setIndex(3);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: LucideIcons.calculator,
                    label: t('weightLiquidCalculator'),
                    color: AppColors.orange,
                    onTap: () {
                      AppRouter.navigateToWeightLiquidCalculator(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: LucideIcons.percent,
                    label: t('discountCalculator'),
                    color: const Color(0xFF2563EB), // Blue
                    onTap: () {
                      AppRouter.navigateToDiscountCalculator(context);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    t('recentItems'),
                    style: GoogleFonts.hindMadurai(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              ...recentProducts.map((product) => DashboardProductCard(
                    product: product,
                    locale: locale,
                    onTap: () {
                      // View product details
                      AppRouter.navigateToEditProduct(context, product);
                    },
                  )),
          ],
        ),
      ),
    );
  }

  String _getGreetingKey() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'goodMorning';
    } else if (hour >= 12 && hour < 17) {
      return 'goodAfternoon';
    } else {
      return 'goodEvening';
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return LucideIcons.sunrise;
    } else if (hour >= 12 && hour < 17) {
      return LucideIcons.sun;
    } else {
      return LucideIcons.sunset;
    }
  }

  Color _getGreetingColor() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return const Color(0xFF10B981); // Emerald green for morning
    } else if (hour >= 12 && hour < 17) {
      return const Color(0xFF059669); // Primary green for afternoon (matches app theme)
    } else {
      return const Color(0xFF047857); // Dark green for evening
    }
  }

  Widget _buildGreetingSection(BuildContext context, String Function(String) t) {
    final greetingKey = _getGreetingKey();
    final greetingIcon = _getGreetingIcon();
    final greetingColor = _getGreetingColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: greetingColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              greetingIcon,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t(greetingKey),
                style: GoogleFonts.hindMadurai(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Text(
                t('welcomeMessage'),
                style: GoogleFonts.hindMadurai(
                  fontSize: 13,
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
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
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
              final product = ref.read(productsProvider).firstWhere((p) => p.id == productId);
              
              // Mobile notification
              final notificationTitle = t('productDeleted');
              final notificationBody = product.name;
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
