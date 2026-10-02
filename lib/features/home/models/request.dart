import 'package:flutter/material.dart';

/// Order matters: the detail timeline uses [RequestStatus.index].
enum RequestStatus { pending, assigned, inProgress, resolved }

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.assigned:
        return 'Assigned';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.resolved:
        return 'Resolved';
    }
  }

  /// "Active" filter = anything not resolved yet.
  bool get isActive => this != RequestStatus.resolved;
}

const List<String> _months = [
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

class Request {
  final String id; // e.g. #RPT-1042
  final String category; // e.g. Plumbing
  final String issue; // e.g. Leakage
  final String unit; // e.g. Flat 201
  final String tower; // e.g. Tower A
  final String note;
  final IconData icon;
  final RequestStatus status;
  final DateTime createdAt;

  /// Caretaker / manager handling it, once assigned.
  final String? assignedTo;

  const Request({
    required this.id,
    required this.category,
    required this.issue,
    required this.unit,
    required this.tower,
    required this.icon,
    required this.status,
    required this.createdAt,
    this.note = '',
    this.assignedTo,
  });

  String get title => '$category · $issue';

  String get location => '$unit · $tower';

  String get subtitle => '$unit · $dayLabel';

  String get dayLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = today.difference(day).inDays;

    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${createdAt.day} ${_months[createdAt.month - 1]}';
  }

  String get dateLabel =>
      '${createdAt.day} ${_months[createdAt.month - 1]} ${createdAt.year}';

  String get timeLabel {
    final hour = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
