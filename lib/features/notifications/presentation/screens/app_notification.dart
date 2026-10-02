import 'package:flutter/material.dart';

/// What the notification is about. Decides where a tap takes the user.
enum NotificationType {
  request, // status change on a report the user sent
  announcement, // new announcement from management
  maintenance, // maintenance notice
  event, // community event reminder
  guest, // guest entry handled by security
  payment, // security contribution reminder
}

enum NotificationPriority { important, normal }

/// A personal alert for the signed-in resident / member.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final IconData icon;
  final DateTime time;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    required this.time,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
  });

  bool get isImportant => priority == NotificationPriority.important;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      icon: icon,
      time: time,
      priority: priority,
      isRead: isRead ?? this.isRead,
    );
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "Today, 11:20 AM", "Yesterday, 9:10 AM" or "12 Apr, 11:20 AM".
  String get timeLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final diff = today.difference(day).inDays;

    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final clock = '$hour:$minute $period';

    if (diff == 0) return 'Today, $clock';
    if (diff == 1) return 'Yesterday, $clock';
    return '${time.day} ${_months[time.month - 1]}, $clock';
  }
}

/// Mock data. Replace with your API / push notifications later.
List<AppNotification> mockNotifications() {
  final now = DateTime.now();

  return [
    AppNotification(
      id: 'ntf-1',
      title: 'Issue Status Updated',
      message: 'Your plumbing issue is now In progress.',
      type: NotificationType.request,
      icon: Icons.water_drop_outlined,
      time: now.subtract(const Duration(minutes: 25)),
    ),
    AppNotification(
      id: 'ntf-2',
      title: 'New Announcement',
      message: 'Water supply will be interrupted tomorrow (10 AM – 2 PM).',
      type: NotificationType.announcement,
      priority: NotificationPriority.important,
      icon: Icons.campaign_outlined,
      time: now.subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'ntf-3',
      title: 'Maintenance Update',
      message: 'Lift maintenance is scheduled for the 15th.',
      type: NotificationType.maintenance,
      icon: Icons.elevator_outlined,
      time: now.subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      id: 'ntf-4',
      title: 'Guest Entry Recorded',
      message: 'Security has recorded your guest for Flat 201.',
      type: NotificationType.guest,
      icon: Icons.person_add_alt_1_outlined,
      time: now.subtract(const Duration(days: 1, hours: 1)),
      isRead: true,
    ),
    AppNotification(
      id: 'ntf-5',
      title: 'Security Contribution Due',
      message: 'Your monthly security contribution is due by the 5th.',
      type: NotificationType.payment,
      priority: NotificationPriority.important,
      icon: Icons.shield_outlined,
      time: now.subtract(const Duration(days: 2)),
      isRead: true,
    ),
    AppNotification(
      id: 'ntf-6',
      title: 'Event Reminder',
      message: 'Community meet this Sunday at the clubhouse.',
      type: NotificationType.event,
      icon: Icons.event_outlined,
      time: now.subtract(const Duration(days: 3)),
      isRead: true,
    ),
    AppNotification(
      id: 'ntf-7',
      title: 'Issue Resolved',
      message: 'Your electrical issue has been marked as resolved.',
      type: NotificationType.request,
      icon: Icons.bolt_rounded,
      time: now.subtract(const Duration(days: 4)),
      isRead: true,
    ),
  ];
}
