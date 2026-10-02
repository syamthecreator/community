import 'package:community/core/theme/app_colors.dart';
import 'package:community/features/home/models/request.dart';
import 'package:flutter/material.dart';

/// Status pill used on Home and on the Requests screen.
/// Only AppColors are used, so the four states differ by style:
/// grey (pending), outlined (assigned), tinted (in progress), tinted + tick (resolved).
class RequestStatusChip extends StatelessWidget {
  final RequestStatus status;

  const RequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color foreground;
    final Color background;
    Color? borderColor;

    switch (status) {
      case RequestStatus.pending:
        foreground = AppColors.body;
        background = AppColors.hint.withValues(alpha: 0.18);
      case RequestStatus.assigned:
        foreground = AppColors.brandDark;
        background = Colors.transparent;
        borderColor = AppColors.brand.withValues(alpha: 0.6);
      case RequestStatus.inProgress:
        foreground = AppColors.brand;
        background = AppColors.brand.withValues(alpha: 0.14);
      case RequestStatus.resolved:
        foreground = AppColors.brandDark;
        background = AppColors.brandDark.withValues(alpha: 0.12);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: borderColor == null ? null : Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == RequestStatus.resolved) ...[
            Icon(Icons.check_rounded, size: 13, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
