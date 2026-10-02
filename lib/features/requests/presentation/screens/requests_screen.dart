import 'package:community/app/app_router.dart';
import 'package:community/core/constants/asset_constants.dart';
import 'package:community/core/theme/app_colors.dart';
import 'package:community/features/home/models/request.dart';
import 'package:community/features/requests/presentation/screens/request_status_chip.dart';
import 'package:community/features/requests/presentation/screens/request_store.dart';
import 'package:flutter/material.dart';

enum _Filter { all, active, resolved }

extension on _Filter {
  String get label {
    switch (this) {
      case _Filter.all:
        return 'All';
      case _Filter.active:
        return 'Active';
      case _Filter.resolved:
        return 'Resolved';
    }
  }
}

/// "My Requests" tab: every report the user has sent, with its status.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  _Filter _filter = _Filter.all;

  bool _matches(Request request) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.active:
        return request.status.isActive;
      case _Filter.resolved:
        return !request.status.isActive;
    }
  }

  void _openReport() => Navigator.pushNamed(context, AppRouter.report);

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  void _showDetails(Request request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RequestDetailSheet(request: request),
    );
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
            listenable: RequestStore.instance,
            builder: (context, _) {
              final all = RequestStore.instance.requests;
              final activeCount = all.where((r) => r.status.isActive).length;
              final resolvedCount = all.length - activeCount;
              final items = all.where(_matches).toList();

              return Column(
                children: [
                  _buildHeader(total: all.length, active: activeCount),
                  _buildFilters(
                    all: all.length,
                    active: activeCount,
                    resolved: resolvedCount,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      // Keep the content at the top (the default centers it).
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, ?current],
                      ),
                      child: KeyedSubtree(
                        key: ValueKey('${_filter.name}-${items.length}'),
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
  // Header: title, short summary, quick "new report" button
  // ---------------------------------------------------------------
  Widget _buildHeader({required int total, required int active}) {
    final String summary;
    if (total == 0) {
      summary = 'Nothing reported yet';
    } else if (active == 0) {
      summary = "All caught up. Nothing is waiting.";
    } else {
      summary = '$active active ${active == 1 ? 'request' : 'requests'}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Requests',
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
          IconButton(
            tooltip: 'Report an Issue',
            onPressed: _openReport,
            icon: const Icon(Icons.add_rounded, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              fixedSize: const Size(44, 44),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Filter pills with counts: All / Active / Resolved
  // ---------------------------------------------------------------
  Widget _buildFilters({
    required int all,
    required int active,
    required int resolved,
  }) {
    int countFor(_Filter f) {
      switch (f) {
        case _Filter.all:
          return all;
        case _Filter.active:
          return active;
        case _Filter.resolved:
          return resolved;
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
  // List of request cards (pull down to refresh)
  // ---------------------------------------------------------------
  Widget _buildList(List<Request> items) {
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

  Widget _buildCard(Request request, int index) {
    // Later cards animate a little slower, so they appear one after another.
    final delayStep = index > 6 ? 6 : index;

    return TweenAnimationBuilder<double>(
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
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: InkWell(
          onTap: () => _showDetails(request),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon, title, place and date
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        request.icon,
                        color: AppColors.brand,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.title,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            request.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.hint,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress: submitted, assigned, in progress, resolved
                _ProgressBar(status: request.status),
                const SizedBox(height: 14),

                // Status chip + who is handling it
                Row(
                  children: [
                    RequestStatusChip(status: request.status),
                    const SizedBox(width: 12),
                    Expanded(child: _buildHandler(request)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandler(Request request) {
    final assignedTo = request.assignedTo;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          assignedTo != null
              ? Icons.person_outline_rounded
              : Icons.hourglass_empty_rounded,
          size: 15,
          color: AppColors.hint,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            assignedTo ?? 'Waiting for assignment',
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
                Icons.assignment_outlined,
                size: 40,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isAll ? 'No requests yet' : 'Nothing here',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAll
                  ? 'Reports you send will show up here with their status.'
                  : 'No ${_filter.label.toLowerCase()} requests right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.body,
              ),
            ),
            if (isAll) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: _openReport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: AppColors.brand),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Report an Issue',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// 4-step progress bar shown on each card
// ---------------------------------------------------------------
class _ProgressBar extends StatelessWidget {
  final RequestStatus status;

  const _ProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    // pending 1 bar, assigned 2, inProgress 3, resolved 4.
    final filled = status.index + 1;
    const total = 4;

    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: i < filled
                    ? AppColors.brand
                    : AppColors.border.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------
// Detail bottom sheet: info + progress timeline
// ---------------------------------------------------------------
class _RequestDetailSheet extends StatelessWidget {
  final Request request;

  const _RequestDetailSheet({required this.request});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(request.icon, color: AppColors.brand, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${request.id} · ${request.dateLabel}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.body,
                      ),
                    ),
                  ],
                ),
              ),
              RequestStatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Category', value: request.category),
                _divider(),
                _DetailRow(label: 'Issue', value: request.issue),
                _divider(),
                _DetailRow(label: 'Location', value: request.location),
                if (request.note.isNotEmpty) ...[
                  _divider(),
                  _DetailRow(label: 'Note', value: request.note),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 14),
          _Timeline(request: request),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: AppColors.border.withValues(alpha: 0.25));
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.body,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final Request request;

  const _Timeline({required this.request});

  @override
  Widget build(BuildContext context) {
    // RequestStatus.index: pending 0, assigned 1, inProgress 2, resolved 3.
    final current = request.status.index;

    final steps = <({String title, String subtitle})>[
      (
        title: 'Submitted',
        subtitle: 'Sent to the caretaker / manager · ${request.timeLabel}',
      ),
      (
        title: 'Assigned',
        subtitle: request.assignedTo != null
            ? 'Assigned to ${request.assignedTo}'
            : 'Waiting for someone to pick it up',
      ),
      (title: 'In progress', subtitle: 'Work has started'),
      (title: 'Resolved', subtitle: 'The issue has been fixed'),
    ];

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _buildStep(
            title: steps[i].title,
            subtitle: steps[i].subtitle,
            done: i <= current,
            isCurrent: i == current,
            isLast: i == steps.length - 1,
            lineDone: i < current,
          ),
      ],
    );
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    required bool done,
    required bool isCurrent,
    required bool isLast,
    required bool lineDone,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.brand : Colors.white,
                    border: Border.all(
                      color: done
                          ? AppColors.brand
                          : AppColors.border.withValues(alpha: 0.6),
                      width: 1.6,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.25),
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineDone
                          ? AppColors.brand
                          : AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: done ? AppColors.title : AppColors.hint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: done ? AppColors.body : AppColors.hint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}