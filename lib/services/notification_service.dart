import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/product.dart';
import '../utils/helpers.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  


  static Future<void> init() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    


    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );
    
    // Request permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {


    // For mobile/desktop, use native notifications
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'malar_store_channel',
      'Malar Store Notifications',
      channelDescription: 'Notifications for product expiry and updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Schedule daily notification for expiring products
  static Future<void> scheduleDailyExpiringProductNotification({
    required int id,
    required String productName,
    required int hour, // Hour of day (0-23)
  }) async {


    await _notificationsPlugin.zonedSchedule(
      id,
      'Expiring Soon',
      '$productName is expiring soon!',
      _nextInstanceOfTime(hour, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiring_products_channel',
          'Expiring Products',
          channelDescription: 'Daily reminders for expiring products',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedule 12-hour recurring notification for pending credits
  static Future<void> schedule12HourCreditReminder({
    required int id,
    required String customerName,
    required double pendingAmount,
  }) async {


    // Schedule first notification in 12 hours
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(hours: 12));

    await _notificationsPlugin.zonedSchedule(
      id,
      'Credit Reminder',
      '$customerName is pending ₹${pendingAmount.toStringAsFixed(2)}.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'credit_reminders_channel',
          'Credit Reminders',
          channelDescription: '12-hour reminders for pending credits',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Schedule daily notifications for 7 days before expiry
  static Future<void> scheduleExpiryReminders(Product product) async {
    final expiryDate = Helpers.parseDate(product.expiryDate);
    if (expiryDate == null) return;

    // Base ID from product ID hash
    final baseId = product.id.hashCode;

    // Clear any existing notifications for this product (offsets 1-7)
    for (int i = 1; i <= 7; i++) {
       await cancelNotification(baseId + i);
    }

    // Don't schedule if already expired or expiring today
    if (expiryDate.isBefore(DateTime.now())) return;

    // Schedule for 7 days before
    for (int days = 7; days >= 1; days--) {
        final notificationDate = expiryDate.subtract(Duration(days: days));
        
        // Target time: 9:00 AM on that day
        final scheduledTime = tz.TZDateTime(
          tz.local, 
          notificationDate.year, 
          notificationDate.month, 
          notificationDate.day, 
          9, // 9 AM
          0
        );

        // Only schedule if the time is in the future
        if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
           await _notificationsPlugin.zonedSchedule(
            baseId + days, // Unique ID for each day
            'Expiry Alert',
            '${product.name} is expiring soon in $days days.',
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'expiry_reminders_channel',
                'Expiry Reminders',
                channelDescription: 'Daily 7-day countdown for expiring products',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
    }
  }

  // Cancel a scheduled notification
  static Future<void> cancelNotification(int id) async {

    await _notificationsPlugin.cancel(id);
  }

  // Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {

    await _notificationsPlugin.cancelAll();
  }

  // Helper to get next instance of a specific time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
}
