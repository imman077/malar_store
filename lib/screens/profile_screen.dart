import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    String t(String key) => TranslationService.translate(key, locale);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Store Name
                  Text(
                    locale == 'ta' ? 'மலர் ஸ்டோர்' : 'Malar Stores',
                    style: GoogleFonts.hindMadurai(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    locale == 'ta' ? 'கடை உரிமையாளர்' : 'Shop Owner',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Section
            _buildSectionTitle(t('settings'), locale),
            const SizedBox(height: 12),

            // Language Setting
            _buildSettingCard(
              icon: LucideIcons.languages,
              title: t('language'),
              subtitle: locale == 'ta' ? 'தமிழ்' : 'English',
              onTap: () {
                ref.read(languageProvider.notifier).toggleLanguage();
              },
            ),

            // Notifications Setting
            _buildSettingCard(
              icon: LucideIcons.bell,
              title: locale == 'ta' ? 'அறிவிப்புகள்' : 'Notifications',
              subtitle: locale == 'ta' ? 'இயக்கப்பட்டது' : 'Enabled',
              onTap: () {
                // TODO: Implement notifications settings
              },
            ),

            const SizedBox(height: 24),

            // About Section
            _buildSectionTitle(locale == 'ta' ? 'பற்றி' : 'About', locale),
            const SizedBox(height: 12),

            // App Version
            _buildSettingCard(
              icon: LucideIcons.info,
              title: locale == 'ta' ? 'பதிப்பு' : 'Version',
              subtitle: '1.0.0',
              onTap: () {},
              showArrow: false,
            ),

            // Help & Support
            _buildSettingCard(
              icon: LucideIcons.helpCircle,
              title: locale == 'ta' ? 'உதவி & ஆதரவு' : 'Help & Support',
              subtitle: locale == 'ta' ? 'உதவி பெறுங்கள்' : 'Get help',
              onTap: () {
                // TODO: Implement help & support
              },
            ),

            const SizedBox(height: 24),

            // Logout Button
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     onPressed: () {
            //       _showLogoutDialog(context, locale);
            //     },
            //     icon: const Icon(LucideIcons.logOut),
            //     label: Text(
            //       locale == 'ta' ? 'வெளியேறு' : 'Logout',
            //       style: const TextStyle(
            //         fontSize: 16,
            //         fontWeight: FontWeight.w600,
            //       ),
            //     ),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: AppColors.red,
            //       foregroundColor: AppColors.white,
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String locale) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.hindMadurai(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.gray,
          ),
        ),
        trailing: showArrow
            ? const Icon(
                LucideIcons.chevronRight,
                color: AppColors.gray,
                size: 20,
              )
            : null,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, String locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale == 'ta' ? 'வெளியேறு' : 'Logout'),
        content: Text(
          locale == 'ta'
              ? 'நீங்கள் வெளியேற விரும்புகிறீர்களா?'
              : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale == 'ta' ? 'ரத்து' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout functionality
            },
            child: Text(
              locale == 'ta' ? 'வெளியேறு' : 'Logout',
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}
