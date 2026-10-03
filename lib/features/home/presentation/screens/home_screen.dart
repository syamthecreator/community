import 'dart:io';
import 'dart:ui';

import 'package:community/app/app_router.dart';
import 'package:community/core/constants/asset_constants.dart';
import 'package:community/core/theme/app_colors.dart';
import 'package:community/core/widgets/glass.dart';
import 'package:community/features/notifications/presentation/screens/notification_store.dart';
import 'package:community/features/report/presentation/screens/report_issue_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenView();
  }
}

// ───────────────────────── Config (replace with API / session data) ─────────────────────────
const int _maxChars = 50; // applies to EVERY text a member writes
const String _myId = 'USR-2041'; // current member's privacy-safe ID
const String _communityName = 'Green Valley Community';
const int _memberCount = 128;

String _clip(String s) =>
    s.length <= _maxChars ? s : '${s.substring(0, _maxChars - 1)}…';

// ───────────────────────── Extra tones ─────────────────────────
class _Tone {
  _Tone._();
  static const Color mint = Color(0xFF3FD0AE);
  static const Color sky = Color(0xFF55A8E8);
  static const Color lilac = Color(0xFF9B8CF2);
  static const Color sun = Color(0xFFF6B04A);
  static const Color coral = Color(0xFFFF7A7A);
}

// ───────────────────────── Model ─────────────────────────
enum _Type { admin, member, report, sos }

enum _DeleteChoice { everyone, me }

enum _Status { submitted, inProgress, resolved }

extension on _Status {
  String get label => switch (this) {
    _Status.submitted => 'Submitted',
    _Status.inProgress => 'In Progress',
    _Status.resolved => 'Resolved',
  };
  Color get color => switch (this) {
    _Status.submitted => AppColors.slate,
    _Status.inProgress => AppColors.orange,
    _Status.resolved => AppColors.brand,
  };
}

class _Item {
  const _Item({
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
  final _Type type;
  final String userId; // ONLY the ID is ever shown (no name / tower / flat)
  final String time;
  final String text;
  final bool hasImage;
  final String? photoPath;
  final String? reportTitle;
  final IconData? reportIcon;
  final _Status? status;
  final bool adminOnly;
  final String? replyAuthor;
  final String? replyText;
  final bool edited;
  final bool deleted;

  _Item copyWith({String? text, bool? edited, bool? deleted}) => _Item(
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

  bool get isMine => userId == _myId;
  bool get isAdmin => type == _Type.admin;
  String get displayName =>
      isAdmin ? 'Community Admin' : (isMine ? 'You' : userId);
}

String _avatarLabel(String id) =>
    id.length <= 2 ? id : id.substring(id.length - 2);

// ───────────────────────── Glass primitives ─────────────────────────
class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(22)),
    this.blur = 16,
    this.opacity = 0.55,
    this.tint,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderOpacity = 0.75,
    this.shadow = true,
    this.shadowColor,
    this.gradient,
  });

  final Widget child;
  final BorderRadius radius;
  final double blur;
  final double opacity;
  final Color? tint;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderOpacity;
  final bool shadow;
  final Color? shadowColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final base = tint ?? Colors.white;

    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withValues(alpha: (opacity * 1.15).clamp(0.0, 1.0)),
                base.withValues(alpha: opacity * 0.70),
                base.withValues(alpha: opacity * 0.50),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: borderOpacity),
          width: 1.2,
        ),
      ),
      child: child,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: (shadowColor ?? const Color(0xFF1B5E52)).withValues(
                    alpha: shadowColor == null ? 0.10 : 0.28,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: blur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: surface,
              )
            : surface,
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size, this.alpha = 0.35});
  final Color color;
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Screen ─────────────────────────
class _HomeScreenView extends StatefulWidget {
  const _HomeScreenView();

  @override
  State<_HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<_HomeScreenView>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  final _composerFocus = FocusNode();

  bool _showJump = false;
  bool _pinnedVisible = true;
  _Item? _replyTo;
  final Set<_Item> _selected = {};
  _Item? _editing;

  int _tab = 0; // 0 = chat, 1 = report
  GlobalKey<ReportIssueViewState> _reportKey = GlobalKey();
  bool _reportSubmitted = false;

