import 'dart:io';
import 'dart:ui';

import 'package:community/app/app_router.dart';
import 'package:community/core/constants/asset_constants.dart';
import 'package:community/core/theme/app_colors.dart';
import 'package:community/core/widgets/app_skeleton.dart';
import 'package:community/core/widgets/glass_morphism.dart';
import 'package:community/features/notifications/presentation/screens/notifications_screen.dart';
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

const int _maxChars = 50;
const String _myId = '201';
const String _communityName = 'Green Valley Community';
const int _memberCount = 30;
final List<String> _memberRooms = List.generate(
  _memberCount,
  (i) => '${i ~/ 6 + 1}0${i % 6 + 1}',
);

String _clip(String s) =>
    s.length <= _maxChars ? s : '${s.substring(0, _maxChars - 1)}…';

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
  final String userId;
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
      isAdmin ? 'Community Admin' : (isMine ? 'You' : 'Room $userId');
}

Widget _glass({
  required Widget child,
  BorderRadius radius = const BorderRadius.all(Radius.circular(22)),
  double blur = 16,
  double opacity = 0.55,
  Color? tint,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  Color? borderColor,
  double borderOpacity = 0.75,
  bool shadow = true,
  Color? shadowColor,
  Gradient? gradient,
}) {
  final base = tint ?? AppColors.kwhite;

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
                color: (shadowColor ?? AppColors.glassShadow).withValues(
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

Widget _blob({
  required Color color,
  required double size,
  double alpha = 0.35,
}) {
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
  final Set<_Item> _selected = {};

  bool _showJump = false;
  bool _pinnedVisible = true;
  _Item? _replyTo;
  _Item? _editing;
  int _tab = 0;
  GlobalKey<ReportIssueViewState> _reportKey = GlobalKey();
  bool _reportSubmitted = false;

  bool _loading = true;

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);
    _scrollToEnd();
  }

  late final AnimationController _hold =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _sosSent();
        });

  final List<_Item> _items = [
    const _Item(
      day: 'Yesterday',
      type: _Type.member,
      userId: '305',
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
      userId: '214',
      time: '9:30 AM',
      text: 'ലിഫ്റ്റ് ഇന്ന് ശരിയാകുമോ?',
    ),
    const _Item(
      day: 'Today',
      type: _Type.member,
      userId: '118',
      time: '9:22 AM',
      text: 'Technician is checking it now',
      replyAuthor: 'Room 214',
      replyText: 'Anyone knows why the lift is not working?',
    ),
    const _Item(
      day: 'Today',
      type: _Type.report,
      userId: '507',
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
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _composerFocus.dispose();
    _scroll.dispose();
    _hold.dispose();
    super.dispose();
  }

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

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _jumpToEnd(animate: false),
    );
    for (final ms in const [150, 400]) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted && _tab == 0) _jumpToEnd(animate: false);
      });
    }
  }

  bool get _selecting => _selected.isNotEmpty;

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

    final canEveryone = items.every((i) => i.isMine && !i.deleted);
    final choice = await showDialog<_DeleteChoice>(
      context: context,
      barrierColor: AppColors.kblack.withValues(alpha: 0.25),
      builder: (ctx) =>
          _deleteDialog(ctx, count: items.length, canEveryone: canEveryone),
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
    if (t == 0) _scrollToEnd();
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
    _scrollToEnd();
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
      _selectTab(0);
    } else {
      _scrollToEnd();
    }
  }

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
      barrierColor: AppColors.kblack.withValues(alpha: 0.25),
      builder: (ctx) => _attachSheet(ctx),
    );
    if (source == null || !mounted) return;
    await _pickFlow(source);
  }

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
      barrierColor: AppColors.kblack.withValues(alpha: 0.25),
      builder: (_) => _glass(
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
                  colors: [AppColors.mint, AppColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.kwhite, width: 3),
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
                color: AppColors.kwhite,
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
                'Sent from Room $_myId',
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
              _glass(
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
        if (!_loading && pinned != null && _pinnedVisible)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _pinnedBar(
              text: pinned.text,
              onClose: () => setState(() => _pinnedVisible = false),
            ),
          ),
        Expanded(
          child: SkeletonSwitcher(
            loading: _loading,
            skeleton: const SkeletonChatList(),
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
                            child: _dayChip(label: _items[i].day),
                          ),
                        _messageRow(
                          context,
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
                      child: _glass(
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
        ),
        if (_editing != null)
          _replyPreview(
            item: _editing!,
            title: 'Edit message',
            onClose: _cancelEdit,
          )
        else if (_replyTo != null)
          _replyPreview(
            item: _replyTo!,
            onClose: () => setState(() => _replyTo = null),
          ),
        IgnorePointer(
          ignoring: _loading,
          child: Opacity(
            opacity: _loading ? 0.5 : 1,
            child: _composer(
              controller: _controller,
              focusNode: _composerFocus,
              onSend: _sendText,
              onAttach: _openAttachSheet,
            ),
          ),
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
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: Scaffold(
          backgroundColor: const Color(0xFFEAF4F1),
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: _homeBackdrop(
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _selecting
                            ? KeyedSubtree(
                                key: const ValueKey('sel'),

                                child: _selectionBar(
                                  context,
                                  count: _selected.length,
                                  onBack: _clearSelection,
                                  onCopy: _copySelected,
                                  onDelete: _deleteSelected,
                                  onEdit: _canEdit ? _startEdit : null,
                                ),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('hdr'),
                                child: _header(
                                  context,
                                  onMembers: () {
                                    _dismissKeyboard();
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const _MembersScreen(),
                                          ),
                                        )
                                        .then((_) => _dismissKeyboard());
                                  },

                                  onNotifications: () {
                                    _dismissKeyboard();

                                    Navigator.pushNamed(
                                      context,
                                      AppRouter.notifications,
                                    );
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
                        _bottomNav(
                          hold: _hold,
                          tab: _tab,
                          onHome: () => _selectTab(0),
                          onReport: () => _selectTab(1),
                        ),
                    ],
                  ),
                ),
              ),
              _sosHoldOverlay(hold: _hold),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _attachSheet(BuildContext context) {
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

Widget _homeBackdrop({required Widget child}) {
  return Stack(
    children: [
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.homeGradientStart,
                AppColors.homeGradientBlue,
                AppColors.homeGradientPurple,
                AppColors.homeGradientEnd,
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
      Positioned(
        top: -90,
        left: -70,
        child: _blob(color: AppColors.brand, size: 300, alpha: 0.38),
      ),
      Positioned(
        top: 120,
        right: -80,
        child: _blob(color: AppColors.sun, size: 220, alpha: 0.20),
      ),
      Positioned(
        top: 300,
        right: -110,
        child: _blob(color: AppColors.violet, size: 280, alpha: 0.24),
      ),
      Positioned(
        bottom: 90,
        left: -90,
        child: _blob(color: AppColors.cyan, size: 320, alpha: 0.30),
      ),
      Positioned(
        bottom: -60,
        right: -60,
        child: _blob(color: AppColors.coral, size: 220, alpha: 0.16),
      ),
      Positioned.fill(child: child),
    ],
  );
}

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
        body: _homeBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: _glass(
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
                        child: _glass(
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
                    child: _glass(
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
                    return _glass(
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
                          _sendOrb(onTap: _send),
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

Widget _sendOrb({required VoidCallback onTap}) {
  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.mint, AppColors.brand, AppColors.brandDark],
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
      icon: const Icon(Icons.send_rounded, color: AppColors.kwhite, size: 20),
    ),
  );
}

Widget _header(
  BuildContext context, {
  required VoidCallback onNotifications,
  required VoidCallback onProfile,
  required VoidCallback onMembers,
}) {
  final top = MediaQuery.of(context).padding.top;

  return _glass(
    radius: const BorderRadius.vertical(bottom: Radius.circular(0)),
    blur: 28,
    opacity: 0.66,
    tint: AppColors.headerTint,
    borderOpacity: 0.95,
    padding: EdgeInsets.fromLTRB(16, top + 10, 16, 12),
    child: Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onMembers,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.mint,
                        AppColors.brand,
                        AppColors.brandDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.kwhite.withValues(alpha: 0.7),
                    ),
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
                      const Icon(
                        Icons.groups_rounded,
                        color: AppColors.kwhite,

                        size: 25,
                      ),
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
              ],
            ),
          ),
        ),
        ListenableBuilder(
          listenable: NotificationStore.instance,
          builder: (_, _) => _headerIcon(
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
                  AppColors.sky,
                  AppColors.lilac,
                  AppColors.brand,
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kwhite,
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

Widget _headerIcon({
  required IconData icon,
  required VoidCallback onTap,
  int badgeCount = 0,
}) {
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
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.coral, AppColors.error],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.kwhite, width: 1.5),
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: AppColors.kwhite,
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

Widget _pinnedBar({required String text, required VoidCallback onClose}) {
  return _glass(
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
              colors: [AppColors.sky, AppColors.info],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.push_pin_rounded,
            size: 14,
            color: AppColors.kwhite,
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
                style: const TextStyle(fontSize: 12.5, color: AppColors.title),
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

Widget _dayChip({required String label}) {
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
        _glass(
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

Widget _messageRow(
  BuildContext context, {
  required _Item item,
  required bool selected,
  required bool selecting,
  required VoidCallback onTap,
  required VoidCallback onLongPress,
  required VoidCallback onReply,
}) {
  final mine = item.isMine;
  final maxW = MediaQuery.of(context).size.width * 0.72;
  final avatar = _avatar(item: item);

  final Widget content = item.deleted
      ? _deletedBubble(item: item)
      : switch (item.type) {
          _Type.report => _reportCard(item: item),
          _Type.sos => _sosCard(item: item),
          _ => _bubble(item: item),
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
      setState(() => _dx = _from * (1 - Curves.easeOut.transform(_back.value)));
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

Future<void> _openSelectionMenu(
  BuildContext context,
  VoidCallback? onEdit,
) async {
  final top = MediaQuery.of(context).padding.top;

  final picked = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Menu',
    barrierColor: AppColors.kblack.withValues(alpha: 0.10),
    transitionDuration: const Duration(milliseconds: 170),
    pageBuilder: (ctx, _, _) => Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(top: top + 58, right: 12),
        child: Material(
          type: MaterialType.transparency,
          child: _glassMenu(
            ctx,
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
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
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

Widget _selectionBar(
  BuildContext context, {
  required int count,
  required VoidCallback onBack,
  required VoidCallback onCopy,
  required VoidCallback onDelete,
  VoidCallback? onEdit,
}) {
  final top = MediaQuery.of(context).padding.top;

  return _glass(
    radius: BorderRadius.zero,
    blur: 28,
    opacity: 0.66,
    tint: AppColors.headerTint,
    borderOpacity: 0.95,
    padding: EdgeInsets.fromLTRB(8, top + 10, 8, 12),
    child: SizedBox(
      height: 46,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.title),
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
              onPressed: () => _openSelectionMenu(context, onEdit),
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.title),
            ),
        ],
      ),
    ),
  );
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

Widget _glassMenu(BuildContext context, {required List<_GlassMenuItem> items}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 170),
    child: IntrinsicWidth(
      child: _glass(
        radius: BorderRadius.circular(20),
        blur: 24,
        opacity: 0.88,
        tint: AppColors.headerTint,
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
                        child: Icon(it.icon, size: 18, color: AppColors.brand),
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

Widget _deleteDialog(
  BuildContext context, {
  required int count,
  required bool canEveryone,
}) {
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
    child: _glass(
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

Widget _deletedBubble({required _Item item}) {
  return _glass(
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

Widget _sosCard({required _Item item}) {
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

  return _glass(
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
                  color: AppColors.kwhite,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

Widget _avatar({required _Item item}) {
  final mine = item.isMine;
  final color = item.isAdmin
      ? AppColors.info
      : (mine ? AppColors.brand : AppColors.slate);
  final Widget inner = item.isAdmin
      ? Icon(Icons.campaign_rounded, size: 19, color: color)
      : mine
      ? Icon(Icons.person_rounded, size: 19, color: color)
      : Text(
          item.userId,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: item.userId.length > 3 ? 10.5 : 12.5,
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
        colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0.12)],
      ),
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.kwhite, width: 1.5),
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

Widget _imageBlock({String? path}) {
  if (path != null) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Image.file(
        File(path),
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
          AppColors.lilac.withValues(alpha: 0.16),
          AppColors.brand.withValues(alpha: 0.16),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.kwhite.withValues(alpha: 0.7)),
    ),
    child: const Icon(Icons.image_rounded, size: 38, color: AppColors.slate),
  );
}

Widget _quoteBlock({
  required String author,
  required String text,
  required bool onDark,
}) {
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

Widget _bubble({required _Item item}) {
  final mine = item.isMine;
  final isAdmin = item.isAdmin;
  final accent = isAdmin ? AppColors.info : AppColors.slate;
  final fg = mine ? Colors.white : AppColors.title;

  // mine -> solid green | admin -> blue glass | everyone else -> white glass
  final Gradient gradient = mine
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sosGradientStart, AppColors.sosGradientEnd],
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

  return _glass(
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
          _quoteBlock(
            author: item.replyAuthor ?? '',
            text: item.replyText!,
            onDark: mine,
          ),
        if (item.hasImage) _imageBlock(path: item.photoPath),
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

Widget _reportCard({required _Item item}) {
  final accent = item.isMine ? AppColors.brand : AppColors.violet;
  final status = item.status!;

  return _glass(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              if (item.hasImage) _imageBlock(path: item.photoPath),
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
                child: _statusStepper(status: status),
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

Widget _statusStepper({required _Status status}) {
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

Widget _replyPreview({
  required _Item item,
  required VoidCallback onClose,
  String? title,
}) {
  return _glass(
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
                  style: const TextStyle(fontSize: 12.5, color: AppColors.body),
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

Widget _composer({
  required TextEditingController controller,
  required FocusNode focusNode,
  required VoidCallback onSend,
  required VoidCallback onAttach,
}) {
  return ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final count = controller.text.length;
      final hasText = controller.text.trim().isNotEmpty;
      final low = _maxChars - count <= 10;

      return _glass(
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
                style: const TextStyle(fontSize: 14.5, color: AppColors.title),
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                child: _sendOrb(onTap: hasText ? onSend : () {}),
              ),
            ),
          ],
        ),
      );
    },
  );
}

const double _bottomNavBarHeight = 100;

Widget _bottomNav({
  required AnimationController hold,
  required int tab,
  required VoidCallback onHome,
  required VoidCallback onReport,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        _glass(
          radius: const BorderRadius.vertical(top: Radius.circular(28)),
          blur: 28,
          opacity: 0.66,
          tint: AppColors.headerTint,
          borderOpacity: 0.95,
          child: Container(
            height: _bottomNavBarHeight,
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: _navItem(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Home',
                      selected: tab == 0,
                      onTap: onHome,
                    ),
                  ),
                  const Expanded(child: SizedBox()), // space for SOS
                  Expanded(
                    child: _navItem(
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

Widget _navItem({
  required IconData icon,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
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
                          AppColors.sosRed,
                          AppColors.sosDarkRed,
                          AppColors.sosDeepRed,
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
                              color: AppColors.kwhite,
                              size: 22,
                            ),
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: AppColors.kwhite,
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

Widget _sosHoldOverlay({required AnimationController hold}) {
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
                    color: AppColors.kwhite,
                    decoration: TextDecoration.none,
                  ),
                ),
                const Text(
                  'Keep holding to send SOS',
                  style: TextStyle(
                    color: AppColors.kwhite,
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

// Paste this over the existing `_MembersScreen` + `_MembersScreenState`
// in home_screen.dart (it uses the private _glass / _homeBackdrop helpers
// from that file, so it must stay in the same file).

class _MembersScreen extends StatefulWidget {
  const _MembersScreen();

  @override
  State<_MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<_MembersScreen> {
  final _search = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Replace with your real members fetch.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ───────── small building blocks ─────────

  Widget _circle(Widget inner, Color color, {double size = 44}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.34),
            color.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: AppColors.kwhite, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: inner,
    );
  }

  /// Fade + slide-up entrance, staggered by [index].
  Widget _entrance(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index.clamp(0, 8)) * 45),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c),
      ),
      child: child,
    );
  }

  Widget _tile({
    required int index,
    required Widget avatar,
    required String title,
    String? subtitle,
    String? tag,
    Color tagColor = AppColors.brand,
    bool highlight = false,
  }) {
    return _entrance(
      index,
      _glass(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        radius: BorderRadius.circular(20),
        blur: 0,
        opacity: highlight ? 0.80 : 0.62,
        shadow: highlight,
        shadowColor: highlight ? AppColors.brand : null,
        borderColor: highlight
            ? AppColors.brand.withValues(alpha: 0.55)
            : tagColor == AppColors.info
            ? AppColors.info.withValues(alpha: 0.40)
            : null,
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.hint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (tag != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tagColor.withValues(alpha: 0.28)),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: tagColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    String label, {
    int? count,
    IconData icon = Icons.layers_rounded,
    Color color = AppColors.slate,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.30),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 10),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.hint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 11, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    final floors = (_memberCount / 6).ceil();
    return _entrance(
      0,
      _glass(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(16),
        radius: BorderRadius.circular(26),
        blur: 0,
        opacity: 0.70,
        shadowColor: AppColors.brand,
        borderColor: AppColors.brand.withValues(alpha: 0.30),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.mint,
                    AppColors.brand,
                    AppColors.brandDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.kwhite.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: AppColors.kwhite,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    _communityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _statPill(
                        Icons.people_alt_rounded,
                        '$_memberCount members',
                        AppColors.brandDark,
                      ),
                      _statPill(
                        Icons.apartment_rounded,
                        '$floors floors',
                        AppColors.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(double top) {
    return _glass(
      radius: BorderRadius.zero,
      blur: 28,
      opacity: 0.66,
      tint: AppColors.headerTint,
      borderOpacity: 0.95,
      padding: EdgeInsets.fromLTRB(8, top + 10, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.title),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Members',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.title,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '$_communityName · $_memberCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: ListenableBuilder(
        listenable: _search,
        builder: (context, _) {
          final has = _search.text.isNotEmpty;
          return _glass(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            radius: BorderRadius.circular(30),
            blur: 20,
            opacity: 0.62,
            shadow: has,
            shadowColor: has ? AppColors.brand : null,
            borderColor: has
                ? AppColors.brand.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.85),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: has ? AppColors.brand : AppColors.hint,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _search,
                    keyboardType: TextInputType.number,
                    cursorColor: AppColors.brand,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.title,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search room number',
                      hintStyle: TextStyle(color: AppColors.hint, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (has)
                  IconButton(
                    onPressed: _search.clear,
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
        },
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circle(
            const Icon(
              Icons.search_off_rounded,
              size: 30,
              color: AppColors.slate,
            ),
            AppColors.slate,
            size: 72,
          ),
          const SizedBox(height: 14),
          const Text(
            'No room found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a different room number',
            style: TextStyle(fontSize: 12.5, color: AppColors.body),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    return ListenableBuilder(
      listenable: _search,
      builder: (context, _) {
        final q = _search.text.trim();
        final searching = q.isNotEmpty;

        final rooms = [
          for (final r in _memberRooms)
            if (r != _myId && (!searching || r.contains(q))) r,
        ];
        final showAdmin = !searching;
        final showMyRoom = !searching || _myId.contains(q);

        if (rooms.isEmpty && !showAdmin && !showMyRoom) return _empty();

        // Group by floor (first digit of the room number).
        final byFloor = <String, List<String>>{};
        for (final r in rooms) {
          byFloor.putIfAbsent(r[0], () => []).add(r);
        }

        int i = 1;
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          children: [
            if (!searching) _heroCard(),
            if (showAdmin) ...[
              _section(
                'ADMIN',
                icon: Icons.verified_rounded,
                color: AppColors.info,
              ),
              _tile(
                index: i++,
                avatar: _circle(
                  const Icon(
                    Icons.campaign_rounded,
                    size: 22,
                    color: AppColors.info,
                  ),
                  AppColors.info,
                ),
                title: 'Community Admin',
                subtitle: 'Manages the community',
                tag: 'Admin',
                tagColor: AppColors.info,
              ),
            ],
            if (showMyRoom) ...[
              _section(
                'YOU',
                icon: Icons.person_rounded,
                color: AppColors.brand,
              ),
              _tile(
                index: i++,
                highlight: true,
                avatar: _circle(
                  const Icon(
                    Icons.person_rounded,
                    size: 22,
                    color: AppColors.brand,
                  ),
                  AppColors.brand,
                ),
                title: 'Room $_myId',
                subtitle: 'Floor ${_myId[0]}',
                tag: 'You',
              ),
            ],
            for (final e in byFloor.entries) ...[
              _section(
                'FLOOR ${e.key}',
                count: e.value.length,
                icon: Icons.apartment_rounded,
              ),
              for (final r in e.value)
                _tile(
                  index: i++,
                  avatar: _circle(
                    Text(
                      r,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate,
                      ),
                    ),
                    AppColors.slate,
                  ),
                  title: 'Room $r',
                  subtitle: 'Resident',
                ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _homeBackdrop(
          child: Column(
            children: [
              _header(top),
              _searchBar(),
              Expanded(
                child: SkeletonSwitcher(
                  loading: _loading,
                  skeleton: const SkeletonList(count: 9),
                  child: _list(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
