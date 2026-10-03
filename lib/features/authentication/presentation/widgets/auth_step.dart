import 'package:community/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// "Mobile number -> Admin PIN" progress. [step] is 1 or 2.
/// Was: AuthStepper
Widget authStepper({required int step}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _stepDot(number: 1, label: 'Mobile number', step: step),
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 28,
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: step > 1
              ? AppColors.brand
              : AppColors.brand.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      _stepDot(number: 2, label: 'Admin PIN', step: step),
    ],
  );
}

/// Was: _StepDot
Widget _stepDot({
  required int number,
  required String label,
  required int step,
}) {
  final done = step > number;
  final active = step == number;
  final highlighted = done || active;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted
              ? AppColors.brand
              : Colors.white.withValues(alpha: 0.7),
          border: Border.all(
            color: highlighted
                ? AppColors.brand
                : AppColors.brand.withValues(alpha: 0.25),
          ),
        ),
        child: done
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : Text(
                '$number',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? Colors.white
                      : AppColors.brandDark.withValues(alpha: 0.6),
                ),
              ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: highlighted ? AppColors.brandDark : AppColors.hint,
        ),
      ),
    ],
  );
}