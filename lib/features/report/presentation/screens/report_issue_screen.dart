import 'dart:io';

import 'package:community/core/theme/app_colors.dart';
import 'package:community/core/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ---------------------------------------------------------------
// Result sent to Home when a report is submitted.
// ---------------------------------------------------------------
enum ReportVisibility { adminOnly, everyone }

class ReportResult {
  final String category;
  final IconData icon;
  final String issue;
  final String note;
  final String? photoPath;
  final ReportVisibility visibility;
  final String refId;

  const ReportResult({
    required this.category,
    required this.icon,
    required this.issue,
    required this.note,
    required this.photoPath,
    required this.visibility,
    required this.refId,
  });
}

// ---------------------------------------------------------------
// Mock data. In the real app these come from the association's
// setup, because each community configures its own options.
// ---------------------------------------------------------------
class _Category {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> issues;

  const _Category({
    required this.label,
    required this.icon,
    required this.color,
    this.issues = const [],
  });

  bool get isCustom => issues.isEmpty;
}

const List<_Category> _categories = [
  _Category(
    label: 'Plumbing',
    color: AppColors.info,
    icon: Icons.plumbing_rounded,
    issues: [
      'Leakage',
      'Blocked drain',
      'Tap not working',
      'Low water pressure',
      'Flush / toilet issue',
    ],
  ),
  _Category(
    label: 'Electrical',
    color: AppColors.warning,
    icon: Icons.bolt_rounded,
    issues: [
      'Power outage',
      'Switch / socket problem',
      'Light not working',
      'MCB keeps tripping',
    ],
  ),
  _Category(
    label: 'Lift',
    icon: Icons.elevator_outlined,
    color: AppColors.violet,
    issues: [
      'Lift not working',
      'Stuck between floors',
      'Door problem',
      'Unusual noise',
    ],
  ),
  _Category(
    label: 'Cleaning',
    color: AppColors.brand,
    icon: Icons.cleaning_services_outlined,
    issues: [
      'Garbage not collected',
      'Stairs / corridor dirty',
      'Common area cleaning',
      'Pest problem',
    ],
  ),
  _Category(
    label: 'Parking',
    color: AppColors.orange,
    icon: Icons.local_parking_rounded,
    issues: [
      'Vehicle blocking my slot',
      'Unknown vehicle parked',
      'Slot dispute',
    ],
  ),
  _Category(
    label: 'Security',
    color: AppColors.rose,
    icon: Icons.shield_outlined,
    issues: ['Suspicious person', 'Gate problem', 'CCTV not working'],
  ),
  _Category(
    label: 'Water',
    color: AppColors.cyan,
    icon: Icons.water_drop_outlined,
    issues: ['No water supply', 'Dirty water', 'Tank overflow'],
  ),
  _Category(
    label: 'Other',
    color: AppColors.slate,
    icon: Icons.more_horiz_rounded,
  ),
];

// ---------------------------------------------------------------
// Report an Issue (embedded in Home as a tab)
// Steps: 1 Category -> 2 Details -> 3 Review, visibility & submit -> Success
//
// This is a plain widget: no Scaffold, SafeArea or background.
// Home provides the header, background and bottom nav.
// ---------------------------------------------------------------
class ReportIssueView extends StatefulWidget {
  /// Opens straight on the custom report form.
  final bool startWithCustom;

  /// Called as soon as a report is submitted (Home adds it to the feed).
  final ValueChanged<ReportResult> onSubmitted;

  /// Called when the user leaves the report tab (back on step 1 / Back to Home).
  final VoidCallback onExit;

  const ReportIssueView({
    super.key,
    required this.onSubmitted,
    required this.onExit,
    this.startWithCustom = false,
  });

  @override
  State<ReportIssueView> createState() => ReportIssueViewState();
}

class ReportIssueViewState extends State<ReportIssueView> {
  static const int _stepCount = 3;
  static const int _minCustomLength = 10;

  final TextEditingController _noteController = TextEditingController();

  int _step = 0; // 0 category, 1 details, 2 review
  _Category? _category;
  String? _issue;

  final ImagePicker _picker = ImagePicker();
  XFile? _photo;

  // Defaults to the privacy-safe option.
  ReportVisibility _visibility = ReportVisibility.adminOnly;