  late final AnimationController _hold =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _sosSent();
        });

  // Sample data — replace with API/stream. Every text is <= 50 chars.
  // Backend rule: "Admin only" reports go only to the owner and admins.
  final List<_Item> _items = [
    const _Item(
      day: 'Yesterday',
      type: _Type.member,
      userId: 'USR-1093',
      time: '6:40 PM',
      hasImage: true,
      text: 'Parking light fixed',
    ),
    const _Item(
      day: 'Yesterday',
      type: _Type.report,
      userId: _myId,
      time: '8:15 PM',
      reportTitle: 'Plumbing Report',
      reportIcon: Icons.plumbing_rounded,
      text: 'Tap leaking, need a plumber',
      status: _Status.submitted,
      adminOnly: true,
    ),
    const _Item(
      day: 'Today',
      type: _Type.admin,
      userId: 'ADMIN',
      time: '9:00 AM',
      text: 'Water off 10 AM–12 PM today for maintenance',
    ),
    const _Item(
      day: 'Today',
      type: _Type.member,
      userId: 'USR-3302',
      time: '9:15 AM',
      text: 'Anyone knows why the lift is not working?',
    ),
    const _Item(
      day: 'Today',
      type: _Type.member,
      userId: 'USR-1047',
      time: '9:22 AM',
      text: 'Technician is checking it now',
      replyAuthor: 'USR-3302',
      replyText: 'Anyone knows why the lift is not working?',
    ),
    const _Item(
      day: 'Today',
      type: _Type.report,
      userId: 'USR-2218',
      time: '10:05 AM',
      reportTitle: 'Plumbing Report',
      reportIcon: Icons.plumbing_rounded,
      text: 'Water leakage near the main entrance',
      status: _Status.inProgress,
    ),
    const _Item(
      day: 'Today',
      type: _Type.member,
      userId: _myId,
      time: '10:20 AM',
      text: 'Thanks for the update!',
    ),
  ];

  _Item? get _pinned {
    for (final i in _items.reversed) {
      if (i.isAdmin) return i;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final far = _scroll.position.maxScrollExtent - _scroll.offset > 200;
      if (far != _showJump) setState(() => _showJump = far);
    });
    // When the keyboard opens, keep the latest message visible.
    _composerFocus.addListener(() {
      if (_composerFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 320), () {
          if (mounted) _jumpToEnd();
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _jumpToEnd(animate: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _composerFocus.dispose();
    _scroll.dispose();
    _hold.dispose();
    super.dispose();
  }

  /// Closes the keyboard everywhere (taps, sheets, route changes).
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _jumpToEnd({bool animate = true}) {
    if (!_scroll.hasClients) return;
    final end = _scroll.position.maxScrollExtent;
    if (animate) {
      _scroll.animateTo(
        end,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(end);
    }
  }

  // ───────── Selection (WhatsApp style) ─────────
  bool get _selecting => _selected.isNotEmpty;

  // Only my own text messages. Image-only messages: delete and re-upload.
  // Image + text: only the text can be edited.
  bool get _canEdit {
    if (_selected.length != 1) return false;
    final i = _selected.first;
    return i.isMine &&
        i.type == _Type.member &&
        !i.deleted &&
        i.text.isNotEmpty;
  }

  void _toggleSelect(_Item item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(item)) _selected.add(item);
    });
  }

  void _onRowTap(_Item item) {
    if (_selecting) {
      _toggleSelect(item);
    } else {
      _dismissKeyboard();
    }
  }

  void _onRowLongPress(_Item item) {
    _dismissKeyboard();
    _toggleSelect(item);
  }

  void _clearSelection() {
    if (_selected.isEmpty) return;
    setState(_selected.clear);
  }

  Future<void> _copySelected() async {
    final texts = [
      for (final i in _items)
        if (_selected.contains(i) && !i.deleted && i.text.isNotEmpty) i.text,
    ];
    if (texts.isEmpty) {
      _toast('Nothing to copy');
      return;
    }
    await Clipboard.setData(ClipboardData(text: texts.join('\n')));
    if (!mounted) return;
    _clearSelection();
    _toast('Copied');
  }

  Future<void> _deleteSelected() async {
    final items = _selected.toList();

    // SOS alerts can never be deleted.
    if (items.any((i) => i.type == _Type.sos)) {
      _toast("SOS alerts can't be deleted");
      return;
    }

    // "Delete for everyone" only for my own, not already deleted.
    final canEveryone = items.every((i) => i.isMine && !i.deleted);

    final choice = await showDialog<_DeleteChoice>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) =>
          _DeleteDialog(count: items.length, canEveryone: canEveryone),
    );
    if (choice == null || !mounted) return;

    setState(() {
      for (final it in items) {
        if (choice == _DeleteChoice.everyone) {
          final i = _items.indexOf(it);
          if (i >= 0) _items[i] = it.copyWith(deleted: true);
        } else {
          _items.remove(it);
        }
        if (identical(_replyTo, it)) _replyTo = null;
        if (identical(_editing, it)) {
          _editing = null;
          _controller.clear();
        }
      }
      _selected.clear();
    });
  }

  void _startEdit() {
    final item = _selected.first;
    setState(() {
      _selected.clear();
      _replyTo = null;
      _editing = item;
    });
    _controller.text = item.text;
    _controller.selection = TextSelection.collapsed(offset: item.text.length);
    _composerFocus.requestFocus();
  }

  void _swipeReply(_Item item) {
    if (item.deleted) return;
    if (_editing != null) _cancelEdit();
    _setReply(item);
    _composerFocus.requestFocus();
  }

  void _cancelEdit() {
    setState(() => _editing = null);
    _controller.clear();
    _dismissKeyboard();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.title,
        ),
      );
  }

  // ───────── Tabs ─────────
  void _selectTab(int t) {
    if (t == _tab) return;
    _dismissKeyboard();
    setState(() {
      _selected.clear();
      _tab = t;
      if (t == 0 && _reportSubmitted) {
        _reportSubmitted = false;
        _reportKey = GlobalKey();
      }
    });
    if (t == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
    }
  }

  void _onReportSubmitted(ReportResult result) {
    setState(() {
      _reportSubmitted = true;
      _items.add(
        _Item(
          day: 'Today',
          type: _Type.report,
          userId: _myId,
          time: TimeOfDay.now().format(context),
          reportTitle: '${result.category} Report',
          reportIcon: result.icon,
          text: _clip(
            result.note.isEmpty
                ? result.issue
                : '${result.issue} ${result.note}',
          ),
          hasImage: result.photoPath != null,
          photoPath: result.photoPath,
          status: _Status.submitted,
          adminOnly: result.visibility == ReportVisibility.adminOnly,
        ),
      );
    });
  }

  // ───────── Sending ─────────
  void _addMine({String text = '', String? photoPath}) {
    setState(() {
      _items.add(
        _Item(
          day: 'Today',
          type: _Type.member,
          userId: _myId,
          time: TimeOfDay.now().format(context),
          text: _clip(text),
          hasImage: photoPath != null,
          photoPath: photoPath,
          replyAuthor: _replyTo?.displayName,
          replyText: _replyTo == null
              ? null
              : (_replyTo!.text.isNotEmpty ? _replyTo!.text : 'Photo'),
        ),
      );
      _replyTo = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final editing = _editing;
    if (editing != null) {
      final newText = _clip(text);
      final i = _items.indexOf(editing);
      setState(() {
        if (i >= 0 && newText != editing.text) {
          _items[i] = editing.copyWith(text: newText, edited: true);
        }
        _editing = null;
      });
      _controller.clear();
      _dismissKeyboard();
      return;
    }

    _addMine(text: text);
    _controller.clear();
    _dismissKeyboard();
  }

  /// Posts the SOS alert in the community chat once the popup closes.
  void _addSos() {
    setState(() {
      _items.add(
        _Item(
          day: 'Today',
          type: _Type.sos,
          userId: _myId,
          time: TimeOfDay.now().format(context),
          text: 'Needs urgent help',
        ),
      );
    });

    if (_tab != 0) {
      _selectTab(0); // also scrolls to the latest message
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
    }
  }

  // ───────── Attach: ONE icon → Camera / Gallery → preview + caption ─────────
  Future<void> _openAttachSheet() async {
    if (_editing != null) {
      _toast('Finish editing first');
      return;
    }
    _dismissKeyboard();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => const _AttachSheet(),
    );
    if (source == null || !mounted) return;
    await _pickFlow(source);
  }

  /// pick -> preview (caption, <=50 chars) -> send / retake (loops).
  Future<void> _pickFlow(ImageSource source) async {
    while (mounted) {
      _dismissKeyboard();
      XFile? picked;
      try {
        picked = await _picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1600,
        );
      } catch (_) {
        _toast(
          source == ImageSource.camera
              ? 'Could not open the camera'
              : 'Could not open the gallery',
        );
        return;
      }
      if (picked == null || !mounted) {
        _dismissKeyboard();
        return;
      }

      final path = picked.path;
      final result = await Navigator.of(context).push<_PreviewResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _ImagePreviewScreen(path: path, source: source),
        ),
      );
      // Flutter restores focus when a screen closes; cancel that here.
      _dismissKeyboard();
      if (result == null || !mounted) return;
      if (result.retake) continue;
      _addMine(text: result.caption, photoPath: path);
      return;
    }
  }

  void _setReply(_Item item) {
    HapticFeedback.selectionClick();
    setState(() => _replyTo = item);
  }

  Future<void> _sosSent() async {
    _dismissKeyboard();
    HapticFeedback.heavyImpact();
    _hold.reset();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => _Glass(
        radius: const BorderRadius.vertical(top: Radius.circular(32)),
        blur: 28,
        opacity: 0.82,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.slate.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_Tone.mint, AppColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SOS alert sent',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.25),
                ),
              ),
              child: const Text(
                'Sent with your ID: $_myId',
                style: TextStyle(
                  color: AppColors.brandDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            for (final r in const [
              (Icons.admin_panel_settings_rounded, 'Community Admin'),
              (Icons.shield_rounded, 'Security'),
              (Icons.groups_rounded, 'Emergency Responders'),
            ])
              _Glass(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                radius: BorderRadius.circular(18),
                blur: 0,
                opacity: 0.55,
                shadow: false,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.slate.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(r.$1, size: 18, color: AppColors.slate),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        r.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.title,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.done_all_rounded,
                      size: 18,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    _addSos();
  }

  Widget _buildChatTab() {
    final pinned = _pinned;
    return Column(
      children: [
        if (pinned != null && _pinnedVisible)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _PinnedBar(
              text: pinned.text,
              onClose: () => setState(() => _pinnedVisible = false),
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scroll,
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < _items.length; i++) ...[
                      if (i == 0 || _items[i].day != _items[i - 1].day)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: _DayChip(label: _items[i].day),
                        ),
                      _MessageRow(
                        item: _items[i],
                        selected: _selected.contains(_items[i]),
                        selecting: _selecting,
                        onTap: () => _onRowTap(_items[i]),
                        onLongPress: () => _onRowLongPress(_items[i]),
                        onReply: () => _swipeReply(_items[i]),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 8,
                child: AnimatedScale(
                  scale: _showJump ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: GestureDetector(
                    onTap: _jumpToEnd,
                    child: _Glass(
                      radius: const BorderRadius.all(Radius.circular(24)),
                      blur: 14,
                      opacity: 0.78,
                      shadowColor: AppColors.brand,
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_editing != null)
          _ReplyPreview(
            item: _editing!,
            title: 'Edit message',
            onClose: _cancelEdit,
          )
        else if (_replyTo != null)
          _ReplyPreview(
            item: _replyTo!,
            onClose: () => setState(() => _replyTo = null),
          ),
        _Composer(
          controller: _controller,
          focusNode: _composerFocus,
          onSend: _sendText,
          onAttach: _openAttachSheet,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: _tab == 0 && _selected.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selected.isNotEmpty) {
          _clearSelection();
          return;
        }
        final handled = _reportKey.currentState?.handleBack() ?? false;
        if (!handled) _selectTab(0);
      },
      // Tapping empty space anywhere closes the keyboard.
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: Scaffold(
          backgroundColor: const Color(0xFFEAF4F1),
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: _HomeBackdrop(
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _selecting
                            ? KeyedSubtree(
                                key: const ValueKey('sel'),

                                child: _SelectionBar(
                                  count: _selected.length,
                                  onBack: _clearSelection,
                                  onCopy: _copySelected,
                                  onDelete: _deleteSelected,
                                  onEdit: _canEdit ? _startEdit : null,
                                ),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('hdr'),
                                child: _Header(
                                  onNotifications: () {
                                    _dismissKeyboard();
                                    Navigator.pushNamed(
                                      context,
                                      AppRouter.notifications,
                                    ).then((_) => _dismissKeyboard());
                                  },
                                  onProfile: () {
                                    _dismissKeyboard();
                                    Navigator.pushNamed(
                                      context,
                                      AppRouter.profile,
                                    ).then((_) => _dismissKeyboard());
                                  },
                                ),
                              ),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _tab,
                          sizing: StackFit.expand,
                          children: [
                            _buildChatTab(),
                            ReportIssueView(
                              key: _reportKey,
                              onSubmitted: _onReportSubmitted,
                              onExit: () => _selectTab(0),
                            ),
                          ],
                        ),
                      ),
                      if (!keyboardOpen)
                        _BottomNav(
                          hold: _hold,
                          tab: _tab,
                          onHome: () => _selectTab(0),
                          onReport: () => _selectTab(1),
                        ),
                    ],
                  ),
                ),
              ),
              _SosHoldOverlay(hold: _hold),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Attach sheet (Camera / Gallery) ─────────────────────────
class _AttachSheet extends StatelessWidget {
  const _AttachSheet();

  @override
  Widget build(BuildContext context) {
    Widget option(IconData icon, String label, ImageSource source) {
      return ListTile(
        leading: Icon(icon, color: AppColors.brand),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.title,
          ),
        ),
        onTap: () => Navigator.pop(context, source),
      );
    }

    return Glass(
      radius: const BorderRadius.vertical(top: Radius.circular(30)),
      blur: 28,
      opacity: 0.80,
      shadow: false,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              option(
                Icons.photo_camera_outlined,
                'Take a photo',
                ImageSource.camera,
              ),
              option(
                Icons.photo_library_outlined,
                'Choose from gallery',
                ImageSource.gallery,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD2F3E9),
                  Color(0xFFE3EEFA),
                  Color(0xFFEFEBFA),
                  Color(0xFFF1F6F4),
                ],
                stops: [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.55,
            child: Image.asset(
              AssetConstants.background,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        const Positioned(
          top: -90,
          left: -70,
          child: _Blob(color: AppColors.brand, size: 300, alpha: 0.38),
        ),
        const Positioned(
          top: 120,
          right: -80,
          child: _Blob(color: _Tone.sun, size: 220, alpha: 0.20),
        ),
        const Positioned(
          top: 300,
          right: -110,
          child: _Blob(color: AppColors.violet, size: 280, alpha: 0.24),
        ),
        const Positioned(
          bottom: 90,
          left: -90,
          child: _Blob(color: AppColors.cyan, size: 320, alpha: 0.30),
        ),
        const Positioned(
          bottom: -60,
          right: -60,
          child: _Blob(color: _Tone.coral, size: 220, alpha: 0.16),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

// ───────────────────────── Image preview + caption screen ─────────────────────────
class _PreviewResult {
  const _PreviewResult({this.caption = '', this.retake = false});
  final String caption;
  final bool retake;
}

class _ImagePreviewScreen extends StatefulWidget {
  const _ImagePreviewScreen({required this.path, required this.source});
  final String path;
  final ImageSource source;

  @override
  State<_ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<_ImagePreviewScreen> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _send() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, _PreviewResult(caption: _caption.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final camera = widget.source == ImageSource.camera;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF4F1),
        resizeToAvoidBottomInset: true,
        body: _HomeBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: _Glass(
                          radius: BorderRadius.circular(22),
                          blur: 14,
                          opacity: 0.60,
                          shadow: false,
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.title,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(
                          context,
                          const _PreviewResult(retake: true),
                        ),
                        child: _Glass(
                          radius: BorderRadius.circular(22),
                          blur: 14,
                          opacity: 0.60,
                          shadow: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                camera
                                    ? Icons.refresh_rounded
                                    : Icons.photo_library_outlined,
                                size: 18,
                                color: AppColors.brand,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                camera ? 'Retake' : 'Choose another',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brand,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: _Glass(
                      radius: BorderRadius.circular(26),
                      blur: 0,
                      opacity: 0.50,
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: Image.file(
                              File(widget.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: _caption,
                  builder: (context, _) {
                    final count = _caption.text.length;
                    final low = _maxChars - count <= 10;
                    return _Glass(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      padding: const EdgeInsets.fromLTRB(18, 3, 5, 3),
                      radius: BorderRadius.circular(30),
                      blur: 20,
                      opacity: 0.62,
                      shadowColor: count > 0 ? AppColors.brand : null,
                      borderColor: count > 0
                          ? AppColors.brand.withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.85),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _caption,
                              maxLength: _maxChars,
                              maxLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              cursorColor: AppColors.brand,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: AppColors.title,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Add a message…',
                                hintStyle: TextStyle(
                                  color: AppColors.hint,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                            ),
                          ),
                          if (count > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '$count/$_maxChars',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: low ? AppColors.error : AppColors.hint,
                                ),
                              ),
                            ),
                          _SendOrb(onTap: _send),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SendOrb extends StatelessWidget {
  const _SendOrb({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_Tone.mint, AppColors.brand, AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.onNotifications, required this.onProfile});
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return _Glass(
      radius: const BorderRadius.vertical(bottom: Radius.circular(0)),
      blur: 28,
      opacity: 0.66,
      tint: const Color(0xFFF1FBF8),
      borderOpacity: 0.95,
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_Tone.mint, AppColors.brand, AppColors.brandDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.40),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 3,
                  left: 5,
                  right: 5,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.groups_rounded, color: Colors.white, size: 25),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  _communityName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.title,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.fromLTRB(7, 2, 9, 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 13,
                        color: AppColors.brandDark,
                      ),
                      SizedBox(width: 5),
                      Text(
                        '$_memberCount members',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: NotificationStore.instance,
            builder: (_, _) => _HeaderIcon(
              icon: Icons.notifications_none_rounded,
              badgeCount: NotificationStore.instance.unreadCount,
              onTap: onNotifications,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onProfile,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.brand,
                    _Tone.sky,
                    _Tone.lilac,
                    AppColors.brand,
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.brand.withValues(alpha: 0.14),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.brandDark,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.55),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: AppColors.title, size: 24),
            if (badgeCount > 0)
              Positioned(
                right: -2,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_Tone.coral, AppColors.error],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinnedBar extends StatelessWidget {
  const _PinnedBar({required this.text, required this.onClose});
  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      radius: BorderRadius.circular(18),
      blur: 16,
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.info.withValues(alpha: 0.20),
          Colors.white.withValues(alpha: 0.50),
        ],
      ),
      borderColor: AppColors.info.withValues(alpha: 0.35),
      shadow: false,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_Tone.sky, AppColors.info],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.push_pin_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latest from Admin',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.info,
                  ),
                ),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.title,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Feed ─────────────────────────
class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    Widget line(bool left) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: left ? Alignment.centerLeft : Alignment.centerRight,
            end: left ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              AppColors.slate.withValues(alpha: 0),
              AppColors.slate.withValues(alpha: 0.22),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          line(true),
          _Glass(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            radius: BorderRadius.circular(20),
            blur: 0,
            opacity: 0.70,
            shadow: false,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.slate,
              ),
            ),
          ),
          line(false),
        ],
      ),
    );
  }
}

