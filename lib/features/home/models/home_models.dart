import 'package:community/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

const int maxChars = 50;
const String myId = '201';
const String communityName = 'Favorite Homes';
const int memberCount = 30;
final List<String> memberRooms = List.generate(
  memberCount,
  (i) => '${i ~/ 6 + 1}0${i % 6 + 1}',
);

String clip(String s) =>
    s.length <= maxChars ? s : '${s.substring(0, maxChars - 1)}…';

enum ChatType { admin, member, report, sos }

enum DeleteChoice { everyone, me }

enum ReportStatus { submitted, inProgress, resolved }

extension ReportStatusX on ReportStatus {
  String get label => switch (this) {
    ReportStatus.submitted => 'Submitted',
    ReportStatus.inProgress => 'In Progress',
    ReportStatus.resolved => 'Resolved',
  };
  Color get color => switch (this) {
    ReportStatus.submitted => AppColors.slate,
    ReportStatus.inProgress => AppColors.orange,
    ReportStatus.resolved => AppColors.brand,
  };
}

class ChatItem {
  const ChatItem({
    required this.day,
    required this.type,
    required this.userId,
    required this.time,
    this.text = '',
    this.hasImage = false,
    this.photoPath,
    this.reportTitle,
    this.reportIcon,
    this.status,
    this.adminOnly = false,
    this.replyAuthor,
    this.replyText,
    this.edited = false,
    this.deleted = false,
  });

  final String day;
  final ChatType type;
  final String userId;
  final String time;
  final String text;
  final bool hasImage;
  final String? photoPath;
  final String? reportTitle;
  final IconData? reportIcon;
  final ReportStatus? status;
  final bool adminOnly;
  final String? replyAuthor;
  final String? replyText;
  final bool edited;
  final bool deleted;

  ChatItem copyWith({String? text, bool? edited, bool? deleted}) => ChatItem(
    day: day,
    type: type,
    userId: userId,
    time: time,
    text: text ?? this.text,
    hasImage: hasImage,
    photoPath: photoPath,
    reportTitle: reportTitle,
    reportIcon: reportIcon,
    status: status,
    adminOnly: adminOnly,
    replyAuthor: replyAuthor,
    replyText: replyText,
    edited: edited ?? this.edited,
    deleted: deleted ?? this.deleted,
  );

  bool get isMine => userId == myId;
  bool get isAdmin => type == ChatType.admin;

  String get displayName =>
      isAdmin ? 'Community Admin' : (isMine ? 'You' : 'Room $userId');
}

class PreviewResult {
  const PreviewResult({this.caption = '', this.retake = false});
  final String caption;
  final bool retake;
}

class GlassMenuItem {
  const GlassMenuItem({
    required this.value,
    required this.icon,
    required this.label,
  });
  final String value;
  final IconData icon;
  final String label;
}