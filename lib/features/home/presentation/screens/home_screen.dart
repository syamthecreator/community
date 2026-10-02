import 'dart:io';
import 'dart:ui';

import 'package:community/app/app_router.dart';
import 'package:community/core/constants/asset_constants.dart';
import 'package:community/core/theme/app_colors.dart';
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
enum _Type { admin, member, report }

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
    this.place,
    this.status,
    this.adminOnly = false,
    this.replyAuthor,
    this.replyText,
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
  final String? place; // optional free-text location from the report form
  final _Status? status;
  final bool adminOnly;
  final String? replyAuthor;
  final String? replyText;

  bool get isMine => userId == _myId;
  bool get isAdmin => type == _Type.admin;
  String get displayName =>
      isAdmin ? 'Community Admin' : (isMine ? 'You' : userId);
}

/// Every member gets their own colour (derived from the ID) so messages from
/// different people are instantly distinguishable.
Color _userColor(String id) {
  const palette = [
    Color(0xFF8E6BF0), // violet
    Color(0xFF14A7C9), // cyan
    Color(0xFFE5578B), // rose
    Color(0xFFEE8A2B), // orange
    Color(0xFF3C8DE0), // blue
    Color(0xFFB07A3C), // amber-brown
    Color(0xFF5E7F9A), // slate-blue
  ];
  return palette[id.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length];
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

  bool _showJump = false;
  bool _pinnedVisible = true;
  _Item? _replyTo;

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
    _controller.addListener(() => setState(() {}));
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final far = _scroll.position.maxScrollExtent - _scroll.offset > 200;
      if (far != _showJump) setState(() => _showJump = far);
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _jumpToEnd(animate: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _hold.dispose();
    super.dispose();
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
    FocusScope.of(context).unfocus();
    setState(() {
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
          place: result.location,
          text: _clip(
            result.note.isEmpty ? result.issue : '${result.issue} ${result.note}',
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
    _addMine(text: text);
    _controller.clear();
  }

  // ───────── Attach: ONE icon → Camera / Gallery → preview + caption ─────────
  Future<void> _openAttachSheet() async {
    FocusScope.of(context).unfocus();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => const _AttachSheet(),
    );
    if (source == null || !mounted) return;
    await _pickFlow(source);
  }

  /// pick → preview (caption, <=50 chars) → send / retake (loops).
  Future<void> _pickFlow(ImageSource source) async {
    while (mounted) {
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
      if (picked == null || !mounted) return; // user cancelled the picker

      final path = picked.path;
      final result = await Navigator.of(context).push<_PreviewResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _ImagePreviewScreen(path: path, source: source),
        ),
      );
      if (result == null || !mounted) return; // closed without sending
      if (result.retake) continue; // go round again
      _addMine(text: result.caption, photoPath: path);
      return;
    }
  }

  void _setReply(_Item item) {
    HapticFeedback.selectionClick();
    setState(() => _replyTo = item);
  }

  void _sosSent() {
    HapticFeedback.heavyImpact();
    _hold.reset();
    showModalBottomSheet(
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
  }

  Widget _buildChatTab(bool hasText) {
    final pinned = _pinned;
    return Column(
      children: [
        if (pinned != null && _pinnedVisible)
          _PinnedBar(
            text: pinned.text,
            onClose: () => setState(() => _pinnedVisible = false),
          ),
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scroll,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < _items.length; i++) ...[
                      if (i == 0 || _items[i].day != _items[i - 1].day)
                        _DayChip(label: _items[i].day),
                      _MessageRow(
                        item: _items[i],
                        onReply: () => _setReply(_items[i]),
                      ),
                      const SizedBox(height: 12),
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
        if (_replyTo != null)
          _ReplyPreview(
            item: _replyTo!,
            onClose: () => setState(() => _replyTo = null),
          ),
        _Composer(
          controller: _controller,
          hasText: hasText,
          onSend: _sendText,
          onAttach: _openAttachSheet,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final hasText = _controller.text.trim().isNotEmpty;

    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final handled = _reportKey.currentState?.handleBack() ?? false;
        if (!handled) _selectTab(0);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF4F1),
        body: Stack(
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

            SafeArea(
               bottom: false,
              child: Column(
                children: [
                  _Header(
                    onNotifications: () =>
                        Navigator.pushNamed(context, AppRouter.notifications),
                    onProfile: () =>
                        Navigator.pushNamed(context, AppRouter.profile),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tab,
                      sizing: StackFit.expand,
                      children: [
                        _buildChatTab(hasText),
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

            // Red hold-feedback overlay while SOS is pressed.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _hold,
                  builder: (_, _) {
                    if (_hold.value == 0) return const SizedBox.shrink();
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.error.withValues(
                              alpha: 0.30 * _hold.value,
                            ),
                            AppColors.error.withValues(
                              alpha: 0.55 * _hold.value,
                            ),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(3 - _hold.value * 3).ceil()}',
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
            ),
          ],
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
    Widget tile(IconData icon, String label, Color color, ImageSource src) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.pop(context, src),
          child: _Glass(
            blur: 0,
            opacity: 0.7,
            radius: BorderRadius.circular(22),
            shadow: false,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.75), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.title,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _Glass(
      radius: const BorderRadius.vertical(top: Radius.circular(30)),
      blur: 28,
      opacity: 0.85,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.slate.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Text(
              'Share a photo',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                tile(
                  Icons.photo_camera_rounded,
                  'Camera',
                  AppColors.brand,
                  ImageSource.camera,
                ),
                const SizedBox(width: 12),
                tile(
                  Icons.photo_library_rounded,
                  'Upload',
                  _Tone.sky,
                  ImageSource.gallery,
                ),
              ],
            ),
          ],
        ),
      ),
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
  void initState() {
    super.initState();
    _caption.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _send() =>
      Navigator.pop(context, _PreviewResult(caption: _caption.text.trim()));

  @override
  Widget build(BuildContext context) {
    final camera = widget.source == ImageSource.camera;
    final count = _caption.text.length;
    final low = _maxChars - count <= 10;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, const _PreviewResult(retake: true)),
                    icon: Icon(
                      camera
                          ? Icons.refresh_rounded
                          : Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      camera ? 'Retake' : 'Choose another',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.file(File(widget.path), fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 3, 5, 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _caption,
                        maxLength: _maxChars,
                        maxLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                        ),
                        cursorColor: AppColors.brand,
                        decoration: const InputDecoration(
                          hintText: 'Add a message…',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '$count/$_maxChars',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: low ? _Tone.coral : Colors.white60,
                        ),
                      ),
                    ),
                    _SendOrb(onTap: _send),
                  ],
                ),
              ),
            ),
          ],
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
    return _Glass(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      radius: BorderRadius.circular(26),
      blur: 20,
      opacity: 0.60,
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
  const _MessageRow({required this.item, required this.onReply});
  final _Item item;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final mine = item.isMine;
    final maxW = MediaQuery.of(context).size.width * 0.72;
    final avatar = _Avatar(item: item);

    return Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!mine) avatar,
        Flexible(
          child: GestureDetector(
            onLongPress: onReply,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: item.type == _Type.report
                  ? _ReportCard(item: item)
                  : _Bubble(item: item),
            ),
          ),
        ),
        if (mine) avatar,
      ],
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
        : (mine ? AppColors.brand : _userColor(item.userId));

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
    final userColor = isAdmin ? AppColors.info : _userColor(item.userId);
    final fg = mine ? Colors.white : AppColors.title;

    // Three clearly different looks:
    //  • mine   → solid brand-green gradient, right side
    //  • admin  → blue-tinted glass with verified badge
    //  • member → white glass tinted with that member's own colour
    final Gradient gradient = mine
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF000B38F), Color(0xF0287B6D)],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                userColor.withValues(alpha: isAdmin ? 0.26 : 0.20),
                Colors.white,
              ).withValues(alpha: 0.88),
              Color.alphaBlend(
                userColor.withValues(alpha: isAdmin ? 0.12 : 0.08),
                Colors.white,
              ).withValues(alpha: 0.62),
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
          : userColor.withValues(alpha: 0.40),
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
          // User ID header on every message (privacy: ID only).
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
                      color: mine ? Colors.white70 : userColor,
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
    final accent = item.adminOnly ? AppColors.violet : AppColors.brand;
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
                    color: item.isMine ? AppColors.brandDark : _userColor(item.userId),
                  ),
                ),
                if (item.place != null && item.place!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: AppColors.slate,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          item.place!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
  const _ReplyPreview({required this.item, required this.onClose});
  final _Item item;
  final VoidCallback onClose;

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
                    'Replying to ${item.displayName}',
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
    required this.hasText,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final count = controller.text.length;
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
          // ONE attach icon → sheet with Camera / Upload.
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
              maxLength: _maxChars,
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
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
              child: _SendOrb(onTap: hasText ? onSend : () {}),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(top: 26),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _Glass(
            radius: BorderRadius.circular(0),
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