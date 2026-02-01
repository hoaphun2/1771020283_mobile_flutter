import 'package:flutter/material.dart';
import 'package:mobile_flutter/models/user_model.dart';

class NotificationService with ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
      notifyListeners();
    }
  }

  List<NotificationModel> get notifications => _notifications;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _unreadCount--;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
      }
    }
    _unreadCount = 0;
    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }
}