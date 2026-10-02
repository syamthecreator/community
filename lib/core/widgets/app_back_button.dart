import 'package:community/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: IconButton(
          tooltip: "Back",
          onPressed: onPressed ?? () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          color: AppColors.title,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(
              color: AppColors.border,
              width: 1,
            ),
            fixedSize: const Size(44, 44),
          ),
        ),
      ),
    );
  }
}