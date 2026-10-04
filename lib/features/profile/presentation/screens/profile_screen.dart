import 'dart:io';

import 'package:community/core/constants/asset_constants.dart';
import 'package:community/core/theme/app_colors.dart';
import 'package:community/core/widgets/glass_morphism.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Mock data. These details are set by the admin and are read-only here.
const String _mockUserName = 'Nithya Arun';
const String _mockRole = 'Community Member';
const String _mockCommunity = 'Green Valley Apartments';
const String _mockRoom = '201';
const String _mockPhone = '+91 98765 43210';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  String? _photoPath;

  String get _initials {
    final parts = _mockUserName.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (file != null && mounted) setState(() => _photoPath = file.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  void _removePhoto() {
    setState(() => _photoPath = null);
  }

  void _showPhotoSheet() {
    final hasPhoto = _photoPath != null;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: AppColors.kblack.withValues(alpha: 0.25),
      builder: (sheetContext) {
        Widget option(
          IconData icon,
          String label,
          VoidCallback onTap, {
          Color color = AppColors.brand,
        }) {
          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color == AppColors.error ? color : AppColors.title,
              ),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              onTap();
            },
          );
        }

        return _glassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option(
                Icons.photo_camera_outlined,
                'Take a photo',
                () => _pickPhoto(ImageSource.camera),
              ),
              option(
                Icons.photo_library_outlined,
                'Choose from gallery',
                () => _pickPhoto(ImageSource.gallery),
              ),
              if (hasPhoto)
                option(
                  Icons.delete_outline_rounded,
                  'Remove photo',
                  _removePhoto,
                  color: AppColors.error,
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: AppColors.kblack.withValues(alpha: 0.25),
      builder: (_) => _glassSheet(child: _helpContent()),
    );
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
                  Color(0xFFD9F1EA),
                  Color(0xFFE6F0F8),
                  Color(0xFFF1F6F4),
                ],
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
          child: GlassBlob(color: AppColors.brand, size: 280),
        ),
        const Positioned(
          top: 260,
          right: -110,
          child: GlassBlob(color: AppColors.violet, size: 260, alpha: 0.22),
        ),
        const Positioned(
          bottom: 90,
          left: -90,
          child: GlassBlob(color: AppColors.cyan, size: 300, alpha: 0.30),
        ),

        SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 12),
                  child: child,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.onBack != null) ...[
                        GestureDetector(
                          onTap: widget.onBack,
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
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: AppColors.title,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProfileCard(),
                  const SizedBox(height: 12),
                  _buildDetailsCard(),
                  const SizedBox(height: 12),
                  _buildAdminNote(),
                  const SizedBox(height: 20),
                  _buildMenuCard(),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'NIVA · Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.hint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Glass(
      padding: const EdgeInsets.all(16),
      blur: 20,
      opacity: 0.55,
      child: Row(
        children: [
          GestureDetector(
            onTap: _showPhotoSheet,
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.kwhite.withValues(alpha: 0.85),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.25),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: _photoPath != null
                        ? Image.file(
                            File(_photoPath!),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          )
                        : Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand,
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.brand, AppColors.brandDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.kwhite, width: 2),
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        size: 13,
                        color: AppColors.kwhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  _mockUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 6),
                Glass(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  radius: BorderRadius.circular(20),
                  blur: 0,
                  opacity: 0.50,
                  tint: Color.alphaBlend(
                    AppColors.brand.withValues(alpha: 0.20),
                    AppColors.kwhite,
                  ),
                  borderColor: AppColors.brand.withValues(alpha: 0.30),
                  shadow: false,
                  child: const Text(
                    _mockRole,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandDark,
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

  Widget _buildDetailsCard() {
    final divider = Divider(
      height: 1,
      color: AppColors.border.withValues(alpha: 0.25),
    );

    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      blur: 0,
      opacity: 0.58,
      shadow: false,
      child: Column(
        children: [
          _detailRow(
            icon: Icons.apartment_rounded,
            label: 'Community',
            value: _mockCommunity,
          ),
          divider,
          _detailRow(
            icon: Icons.meeting_room_outlined,
            label: 'Room Number',
            value: _mockRoom,
          ),
          divider,
          _detailRow(
            icon: Icons.phone_outlined,
            label: 'Mobile Number',
            value: _mockPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNote() {
    return Glass(
      padding: const EdgeInsets.all(14),
      radius: BorderRadius.circular(16),
      blur: 0,
      opacity: 0.45,
      tint: Color.alphaBlend(
        AppColors.violet.withValues(alpha: 0.20),
        AppColors.kwhite,
      ),
      borderColor: AppColors.violet.withValues(alpha: 0.30),
      shadow: false,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.violet),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'These details are added by your community admin. '
              'Contact the admin if anything needs to change.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return Glass(
      blur: 0,
      opacity: 0.58,
      shadow: false,
      child: _menuRow(
        icon: Icons.help_outline_rounded,
        title: 'Help & Support',
        onTap: _showHelp,
      ),
    );
  }
}

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
            Flexible(child: child),
          ],
        ),
      ),
    ),
  );
}


/// Was: _DetailRow
Widget _detailRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.kwhite.withValues(alpha: 0.7)),
          ),
          child: Icon(icon, size: 19, color: AppColors.brand),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.body,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.title,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Was: _MenuRow
Widget _menuRow({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 23, color: AppColors.brand),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.title,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.hint),
        ],
      ),
    ),
  );
}


const List<({IconData icon, String name, String role, String phone})>
_helpContacts = [
  (
    icon: Icons.apartment_rounded,
    name: 'Management Office',
    role: 'Community manager',
    phone: '+91 98765 00001',
  ),
  (
    icon: Icons.build_outlined,
    name: 'Building Caretaker',
    role: 'Repairs and maintenance',
    phone: '+91 98765 00002',
  ),
  (
    icon: Icons.shield_outlined,
    name: 'Security Desk',
    role: 'Gate and guest entries',
    phone: '+91 98765 00003',
  ),
];

/// Was: _HelpContent
Widget _helpContent() {
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.title,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'For anything urgent, reach the right person directly.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: AppColors.body,
          ),
        ),
        const SizedBox(height: 16),
        Glass(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          blur: 0,
          opacity: 0.58,
          shadow: false,
          child: Column(
            children: [
              for (var i = 0; i < _helpContacts.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.25),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.kwhite.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Icon(
                          _helpContacts[i].icon,
                          size: 21,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _helpContacts[i].name,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.title,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _helpContacts[i].role,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _helpContacts[i].phone,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
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
