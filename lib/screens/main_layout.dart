import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/credit_note.dart';
import '../models/app_notification.dart';
import '../providers/language_provider.dart';
import '../providers/store_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/credit_form_provider.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/app_router.dart';
import '../utils/helpers.dart';
import 'dashboard_screen.dart';
import 'product_list_screen.dart';
import 'product_form_screen.dart';
import 'credit_manager_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../widgets/add_credit_dialog.dart';

import '../providers/app_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductListScreen(),
    const SizedBox(), // Placeholder for FAB
    const CreditManagerScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final expiredCount = ref.watch(expiredProductsCountProvider);
    final currentIndex = ref.watch(navigationProvider);
    
    String t(String key) => TranslationService.translate(key, locale);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Container(
            //   padding: const EdgeInsets.all(6),
            //   decoration: BoxDecoration(
            //     color: AppColors.white,
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   child: 
            // ),
            ClipRRect(
                child: Image.asset(
                  'assets/images/Image2.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.store,
                      color: AppColors.primary,
                      size: 24,
                    );
                  },
                ),
              ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('name'),
                  style: GoogleFonts.hindMadurai(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  t('subtitle'),
                  style: GoogleFonts.hindMadurai(
                    fontSize: 12,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Language Toggle
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () {
                ref.read(languageProvider.notifier).toggleLanguage();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                locale == 'ta' ? 'ENG' : 'தமிழ்',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Notification Bell
          IconButton(
            onPressed: () {
              // Navigate to notifications screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(LucideIcons.bell, color: AppColors.white),
                if (ref.watch(notificationProvider).unseenCount > 0)
                  Positioned(
                    right: -5,
                    top: -10,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${ref.watch(notificationProvider).unseenCount}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: currentIndex == 2
          ? const SizedBox()
          : _screens[currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Context-aware FAB behavior
          if (currentIndex == 0 || currentIndex == 4) {
            // Home or Profile - Show choice dialog
            _showAddChoiceDialog(context, ref);
          } else if (currentIndex == 1) {
            // Items tab - Go directly to add product
            AppRouter.navigateToAddProduct(context);
          } else if (currentIndex == 3) {
            // Credits tab - Show add credit dialog
            _showAddCreditDialog(context, ref);
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: AppColors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.white,
        elevation: 8,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(LucideIcons.home, t('dashboard'), 0, currentIndex),
              _buildNavItem(LucideIcons.package, t('items'), 1, currentIndex),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(LucideIcons.users, t('credits'), 3, currentIndex),
              _buildNavItem(LucideIcons.user, t('profile'), 4, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, int currentIndex) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(navigationProvider.notifier).setIndex(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.gray,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary : AppColors.gray,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChoiceDialog(BuildContext context, WidgetRef ref) {
    final locale = ref.read(languageProvider);
    String t(String key) => TranslationService.translate(key, locale);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('addNew')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.package, color: AppColors.primary),
              title: Text(t('addProduct')),
              onTap: () {
                Navigator.pop(context);
                AppRouter.navigateToAddProduct(context);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.fileText, color: AppColors.orange),
              title: Text(t('addCredit')),
              onTap: () {
                Navigator.pop(context);
                _showAddCreditDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.shoppingCart, color: AppColors.green),
              title: Text(locale == 'ta' ? 'புதிய ஆர்டர் (Shop)' : 'New Order (Shop)'),
              onTap: () {
                Navigator.pop(context);
                AppRouter.navigateToShop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCreditDialog(BuildContext context, WidgetRef ref) {
    final locale = ref.read(languageProvider);
    String t(String key) => TranslationService.translate(key, locale);
    
    showDialog(
      context: context,
      builder: (context) => AddCreditDialog(t: t),
    );
  }
}
