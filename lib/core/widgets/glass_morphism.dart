import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:community/core/theme/app_colors.dart';
import 'package:flutter/services.dart';

class Glass extends StatelessWidget {
  const Glass({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final base = tint ?? AppColors.kwhite;
    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: opacity),
            base.withValues(alpha: opacity * 0.55),
          ],
        ),
        border: Border.all(
          color:
              borderColor ?? AppColors.kwhite.withValues(alpha: borderOpacity),
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
                  color: AppColors.glassShadow.withValues(alpha: 0.10),
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

class GlassBlob extends StatelessWidget {
  const GlassBlob({
    super.key,
    required this.color,
    required this.size,
    this.alpha = 0.35,
  });
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

void focusAndShowKeyboard(FocusNode node) {
  if (node.hasFocus) {
    SystemChannels.textInput.invokeMethod('TextInput.show');
  } else {
    node.requestFocus();
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 26,
    this.blur = 18,
    this.opacity = 0.58,
    this.padding,
    this.margin,
    this.borderColor,
    this.glowColor,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? glowColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.kwhite.withValues(
              alpha: (opacity * 1.15).clamp(0.0, 1.0),
            ),
            AppColors.kwhite.withValues(alpha: opacity * 0.70),
            AppColors.kwhite.withValues(alpha: opacity * 0.50),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: borderColor ?? AppColors.kwhite.withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
      child: child,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: (glowColor ?? AppColors.glassShadow).withValues(
                    alpha: glowColor == null ? 0.10 : 0.28,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: r,
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

class GlassPrimaryButton extends StatelessWidget {
  const GlassPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2BC9A4),
                  AppColors.brand,
                  AppColors.brandDark,
                ],
              )
            : null,
        color: enabled ? null : AppColors.disabled,
        border: Border.all(color: AppColors.kwhite.withValues(alpha: 0.6)),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(
                color: AppColors.kwhite,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
