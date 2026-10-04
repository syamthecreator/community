import 'package:community/core/constants/asset_constants.dart';
import 'package:community/core/theme/app_colors.dart';
import 'package:community/core/widgets/glass_morphism.dart';
import 'package:community/core/widgets/motion.dart';
import 'package:community/features/authentication/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:community/features/authentication/presentation/widgets/phone_step.dart';
import 'package:community/features/authentication/presentation/widgets/pin_step.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, AuthFlowStep>(
      selector: (_, auth) => auth.step,
      builder: (context, step, _) {
        final onPin = step == AuthFlowStep.pin;
        return PopScope(
          canPop: !onPin,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.read<AuthProvider>().backToPhone();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              backgroundColor: AppColors.background,
              resizeToAvoidBottomInset: true,
              body: GlassBackdrop(
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 350),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    layoutBuilder: (current, previous) =>
                                        Stack(
                                          fit: StackFit.expand,
                                          children: [...previous, ?current],
                                        ),
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                          opacity: anim,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.06, 0),
                                              end: Offset.zero,
                                            ).animate(anim),
                                            child: child,
                                          ),
                                        ),
                                    child: onPin
                                        ? const PinStep(
                                            key: ValueKey('pin'),
                                          )
                                        : const PhoneStep(
                                            key: ValueKey('phone'),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  static Widget header() {
    return Column(
      children: [
        Image.asset(
          AssetConstants.nivaLogo,
          width: 110,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        Text(
          'COMMUNITY APP',
          style: TextStyle(
            fontSize: 11.5,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
            color: AppColors.brandDark.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Welcome to NIVA',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.title,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in with the mobile number\nregistered by your community admin',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: AppColors.body,
          ),
        ),
      ],
    );
  }

  static String? _phoneErrorText(AuthValidationError? error) {
    switch (error) {
      case AuthValidationError.empty:
      case AuthValidationError.invalidNumber:
        return 'Enter a valid Indian mobile number';

      case AuthValidationError.invalidLength:
        return 'Mobile number must be 10 digits';

      case AuthValidationError.notRegistered:
        return "This number isn't registered. Contact your community admin.";

      case null:
        return null;
    }
  }

  static Widget phoneNumberField({
    required FocusNode focusNode,
  }) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final errorText = _phoneErrorText(auth.validationError);
        final hasError = errorText != null;
        final digits = auth.phoneController.text.length;

        return ListenableBuilder(
          listenable: focusNode,
          builder: (context, _) {
            final focused = focusNode.hasFocus;

            final borderColor = hasError
                ? AppColors.error
                : focused
                ? AppColors.brand
                : AppColors.kwhite.withValues(alpha: 0.9);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Mobile number',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.title,
                    ),
                  ),
                ),
                Shake(
                  trigger: auth.phoneErrorTick,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => focusAndShowKeyboard(focusNode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.kwhite.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: focused || hasError ? 1.5 : 1,
                        ),
                        boxShadow: focused
                            ? [
                                BoxShadow(
                                  color: AppColors.brand.withValues(
                                    alpha: 0.14,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 22,
                            color: AppColors.brand.withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: auth.phoneController,
                              focusNode: focusNode,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: false,
                                signed: false,
                              ),
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.telephoneNumberNational,
                              ],
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9]'),
                                ),
                                LengthLimitingTextInputFormatter(10),
                              ],
                              onChanged: (_) => auth.clearError(),
                              onSubmitted: (_) =>
                                  auth.continueAuth(context),
                              cursorColor: AppColors.brand,
                              scrollPadding:
                                  const EdgeInsets.only(bottom: 160),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: AppColors.inputText,
                              ),
                              decoration: const InputDecoration(
                                hintText: '98765 43210',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                  color: AppColors.hint,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                counterText: '',
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(
                                  scale: anim,
                                  child: child,
                                ),
                            child: digits == 10 && !hasError
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    key: ValueKey('ok'),
                                    size: 20,
                                    color: AppColors.brand,
                                  )
                                : digits > 0
                                ? Text(
                                    '$digits/10',
                                    key: const ValueKey('count'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.hint,
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('none'),
                                  ),
                          ),
                          const SizedBox(width: 14),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.topLeft,
                  child: hasError
                      ? Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                            left: 4,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  errorText,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget continueButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return GlassPrimaryButton(
          onPressed: auth.isPhoneReady
              ? () => auth.continueAuth(context)
              : null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: auth.isLoading
                ? const SizedBox(
                    key: ValueKey('loader'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.kwhite,
                    ),
                  )
                : const Text(
                    'Continue',
                    key: ValueKey('label'),
                  ),
          ),
        );
      },
    );
  }

  static Widget terms() {
    return const Text(
      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        height: 1.5,
        color: AppColors.body,
      ),
    );
  }

  static Widget footer() {
    final color = AppColors.brandDark.withValues(alpha: 0.8);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.support_agent_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Not registered? Contact your community admin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}