  bool _isSubmitting = false;
  bool _submitted = false;
  String _refId = '';
  ReportResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.startWithCustom) {
      _category = _categories.last;
      _step = 1;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isCustom => _category?.isCustom ?? false;

  bool get _canContinueFromDetails {
    if (_isCustom) {
      return _noteController.text.trim().length >= _minCustomLength;
    }
    return _issue != null;
  }

  // ------------------------- actions -------------------------

  /// Returns true if it handled the back press itself.
  /// Home calls this from the system back button.
  bool handleBack() {
    if (_submitted) {
      widget.onExit();
      return true;
    }
    if (_step > 0) {
      FocusScope.of(context).unfocus();
      setState(() => _step--);
      return true;
    }
    return false;
  }

  void _selectCategory(_Category category) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (_category != category) {
        _issue = null;
        _photo = null;
        _noteController.clear();
      }
      _category = category;
    });

    // Short pause so the selection is visible, then move on.
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted && _step == 0) setState(() => _step = 1);
    });
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_step > 0) {
      setState(() => _step--);
    } else {
      widget.onExit();
    }
  }

  void _goToReview() {
    if (!_canContinueFromDetails) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 2);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _submitted = true;
      _refId = '#RPT-${1000 + DateTime.now().millisecondsSinceEpoch % 9000}';

      _result = ReportResult(
        category: _category!.label,
        icon: _category!.icon,
        issue: _isCustom ? 'Custom report' : _issue!,
        note: _noteController.text.trim(),
        photoPath: _photo?.path,
        visibility: _visibility,
        refId: _refId,
      );
    });

    widget.onSubmitted(_result!);
  }

  // Shared glass wrapper for bottom sheets.
  Widget _glassSheet({required Widget child}) {
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
              child,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPhotoSourceSheet() async {
    FocusScope.of(context).unfocus();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (sheetContext) {
        return _glassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.brand,
                ),
                title: const Text(
                  'Take a photo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.title,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.brand,
                ),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.title,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source != null) _pickPhoto(source);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file != null && mounted) setState(() => _photo = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  // ------------------------- build -------------------------
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          if (!_submitted) _buildHeader(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_submitted ? 'done' : 'step$_step'),
                child: _buildBody(),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_submitted) return _buildSuccess();
    switch (_step) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildDetailsStep();
      default:
        return _buildReviewStep();
    }
  }

  // ---------------------------------------------------------------
  // Header: back button, title, step progress
  // ---------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              if (_step > 0) ...[
                GestureDetector(
                  onTap: _goBack,
                  child: Glass(
                    radius: BorderRadius.circular(22),
                    blur: 14,
                    opacity: 0.60,
                    shadow: false,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.title,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              const Expanded(
                child: Text(
                  'Report an Issue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.title,
                  ),
                ),
              ),
              Glass(
                radius: BorderRadius.circular(20),
                blur: 0,
                opacity: 0.60,
                shadow: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: Text(
                  'Step ${_step + 1} of $_stepCount',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.body,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                for (var i = 0; i < _stepCount; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? AppColors.brand
                            : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: i <= _step
                            ? [
                                BoxShadow(
                                  color: AppColors.brand.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Step 1: choose a category
  // ---------------------------------------------------------------
  Widget _buildCategoryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What do you need help with?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick a category. No typing needed.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.body,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [for (final c in _categories) _buildCategoryTile(c)],
          ),
          const SizedBox(height: 20),
          Glass(
            padding: const EdgeInsets.all(14),
            radius: BorderRadius.circular(16),
            blur: 0,
            opacity: 0.45,
            tint: Color.alphaBlend(
              AppColors.brand.withValues(alpha: 0.25),
              Colors.white,
            ),
            borderColor: AppColors.brand.withValues(alpha: 0.30),
            shadow: false,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.brandDark,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need help?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.title,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Just select the category and we'll send it to the "
                        "right person. Can't find yours? Choose Other and "
                        'write a custom report.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.body,
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
    );
  }

  Widget _buildCategoryTile(_Category category) {
    final selected = _category == category;
    final color = category.color;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectCategory(category),
      child: Glass(
        radius: BorderRadius.circular(16),
        blur: 0,
        opacity: selected ? 0.70 : 0.55,
        tint: Color.alphaBlend(
          color.withValues(alpha: selected ? 0.22 : 0.08),
          Colors.white,
        ),
        borderColor: selected ? color : color.withValues(alpha: 0.30),
        shadow: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              ),
              child: Icon(category.icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.title,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Step 2: pick the issue, add a note, choose the flat
  // ---------------------------------------------------------------
  Widget _buildDetailsStep() {
    final category = _category!;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryPill(category),
          const SizedBox(height: 16),
          Text(
            _isCustom ? 'Describe your issue' : "What's the problem?",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isCustom
                ? 'Tell us what happened so the right person can help.'
                : 'Select the option that fits best.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.body,
            ),
          ),
          const SizedBox(height: 18),

          if (!_isCustom) ...[
            for (final issue in category.issues) ...[
              _buildIssueTile(issue),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            _buildLabel('Add a note (optional)'),
            const SizedBox(height: 8),
            _buildNoteField(
              hint: 'Any extra details for the caretaker...',
              lines: 3,
            ),
          ] else ...[
            _buildNoteField(
              hint: 'Write your report here...',
              lines: 5,
              helper: 'At least $_minCustomLength characters',
            ),
          ],

          const SizedBox(height: 20),
          _buildLabel('Add a photo (optional)'),
          const SizedBox(height: 8),
          _buildPhotoPicker(),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(_Category category) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => setState(() => _step = 0),
        child: Glass(
          padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
          radius: BorderRadius.circular(20),
          blur: 0,
          opacity: 0.50,
          tint: Color.alphaBlend(
            AppColors.brand.withValues(alpha: 0.20),
            Colors.white,
          ),
          borderColor: AppColors.brand.withValues(alpha: 0.30),
          shadow: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(category.icon, size: 16, color: AppColors.brandDark),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Change',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueTile(String issue) {
    final selected = _issue == issue;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _issue = issue),
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        radius: BorderRadius.circular(14),
        blur: 0,
        opacity: selected ? 0.70 : 0.55,
        tint: selected
            ? Color.alphaBlend(
                AppColors.brand.withValues(alpha: 0.18),
                Colors.white,
              )
            : Colors.white,
        borderColor: selected
            ? AppColors.brand
            : Colors.white.withValues(alpha: 0.85),
        shadow: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                issue,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: AppColors.title,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.brand
                    : Colors.white.withValues(alpha: 0.7),
                border: Border.all(
                  color: selected ? AppColors.brand : AppColors.border,
                  width: 1.4,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppColors.title,
      ),
    );
  }

  Widget _buildNoteField({
    required String hint,
    required int lines,
    String? helper,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        controller: _noteController,
        minLines: lines,
        maxLines: lines,
        maxLength: 300,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        cursorColor: AppColors.brand,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 14.5,
          height: 1.4,
          color: AppColors.title,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.55),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.hint),
          helperText: helper,
          helperStyle: const TextStyle(fontSize: 12, color: AppColors.body),
          counterStyle: const TextStyle(fontSize: 12, color: AppColors.hint),
          contentPadding: const EdgeInsets.all(14),
          border: border(Colors.white.withValues(alpha: 0.85), 1.2),
          enabledBorder: border(Colors.white.withValues(alpha: 0.85), 1.2),
          focusedBorder: border(AppColors.brand, 1.6),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    if (_photo == null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showPhotoSourceSheet,
        child: Glass(
          padding: const EdgeInsets.symmetric(vertical: 20),
          radius: BorderRadius.circular(14),
          blur: 0,
          opacity: 0.45,
          tint: Color.alphaBlend(
            AppColors.brand.withValues(alpha: 0.12),
            Colors.white,
          ),
          borderColor: AppColors.brand.withValues(alpha: 0.35),
          shadow: false,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.brand,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Add a photo',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 1.2,
            ),
          ),
          child: Image.file(
            File(_photo!.path),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _buildPhotoAction(Icons.edit_outlined, _showPhotoSourceSheet),
              const SizedBox(width: 8),
              _buildPhotoAction(
                Icons.close_rounded,
                () => setState(() => _photo = null),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        radius: BorderRadius.circular(20),
        blur: 12,
        opacity: 0.35,
        tint: Colors.black,
        borderColor: Colors.white.withValues(alpha: 0.5),
        shadow: false,
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Step 3: review, choose who can see it, submit
  // ---------------------------------------------------------------
  Widget _buildReviewStep() {
    final category = _category!;
    final note = _noteController.text.trim();
    final adminOnly = _visibility == ReportVisibility.adminOnly;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review your report',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check the details, choose who sees it, then submit.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.body,
            ),
          ),
          const SizedBox(height: 20),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            radius: BorderRadius.circular(16),
            blur: 0,
            opacity: 0.58,
            shadow: false,
            child: Column(
              children: [
                _buildReviewRow(
                  'Category',
                  category.label,
                  icon: category.icon,
                ),
                _buildDivider(),
                _buildReviewRow('Issue', _isCustom ? 'Custom report' : _issue!),
                _buildDivider(),
                if (note.isNotEmpty) ...[
                  _buildDivider(),
                  _buildReviewRow(_isCustom ? 'Description' : 'Note', note),
                ],
                if (_photo != null) ...[
                  _buildDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 92,
                          child: Text(
                            'Photo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.body,
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_photo!.path),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildVisibilityPicker(),
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(14),
            radius: BorderRadius.circular(16),
            blur: 0,
            opacity: 0.45,
            tint: Color.alphaBlend(
              AppColors.brand.withValues(alpha: 0.25),
              Colors.white,
            ),
            borderColor: AppColors.brand.withValues(alpha: 0.30),
            shadow: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.brandDark,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    adminOnly
                        ? 'Only you and the admin will see this report in the '
                              'chat. Other residents cannot see it.'
                        : 'Everyone in the community will see this report in '
                              'the chat, along with its status.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityPicker() {
    Widget tile(
      ReportVisibility value,
      IconData icon,
      String title,
      String subtitle,
      Color color,
    ) {
      final selected = _visibility == value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _visibility = value),
        child: Glass(
          padding: const EdgeInsets.all(14),
          radius: BorderRadius.circular(14),
          blur: 0,
          opacity: selected ? 0.70 : 0.55,
          tint: selected
              ? Color.alphaBlend(color.withValues(alpha: 0.18), Colors.white)
              : Colors.white,
          borderColor: selected ? color : Colors.white.withValues(alpha: 0.85),
          shadow: false,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.body,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? color : AppColors.border,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Who should see this?'),
        const SizedBox(height: 8),
        tile(
          ReportVisibility.adminOnly,
          Icons.lock_rounded,
          'Admin only',
          'Only you and the admin can see it',
          AppColors.violet,
        ),
        const SizedBox(height: 10),
        tile(
          ReportVisibility.everyone,
          Icons.groups_rounded,
          'Everyone',
          'Shown in the community chat',
          AppColors.brand,
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
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
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppColors.brand),
                  const SizedBox(width: 6),
                ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.border.withValues(alpha: 0.25));
  }

  // ---------------------------------------------------------------
  // Success state
  // ---------------------------------------------------------------
  Widget _buildSuccess() {
    final adminOnly = _visibility == ReportVisibility.adminOnly;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.30),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: AppColors.brand,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Report submitted',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              adminOnly
                  ? 'Your report has been sent to the admin. Only you and '
                        "the admin can see it. We'll update you as it moves along."
                  : 'Your report is now visible in the community chat. '
                        "We'll update you as it moves along.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: AppColors.body,
              ),
            ),
            const SizedBox(height: 18),
            Glass(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              radius: BorderRadius.circular(20),
              blur: 14,
              opacity: 0.60,
              shadow: false,
              child: Text(
                'Reference $_refId',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Bottom action bar
  // ---------------------------------------------------------------
  Widget _buildBottomBar() {
    if (_submitted) {
      return _bottomBarShell(
        _primaryButton(label: 'Back to Home', onPressed: widget.onExit),
      );
    }

    switch (_step) {
      case 1:
        return _bottomBarShell(
          _primaryButton(
            label: 'Review',
            onPressed: _canContinueFromDetails ? _goToReview : null,
          ),
        );
      case 2:
        return _bottomBarShell(
          _primaryButton(
            label: 'Submit Report',
            loading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _bottomBarShell(Widget child) {
    return Glass(
      radius: const BorderRadius.vertical(top: Radius.circular(24)),
      blur: 24,
      opacity: 0.60,
      tint: const Color(0xFFF1FBF8),
      shadow: false,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: child,
    );
  }
}

// ---------------------------------------------------------------
// Primary button (same look as the login screens)
// Was: _PrimaryButton
// ---------------------------------------------------------------
Widget _primaryButton({
  required String label,
  required VoidCallback? onPressed,
  bool loading = false,
}) {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.disabled,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: loading
            ? const SizedBox(
                key: ValueKey('loader'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                key: ValueKey(label),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ),
  );
}