/// Every message (mine and others') carries its own avatar.
/// Mine → right side, green. Others → left side, coloured by user ID.
class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.item,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
    required this.onReply,
  });
  final _Item item;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final mine = item.isMine;
    final maxW = MediaQuery.of(context).size.width * 0.72;
    final avatar = _Avatar(item: item);

    final Widget content = item.deleted
        ? _DeletedBubble(item: item)
        : switch (item.type) {
            _Type.report => _ReportCard(item: item),
            _Type.sos => _SosCard(item: item),
            _ => _Bubble(item: item),
          };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: selected
            ? AppColors.brand.withValues(alpha: 0.20)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: _SwipeToReply(
          enabled: !selecting && !item.deleted,
          onReply: onReply,
          child: Row(
            mainAxisAlignment: mine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine) avatar,
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: content,
                ),
              ),
              if (mine) avatar,
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({
    required this.enabled,
    required this.onReply,
    required this.child,
  });
  final bool enabled;
  final VoidCallback onReply;
  final Widget child;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  static const double _trigger = 64;

  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  double _dx = 0;
  double _from = 0;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _back.addListener(() {
      setState(
        () => _dx = _from * (1 - Curves.easeOut.transform(_back.value)),
      );
    });
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _start(DragStartDetails _) => _back.stop();

  void _update(DragUpdateDetails d) {
  if (!widget.enabled) return;

  // Left to right only.
  final next = (_dx + d.delta.dx).clamp(0.0, _trigger * 1.25);

  if (!_fired && next >= _trigger) {
    _fired = true;
    HapticFeedback.selectionClick();
  }

  setState(() => _dx = next);
}

  void _end([DragEndDetails? _]) {
  if (_fired) widget.onReply();

  _fired = false;
  _from = _dx;
  _back.forward(from: 0);
}

  @override
  Widget build(BuildContext context) {
final p = (_dx / _trigger).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _start,
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: _end,
      onHorizontalDragCancel: _end,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: p,
                child: Transform.scale(
                  scale: 0.6 + 0.4 * p,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brand.withValues(alpha: 0.16),
                      border: Border.all(
                        color: AppColors.brand.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      size: 19,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}
// ───────────────────────── Selection bar ─────────────────────────
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onBack,
    required this.onCopy,
    required this.onDelete,
    this.onEdit,
  });
  final int count;
  final VoidCallback onBack;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  Future<void> _openMenu(BuildContext context) async {
    final top = MediaQuery.of(context).padding.top;

    final picked = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.black.withValues(alpha: 0.10),
      transitionDuration: const Duration(milliseconds: 170),
      pageBuilder: (ctx, _, _) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(top: top + 58, right: 12),
          child: Material(
            type: MaterialType.transparency,
            child: _GlassMenu(
              items: const [
                _GlassMenuItem(
                  value: 'edit',
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            alignment: Alignment.topRight,
            scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (picked == 'edit') onEdit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return _Glass(
      radius: BorderRadius.zero,
      blur: 28,
      opacity: 0.66,
      tint: const Color(0xFFF1FBF8),
      borderOpacity: 0.95,
      padding: EdgeInsets.fromLTRB(8, top + 10, 8, 12),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.title,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onCopy,
              icon: const Icon(
                Icons.content_copy_rounded,
                size: 21,
                color: AppColors.title,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.title,
              ),
            ),
            if (onEdit != null)
              IconButton(
                onPressed: () => _openMenu(context),
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.title,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassMenuItem {
  const _GlassMenuItem({
    required this.value,
    required this.icon,
    required this.label,
  });
  final String value;
  final IconData icon;
  final String label;
}

class _GlassMenu extends StatelessWidget {
  const _GlassMenu({required this.items});
  final List<_GlassMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 170),
      child: IntrinsicWidth(
        child: _Glass(
          radius: BorderRadius.circular(20),
          blur: 24,
          opacity: 0.88,
          tint: const Color(0xFFF1FBF8),
          shadowColor: AppColors.brand,
          borderOpacity: 0.95,
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final it in items)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(context, it.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brand.withValues(alpha: 0.12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Icon(
                            it.icon,
                            size: 18,
                            color: AppColors.brand,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            it.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.title,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Delete dialog ─────────────────────────
class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.count, required this.canEveryone});
  final int count;
  final bool canEveryone;

  @override
  Widget build(BuildContext context) {
    Widget action(String label, Color color, _DeleteChoice? value) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(context, value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: _Glass(
        radius: BorderRadius.circular(26),
        blur: 28,
        opacity: 0.85,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                count == 1 ? 'Delete message?' : 'Delete $count messages?',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),
            ),
            if (canEveryone)
              action(
                'Delete for everyone',
                AppColors.error,
                _DeleteChoice.everyone,
              ),
            action('Delete for me', AppColors.error, _DeleteChoice.me),
            action('Cancel', AppColors.brand, null),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Deleted message ─────────────────────────
class _DeletedBubble extends StatelessWidget {
  const _DeletedBubble({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      blur: 0,
      shadow: false,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            AppColors.brand.withValues(alpha: 0.16),
            Colors.white,
          ).withValues(alpha: 0.85),
          Color.alphaBlend(
            AppColors.brand.withValues(alpha: 0.08),
            Colors.white,
          ).withValues(alpha: 0.65),
        ],
      ),
      borderColor: AppColors.brand.withValues(alpha: 0.25),
      radius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, size: 15, color: AppColors.hint),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'You deleted this message',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.body,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.time,
              style: const TextStyle(fontSize: 10.5, color: AppColors.hint),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosCard extends StatelessWidget {
  const _SosCard({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.error;

    Widget team(IconData icon, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.title,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.check_rounded, size: 12, color: AppColors.brand),
        ],
      );
    }

    return _Glass(
      radius: BorderRadius.circular(24),
      blur: 0,
      opacity: 0.68,
      shadowColor: accent,
      borderColor: accent.withValues(alpha: 0.40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (same structure as the report card).
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  accent.withValues(alpha: 0.20),
                  accent.withValues(alpha: 0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: accent.withValues(alpha: 0.15)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withValues(alpha: 0.80), accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'SOS Alert',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_rounded, size: 12, color: accent),
                      SizedBox(width: 4),
                      Text(
                        'Everyone',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.text,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.38,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      team(Icons.admin_panel_settings_rounded, 'Admin'),
                      const SizedBox(height: 8),
                      team(Icons.shield_rounded, 'Security'),
                      const SizedBox(height: 8),
                      team(Icons.groups_rounded, 'Responders'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Alert sent to the community',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.hint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    final mine = item.isMine;
    final color = item.isAdmin
        ? AppColors.info
        : (mine ? AppColors.brand : AppColors.slate);
    final Widget inner = item.isAdmin
        ? Icon(Icons.campaign_rounded, size: 19, color: color)
        : mine
        ? Icon(Icons.person_rounded, size: 19, color: color)
        : Text(
            _avatarLabel(item.userId),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: color,
            ),
          );

    return Container(
      width: 36,
      height: 36,
      margin: EdgeInsets.only(left: mine ? 8 : 0, right: mine ? 0 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.32),
            color.withValues(alpha: 0.12),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: inner,
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        ),
        child: Image.file(
          File(path!),
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      height: 140,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.26),
            _Tone.lilac.withValues(alpha: 0.16),
            AppColors.brand.withValues(alpha: 0.16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: const Icon(Icons.image_rounded, size: 38, color: AppColors.slate),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({
    required this.author,
    required this.text,
    required this.onDark,
  });
  final String author;
  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final accent = onDark ? Colors.white : AppColors.brand;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.20)
            : AppColors.brand.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            author,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: onDark ? Colors.white70 : AppColors.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    final mine = item.isMine;
    final isAdmin = item.isAdmin;
    final accent = isAdmin ? AppColors.info : AppColors.slate;
    final fg = mine ? Colors.white : AppColors.title;

    // mine -> solid green | admin -> blue glass | everyone else -> white glass
    final Gradient gradient = mine
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF000B38F), Color(0xF0287B6D)],
          )
        : isAdmin
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                AppColors.info.withValues(alpha: 0.24),
                Colors.white,
              ).withValues(alpha: 0.90),
              Color.alphaBlend(
                AppColors.info.withValues(alpha: 0.10),
                Colors.white,
              ).withValues(alpha: 0.65),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.92),
              Colors.white.withValues(alpha: 0.68),
            ],
          );

    return _Glass(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
      blur: 0,
      gradient: gradient,
      shadow: mine,
      shadowColor: mine ? AppColors.brand : null,
      borderColor: mine
          ? Colors.white.withValues(alpha: 0.45)
          : accent.withValues(alpha: isAdmin ? 0.40 : 0.22),
      radius: BorderRadius.only(
        topLeft: Radius.circular(mine ? 20 : 5),
        topRight: Radius.circular(mine ? 5 : 20),
        bottomLeft: const Radius.circular(20),
        bottomRight: const Radius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin) ...[
                  const Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    item.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: mine ? Colors.white70 : accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item.replyText != null)
            _QuoteBlock(
              author: item.replyAuthor ?? '',
              text: item.replyText!,
              onDark: mine,
            ),
          if (item.hasImage) _ImageBlock(path: item.photoPath),
          if (item.text.isNotEmpty)
            Text(
              item.text,
              style: TextStyle(fontSize: 14.5, height: 1.38, color: fg),
            ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.edited) ...[
                  Text(
                    'Edited',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: mine ? Colors.white70 : AppColors.hint,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                Text(
                  item.time,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: mine ? Colors.white70 : AppColors.hint,
                  ),
                ),

                if (mine) ...[
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    final accent = item.isMine ? AppColors.brand : AppColors.violet;
    final status = item.status!;

    return _Glass(
      radius: BorderRadius.circular(24),
      blur: 0,
      opacity: 0.68,
      shadowColor: accent,
      borderColor: accent.withValues(alpha: 0.40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  accent.withValues(alpha: 0.20),
                  accent.withValues(alpha: 0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: accent.withValues(alpha: 0.15)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withValues(alpha: 0.80), accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(item.reportIcon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    item.reportTitle ?? 'Report',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.adminOnly
                            ? Icons.lock_rounded
                            : Icons.groups_rounded,
                        size: 12,
                        color: accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.adminOnly ? 'Admin only' : 'Everyone',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                if (item.hasImage) _ImageBlock(path: item.photoPath),
                Text(
                  item.text,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.38,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  child: _StatusStepper(status: status),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (item.adminOnly)
                      Expanded(
                        child: Text(
                          item.isMine
                              ? 'Only you and admin can see this'
                              : 'Visible to admin only',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.hint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.status});
  final _Status status;

  @override
  Widget build(BuildContext context) {
    final steps = _Status.values;
    final idx = status.index;
    final color = status.color;

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  gradient: i <= idx
                      ? LinearGradient(
                          colors: [color.withValues(alpha: 0.75), color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: i <= idx ? null : Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i <= idx
                        ? Colors.white
                        : AppColors.border.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: i == idx
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.55),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: i <= idx
                    ? const Icon(Icons.check, size: 9, color: Colors.white)
                    : null,
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i < idx
                          ? color
                          : AppColors.border.withValues(alpha: 0.20),
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final s in steps)
              Text(
                s.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: s == status ? FontWeight.w800 : FontWeight.w500,
                  color: s == status ? color : AppColors.hint,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────── Composer ─────────────────────────
class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.item, required this.onClose, this.title});
  final _Item item;
  final VoidCallback onClose;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      radius: const BorderRadius.vertical(top: Radius.circular(20)),
      blur: 16,
      opacity: 0.68,
      shadow: false,
      child: Container(
        decoration: BoxDecoration(
          border: const Border(
            left: BorderSide(color: AppColors.brand, width: 4),
          ),
          gradient: LinearGradient(
            colors: [
              AppColors.brand.withValues(alpha: 0.10),
              AppColors.brand.withValues(alpha: 0),
            ],
          ),
        ),
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Replying to ${item.displayName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand,
                    ),
                  ),
                  Text(
                    item.text.isEmpty ? 'Photo' : item.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.body,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final count = controller.text.length;
        final hasText = controller.text.trim().isNotEmpty;
        final low = _maxChars - count <= 10;

        return _Glass(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
          radius: BorderRadius.circular(30),
          blur: 20,
          opacity: 0.62,
          shadowColor: hasText ? AppColors.brand : null,
          borderColor: hasText
              ? AppColors.brand.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.85),
          child: Row(
            children: [
              IconButton(
                onPressed: onAttach,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brand.withValues(alpha: 0.12),
                ),
                icon: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: AppColors.brandDark,
                  size: 23,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLength: _maxChars,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  onTapOutside: (_) => focusNode.unfocus(),
                  cursorColor: AppColors.brand,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.title,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Message (max 50 characters)',
                    hintStyle: TextStyle(color: AppColors.hint, fontSize: 14),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (low ? AppColors.error : AppColors.slate).withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count/$_maxChars',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: low ? AppColors.error : AppColors.hint,
                    ),
                  ),
                ),
              AnimatedScale(
                scale: hasText ? 1 : 0.85,
                duration: const Duration(milliseconds: 160),
                child: Opacity(
                  opacity: hasText ? 1 : 0.45,
                  child: _SendOrb(onTap: hasText ? onSend : () {}),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── Bottom nav: Home | SOS | Report ─────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.hold,
    required this.tab,
    required this.onHome,
    required this.onReport,
  });
  final AnimationController hold;
  final int tab;
  final VoidCallback onHome;
  final VoidCallback onReport;

  static const double _barHeight = 100;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _Glass(
            radius: const BorderRadius.vertical(top: Radius.circular(28)),
            blur: 28,
            opacity: 0.66,
            tint: const Color(0xFFF1FBF8),
            borderOpacity: 0.95,
            child: Container(
              height: _barHeight,
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(37),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Home',
                        selected: tab == 0,
                        onTap: onHome,
                      ),
                    ),
                    const Expanded(child: SizedBox()), // space for SOS
                    Expanded(
                      child: _NavItem(
                        icon: Icons.description_outlined,
                        label: 'Report',
                        selected: tab == 1,
                        onTap: onReport,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -17,
            left: 0,
            right: 0,
            child: Center(child: _SosButton(hold: hold)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brandDark : AppColors.body;
    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.brand.withValues(alpha: 0.14),
                      AppColors.brand.withValues(alpha: 0.03),
                    ],
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.brand.withValues(alpha: 0.18)
                      : AppColors.slate.withValues(alpha: 0.06),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.brand.withValues(alpha: 0.40),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: color,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(top: 2),
                width: selected ? 14 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosButton extends StatefulWidget {
  const _SosButton({required this.hold});
  final AnimationController hold;

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hold = widget.hold;
    return Listener(
      onPointerDown: (_) {
        HapticFeedback.mediumImpact();
        hold.forward(from: 0);
      },
      onPointerUp: (_) {
        if (hold.status != AnimationStatus.completed) hold.reset();
      },
      onPointerCancel: (_) => hold.reset(),
      child: AnimatedBuilder(
        animation: Listenable.merge([hold, _pulse]),
        builder: (_, _) {
          final holding = hold.value > 0;
          final t = _pulse.value;
          return SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.error.withValues(alpha: 0.26),
                        AppColors.error.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.06),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 80 + 22 * t,
                  height: 80 + 22 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35 * (1 - t)),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.28),
                      width: 1.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: hold.value,
                    strokeWidth: 4,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                AnimatedScale(
                  scale: holding ? 0.93 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.25, -0.5),
                        radius: 1.0,
                        colors: [
                          Color(0xFFFF5252),
                          Color(0xFFE41B1B),
                          Color(0xFFC20F0F),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.55),
                          blurRadius: 22,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          child: Container(
                            width: 38,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.45),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SosHoldOverlay extends StatelessWidget {
  const _SosHoldOverlay({required this.hold});
  final AnimationController hold;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: hold,
          builder: (_, _) {
            if (hold.value == 0) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.error.withValues(alpha: 0.30 * hold.value),
                    AppColors.error.withValues(alpha: 0.55 * hold.value),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(3 - hold.value * 3).ceil()}',
                    style: const TextStyle(
                      fontSize: 84,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const Text(
                    'Keep holding to send SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
