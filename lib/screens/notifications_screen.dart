import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';
import '../utils/app_router.dart';
import '../providers/app_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final notificationState = ref.watch(notificationProvider);
    String t(String key) => TranslationService.translate(key, locale);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          t('notifications'),
          style: GoogleFonts.hindMadurai(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          if (notificationState.notifications.isNotEmpty) ...[
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsSeen();
              },
              child: Text(
                t('markAllRead'),
                style: const TextStyle(color: AppColors.white, fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2),
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(t('clearAll')),
                    content: Text('Are you sure you want to clear all notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(notificationProvider.notifier).clearAll();
                          Navigator.pop(context);
                        },
                        child: Text(
                          t('clearAll'),
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: notificationState.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bell,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('noNotifications'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notificationState.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationState.notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () {
                    // Mark as seen
                    ref.read(notificationProvider.notifier).markAsSeen(notification.id);
                    
                    // Navigate based on type
                    _navigateToRelevantScreen(context, ref, notification.type);
                  },
                );
              },
            ),
    );
  }

  void _navigateToRelevantScreen(BuildContext context, WidgetRef ref, String type) {
    // Navigate to relevant screen based on notification type
    if (type.startsWith('product_')) {
      // Navigate to products tab (index 1)
      ref.read(navigationProvider.notifier).setIndex(1);
      Navigator.pop(context); // Close notifications screen
    } else if (type.startsWith('credit_')) {
      // Navigate to credits tab (index 3)
      ref.read(navigationProvider.notifier).setIndex(3);
      Navigator.pop(context);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  IconData _getIconForType(String type) {
    if (type.contains('product_add')) return LucideIcons.packagePlus;
    if (type.contains('product_edit')) return LucideIcons.packageCheck;
    if (type.contains('product_delete')) return LucideIcons.packageX;
    if (type.contains('credit_add')) return LucideIcons.filePlus;
    if (type.contains('credit_edit')) return LucideIcons.fileEdit;
    if (type.contains('credit_delete')) return LucideIcons.fileX;
    return LucideIcons.bell;
  }

  Color _getColorForType(String type) {
    if (type.contains('delete')) return AppColors.red;
    if (type.contains('add')) return Colors.green;
    if (type.contains('edit')) return Colors.orange;
    return AppColors.primary;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForType(notification.type);
    final color = _getColorForType(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.seen ? AppColors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.seen ? Colors.grey[200]! : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.seen ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        if (!notification.seen)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
