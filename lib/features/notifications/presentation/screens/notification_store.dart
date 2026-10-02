import 'package:community/features/notifications/presentation/screens/app_notification.dart';
import 'package:flutter/material.dart';

/// Simple in-memory list of notifications.
///
/// The Notifications screen and the bell on Home both read from this, so
/// reading or deleting a notification updates the unread dot straight away.
/// Replace with your repository / API + state management later.
class NotificationStore extends ChangeNotifier {
  NotificationStore._();

  static final NotificationStore instance = NotificationStore._();

  final List<AppNotification> _items = mockNotifications();

  /// Newest first.
  List<AppNotification> get notifications => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.isRead).length;

  void _setRead(String id, bool read) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1 || _items[i].isRead == read) return;
    _items[i] = _items[i].copyWith(isRead: read);
    notifyListeners();
  }

  void markRead(String id) => _setRead(id, true);

  void toggleRead(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1) return;
    _setRead(id, !_items[i].isRead);
  }

  void markAllRead() {
    if (unreadCount == 0) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  /// Removes a notification and returns its position, so it can be restored.
  int remove(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1) return -1;
    _items.removeAt(i);
    notifyListeners();
    return i;
  }

  /// Puts a deleted notification back (used by "Undo").
  void restore(AppNotification notification, int index) {
    final at = index.clamp(0, _items.length);
    _items.insert(at, notification);
    notifyListeners();
  }
}
