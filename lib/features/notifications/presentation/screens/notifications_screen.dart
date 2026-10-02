import 'package:community/core/constants/asset_constants.dart';
import 'package:community/core/theme/app_colors.dart';
import 'package:community/features/notifications/presentation/screens/app_notification.dart';
import 'package:community/features/notifications/presentation/screens/notification_store.dart';
import 'package:flutter/material.dart';

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

/// "Notifications" tab: personal alerts such as request status changes,
/// announcements, maintenance notices, guest entries and reminders.
class NotificationsScreen extends StatefulWidget {
  /// When set, a back button is shown (used to jump back to the Home tab).
  final VoidCallback? onBack;

  /// Tapping a request notification jumps to the Requests tab.
  final VoidCallback? onOpenRequests;

  /// Tapping an announcement / maintenance / event notification jumps
  /// to the Updates tab.
  final VoidCallback? onOpenUpdates;

  const NotificationsScreen({
    super.key,
    this.onBack,
    this.onOpenRequests,
    this.onOpenUpdates,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationStore _store = NotificationStore.instance;

  _Filter _filter = _Filter.all;

  bool _matches(AppNotification n) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.important:
        return n.isImportant;
      case _Filter.normal:
        return !n.isImportant;
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  void _open(AppNotification n) {
    _store.markRead(n.id);

    switch (n.type) {
      case NotificationType.request:
        widget.onOpenRequests?.call();
      case NotificationType.announcement:
      case NotificationType.maintenance:
      case NotificationType.event:
      case NotificationType.payment:
        widget.onOpenUpdates?.call();
      case NotificationType.guest:
        break;
    }
  }

  void _onMenu(_MenuAction action, AppNotification n) {
    switch (action) {
      case _MenuAction.toggleRead:
        _store.toggleRead(n.id);
      case _MenuAction.delete:
        final index = _store.remove(n.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Notification deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => _store.restore(n, index),
              ),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.5,
            child: Image.asset(
              AssetConstants.background,
              fit: BoxFit.cover,
              alignment: Alignment.center,
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, ?current],
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_filter.name),
                        child: items.isEmpty
                            ? _buildEmpty()
                            : _buildList(items),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Header: back button, title, unread summary, "mark all as read"
  // ---------------------------------------------------------------
  Widget _buildHeader(int unread) {
    final summary = unread == 0
        ? "You're all caught up"
        : '$unread unread ${unread == 1 ? 'notification' : 'notifications'}';

    final circleStyle = IconButton.styleFrom(
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
      fixedSize: const Size(44, 44),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          if (widget.onBack != null) ...[
            IconButton(
              tooltip: 'Back',
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: AppColors.title,
              style: circleStyle,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.body,
                  ),
                ),
              ],
            ),
          ),
          if (unread > 0)
            IconButton(
              tooltip: 'Mark all as read',
              onPressed: _store.markAllRead,
              icon: const Icon(Icons.done_all_rounded, size: 22),
              color: AppColors.brand,
              style: circleStyle,
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Filter pills with counts: All / Important / Normal
  // ---------------------------------------------------------------
  Widget _buildFilters({
    required int all,
    required int important,
    required int normal,
  }) {
    int countFor(_Filter f) {
      switch (f) {
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
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : Colors.white,
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
                color: selected ? Colors.white : AppColors.title,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.brand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // List (pull down to refresh)
  // ---------------------------------------------------------------
  Widget _buildList(List<AppNotification> items) {
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildCard(items[index], index),
      ),
    );
  }

  Widget _buildCard(AppNotification n, int index) {
    final delayStep = index > 6 ? 6 : index;

    // Important alerts get a red-tinted icon, the rest use the brand colour.
    final Color accent = n.isImportant ? AppColors.error : AppColors.brand;

    // Unread cards get a faint green wash so they stand out.
    final Color cardColor = n.isRead
        ? Colors.white
        : Color.alphaBlend(
            AppColors.brand.withValues(alpha: 0.06),
            Colors.white,
          );

    return TweenAnimationBuilder<double>(
      key: ValueKey(n.id),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + delayStep * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: Material(
        color: cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: n.isRead
                ? AppColors.border.withValues(alpha: 0.3)
                : AppColors.brand.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: () => _open(n),
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
                  child: Icon(n.icon, color: accent, size: 23),
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
                              n.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.title,
                              ),
                            ),
                          ),
                          if (!n.isRead) ...[
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
                        n.message,
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
                              n.timeLabel,
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
                _buildMenu(n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Three-dot menu: mark read / unread, delete
  // ---------------------------------------------------------------
  Widget _buildMenu(AppNotification n) {
    return PopupMenuButton<_MenuAction>(
      tooltip: 'More',
      padding: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.hint),
      onSelected: (action) => _onMenu(action, n),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MenuAction.toggleRead,
          child: Row(
            children: [
              Icon(
                n.isRead
                    ? Icons.mark_email_unread_outlined
                    : Icons.done_all_rounded,
                size: 19,
                color: AppColors.title,
              ),
              const SizedBox(width: 10),
              Text(
                n.isRead ? 'Mark as unread' : 'Mark as read',
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

  // ---------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------
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
                  ? 'Alerts about your requests and community updates '
                        'will show up here.'
                  : 'No ${_filter.label.toLowerCase()} notifications '
                        'right now.',
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
