import 'package:community/core/theme/app_colors.dart';
import 'package:community/core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  request,
  announcement,
  maintenance,
  event,
  guest,
  payment,
}

enum NotificationPriority { important, normal }

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

  String get timeLabel {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final day = DateTime(time.year, time.month, time.day);

    final diff = today.difference(day).inDays;

    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.hour >= 12 ? 'PM' : 'AM';

    final clock = '$hour:$minute $period';

    if (diff == 0) {
      return 'Today, $clock';
    }

    if (diff == 1) {
      return 'Yesterday, $clock';
    }

    return '${time.day} ${_months[time.month - 1]}, $clock';
  }
}

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

class NotificationStore extends ChangeNotifier {
  NotificationStore._();

  static final NotificationStore instance = NotificationStore._();
  final List<AppNotification> _items = mockNotifications();
  List<AppNotification> get notifications => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.isRead).length;

  void _setRead(String id, bool read) {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1) return;
    if (_items[index].isRead == read) return;
    _items[index] = _items[index].copyWith(isRead: read);

    notifyListeners();
  }

  void markRead(String id) {
    _setRead(id, true);
  }

  void toggleRead(String id) {
    final index = _items.indexWhere((n) => n.id == id);

    if (index == -1) return;

    _setRead(id, !_items[index].isRead);
  }

  void markAllRead() {
    if (unreadCount == 0) return;

    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }

    notifyListeners();
  }

  int remove(String id) {
    final index = _items.indexWhere((n) => n.id == id);

    if (index == -1) return -1;

    _items.removeAt(index);

    notifyListeners();

    return index;
  }

  void restore(AppNotification notification, int index) {
    final position = index.clamp(0, _items.length);

    _items.insert(position, notification);

    notifyListeners();
  }
}

enum _Filter { all, important, normal }

extension on _Filter {
  String get label {
    switch (this) {
      case _Filter.all:
        return 'All';

      case _Filter.important:
        return 'Important';

      case _Filter.normal:
        return 'Normal';
    }
  }
}

enum _MenuAction { toggleRead, delete }

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const NotificationsScreen({super.key, this.onBack});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationStore _store = NotificationStore.instance;

  _Filter _filter = _Filter.all;

  bool _matches(AppNotification notification) {
    switch (_filter) {
      case _Filter.all:
        return true;

      case _Filter.important:
        return notification.isImportant;

      case _Filter.normal:
        return !notification.isImportant;
    }
  }

  void _open(AppNotification notification) {
    _store.markRead(notification.id);
  }

  void _onMenu(_MenuAction action, AppNotification notification) {
    switch (action) {
      case _MenuAction.toggleRead:
        _store.toggleRead(notification.id);

      case _MenuAction.delete:
        final index = _store.remove(notification.id);

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Notification deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  if (index != -1) {
                    _store.restore(notification, index);
                  }
                },
              ),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDCE8F8),
                  Color(0xFFE9F0FA),
                  Color(0xFFF5FEFF),
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          child: ListenableBuilder(
            listenable: _store,
            builder: (context, _) {
              final all = _store.notifications;
              final unread = _store.unreadCount;
              final important = all.where((n) => n.isImportant).length;
              final items = all.where(_matches).toList();

              return Column(
                children: [
                  _buildHeader(unread),

                  _buildFilters(
                    all: all.length,
                    important: important,
                    normal: all.length - important,
                  ),

                  Expanded(
                    child: items.isEmpty ? _buildEmpty() : _buildList(items),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int unread) {
  final summary = unread == 0
      ? "You're all caught up"
      : '$unread unread ${unread == 1 ? 'notification' : 'notifications'}';

  return Row(
    children: [
      SizedBox(width: 76, child: AppBackButton(onPressed: widget.onBack)),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            height: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.15,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (unread > 0)
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 20),
          child: IconButton(
            tooltip: 'Mark all as read',
            onPressed: _store.markAllRead,
            icon: const Icon(Icons.done_all_rounded, size: 22),
            color: AppColors.brand,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.kwhite,
              side: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
              fixedSize: const Size(44, 44),
            ),
          ),
        )
      else
        const SizedBox(width: 20),
    ],
  );
}

  Widget _buildFilters({
    required int all,
    required int important,
    required int normal,
  }) {
    int countFor(_Filter filter) {
      switch (filter) {
        case _Filter.all:
          return all;

        case _Filter.important:
          return important;

        case _Filter.normal:
          return normal;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          for (var i = 0; i < _Filter.values.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),

            Expanded(
              child: _buildFilterPill(
                _Filter.values[i],
                countFor(_Filter.values[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPill(_Filter filter, int count) {
    final selected = _filter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _filter = filter;
        });
      },
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.kwhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.brand
                : AppColors.border.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filter.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.kwhite : AppColors.title,
              ),
            ),

            const SizedBox(width: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.kwhite.withValues(alpha: 0.25)
                    : AppColors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.kwhite : AppColors.brand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AppNotification> items) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildCard(items[index], index);
      },
    );
  }

  Widget _buildCard(AppNotification notification, int index) {
    final delayStep = index > 6 ? 6 : index;

    final Color accent = notification.isImportant
        ? AppColors.error
        : AppColors.brand;

    final Color cardColor = notification.isRead
        ? AppColors.kwhite
        : Color.alphaBlend(
            AppColors.brand.withValues(alpha: 0.06),
            AppColors.kwhite,
          );

    return TweenAnimationBuilder<double>(
      key: ValueKey(notification.id),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + delayStep * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: Material(
        color: cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: notification.isRead
                ? AppColors.border.withValues(alpha: 0.3)
                : AppColors.brand.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: () => _open(notification),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notification.icon, color: accent, size: 23),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.title,
                              ),
                            ),
                          ),

                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),

                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.body,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppColors.hint,
                          ),

                          const SizedBox(width: 5),

                          Flexible(
                            child: Text(
                              notification.timeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.hint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildMenu(notification),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(AppNotification notification) {
    return PopupMenuButton<_MenuAction>(
      tooltip: 'More',
      padding: EdgeInsets.zero,
      color: AppColors.kwhite,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.hint),
      onSelected: (action) {
        _onMenu(action, notification);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MenuAction.toggleRead,
          child: Row(
            children: [
              Icon(
                notification.isRead
                    ? Icons.mark_email_unread_outlined
                    : Icons.done_all_rounded,
                size: 19,
                color: AppColors.title,
              ),

              const SizedBox(width: 10),

              Text(
                notification.isRead ? 'Mark as unread' : 'Mark as read',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
        ),

        const PopupMenuItem(
          value: _MenuAction.delete,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: AppColors.error,
              ),

              SizedBox(width: 10),

              Text(
                'Delete',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final isAll = _filter == _Filter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 40, right: 40, bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: AppColors.brand,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              isAll ? 'No notifications' : 'Nothing here',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              isAll
                  ? 'Alerts about your requests and community updates will show up here.'
                  : 'No ${_filter.label.toLowerCase()} notifications right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
