import 'package:flutter/material.dart';
import '../utils/constants.dart';

class InAppNotificationOverlay extends StatefulWidget {
  final Widget child;

  const InAppNotificationOverlay({
    super.key,
    required this.child,
  });

  static final GlobalKey<_InAppNotificationOverlayState> globalKey = GlobalKey();

  static void show(BuildContext context, String title, String body) {
    globalKey.currentState?.showNotification(title, body);
  }

  @override
  State<InAppNotificationOverlay> createState() => _InAppNotificationOverlayState();
}

class _InAppNotificationOverlayState extends State<InAppNotificationOverlay>
    with SingleTickerProviderStateMixin {
  final List<_NotificationData> _notifications = [];
  
  void showNotification(String title, String body) {
    setState(() {
      _notifications.add(_NotificationData(title: title, body: body));
    });

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _notifications.isNotEmpty) {
        setState(() {
          _notifications.removeAt(0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_notifications.isNotEmpty)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Column(
                children: _notifications.map((notification) {
                  return _NotificationCard(
                    title: notification.title,
                    body: notification.body,
                    onDismiss: () {
                      setState(() {
                        _notifications.remove(notification);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationData {
  final String title;
  final String body;

  _NotificationData({required this.title, required this.body});
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onDismiss,
            color: AppColors.gray,
          ),
        ],
      ),
    );
  }
}
