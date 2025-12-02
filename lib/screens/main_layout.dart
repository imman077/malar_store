import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/language_provider.dart';
import '../providers/store_provider.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';
import '../utils/app_router.dart';
import 'dashboard_screen.dart';
import 'product_list_screen.dart';
import 'product_form_screen.dart';
import 'credit_manager_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductListScreen(),
    const SizedBox(), // Placeholder for FAB
    const CreditManagerScreen(),
    const Center(child: Text('Profile')), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final expiredCount = ref.watch(expiredProductsCountProvider);
    
    String t(String key) => TranslationService.translate(key, locale);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.store,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('appName'),
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell),
                color: AppColors.white,
                onPressed: () {
                  // Navigate to expired items
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
              if (expiredCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _currentIndex == 2
          ? const SizedBox()
          : _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AppRouter.navigateToAddProduct(context);
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
              _buildNavItem(LucideIcons.home, t('dashboard'), 0),
              _buildNavItem(LucideIcons.package, t('items'), 1),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(LucideIcons.users, t('credits'), 3),
              _buildNavItem(LucideIcons.user, t('profile'), 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
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
}
