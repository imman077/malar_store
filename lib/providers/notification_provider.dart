import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../services/storage_service.dart';

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

  Future<void> _loadNotifications() async {
    final notifications = await StorageService.loadNotifications();
    final unseenCount = notifications.where((n) => !n.seen).length;

    state = NotificationState(
      notifications: notifications,
      unseenCount: unseenCount,
    );
  }

  Future<void> _saveNotifications() async {
    await StorageService.saveNotifications(state.notifications);
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
