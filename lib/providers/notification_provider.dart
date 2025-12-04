import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final int unseenCount;

  NotificationState({
    this.notifications = const [],
    this.unseenCount = 0,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unseenCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unseenCount: unseenCount ?? this.unseenCount,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState()) {
    _loadNotifications();
  }

  static const String _storageKey = 'app_notifications';

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_storageKey);
    
    if (notificationsJson != null) {
      final List<dynamic> decoded = jsonDecode(notificationsJson);
      final notifications = decoded
          .map((json) => AppNotification.fromJson(json))
          .toList();
      
      final unseenCount = notifications.where((n) => !n.seen).length;
      
      state = NotificationState(
        notifications: notifications,
        unseenCount: unseenCount,
      );
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      state.notifications.map((n) => n.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  void addNotification(AppNotification notification) {
    final updatedNotifications = [notification, ...state.notifications];
    final unseenCount = updatedNotifications.where((n) => !n.seen).length;
    
    state = NotificationState(
      notifications: updatedNotifications,
      unseenCount: unseenCount,
    );
    
    _saveNotifications();
  }

  void markAsSeen(String id) {
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == id && !n.seen) {
        return n.copyWith(seen: true);
      }
      return n;
    }).toList();
    
    final unseenCount = updatedNotifications.where((n) => !n.seen).length;
    
    state = NotificationState(
      notifications: updatedNotifications,
      unseenCount: unseenCount,
    );
    
    _saveNotifications();
  }

  void markAllAsSeen() {
    final updatedNotifications = state.notifications.map((n) {
      return n.copyWith(seen: true);
    }).toList();
    
    state = NotificationState(
      notifications: updatedNotifications,
      unseenCount: 0,
    );
    
    _saveNotifications();
  }

  void clearAll() {
    state = NotificationState();
    _saveNotifications();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
