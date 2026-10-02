import 'package:community/core/constants/asset_constants.dart';
import 'package:community/core/theme/app_colors.dart';
import 'package:community/core/widgets/app_back_button.dart';
import 'package:community/core/widgets/glass.dart';
import 'package:community/core/widgets/motion.dart';
import 'package:community/features/authentication/presentation/widgets/auth_step.dart';
import 'package:community/features/authentication/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class VerficationScreen extends StatefulWidget {
  final String phoneNumber;

  const VerficationScreen({super.key, required this.phoneNumber});

  @override
  State<VerficationScreen> createState() => _VerficationScreenState();
}

class _VerficationScreenState extends State<VerficationScreen> {
  final FocusNode _pinFocus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().initializePin();
      _pinFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Empty-space taps dismiss the keyboard; PIN boxes and buttons consume
    // their own taps. Tapping the PIN boxes brings the keyboard back.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF4F1),
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
                          const AppBackButton(),
                          const Spacer(flex: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                FadeSlideIn(
                                  child: PinHeader(
                                    phoneNumber: widget.phoneNumber,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const FadeSlideIn(
                                  delay: Duration(milliseconds: 100),
                                  child: AuthStepper(step: 2),
                                ),
                                const SizedBox(height: 22),
                                FadeSlideIn(
                                  delay: const Duration(milliseconds: 200),
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        PinInput(
                                          focusNode: _pinFocus,
                                          obscure: _obscure,
                                          onToggleObscure: () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        const PinVerifyButton(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const FadeSlideIn(
                                  delay: Duration(milliseconds: 320),
                                  child: PinHelp(),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(flex: 2),
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
    );
  }
}

class PinHeader extends StatelessWidget {
  const PinHeader({super.key, required this.phoneNumber});

  final String phoneNumber;

  String get _formatted => phoneNumber.length == 10
      ? '+91 ${phoneNumber.substring(0, 5)} ${phoneNumber.substring(5)}'
      : '+91 $phoneNumber';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(AssetConstants.nivaLogo, width: 100, fit: BoxFit.contain),
        const SizedBox(height: 24),
        const Text(
          'Enter your PIN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.title,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the 4-digit PIN\ngiven to you by your community admin',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: AppColors.body,
          ),
        ),
        const SizedBox(height: 14),
        // Shows which number is being used, with a quick way to change it.
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_iphone_rounded,
                  size: 16,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatted,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 14,
                  color: AppColors.brand.withValues(alpha: 0.25),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PinInput extends StatelessWidget {
  const PinInput({
    super.key,
    required this.focusNode,
    required this.obscure,
    required this.onToggleObscure,
  });

  final FocusNode focusNode;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final locked = auth.isLocked;
        final hasError = auth.hasPinError || locked;

        final String? message = locked
            ? 'Too many attempts. Try again in ${auth.lockCountdown}'
            : auth.hasPinError
            ? 'Incorrect PIN. ${auth.attemptsLeft} '
                  '${auth.attemptsLeft == 1 ? 'attempt' : 'attempts'} left.'
            : null;

        // Rebuild on focus / text change so the active box highlights.
        return ListenableBuilder(
          listenable: Listenable.merge([focusNode, auth.pinController]),
          builder: (context, _) {
            final text = auth.pinController.text;
            final activeIndex = text.length.clamp(
              0,
              AuthProvider.pinLength - 1,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shake(
                  trigger: auth.pinErrorTick,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: locked
                        ? null
                        : () => focusAndShowKeyboard(focusNode),
                    child: SizedBox(
                      height: 62,
                      child: Stack(
                        children: [
                          // Hidden input field.
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Semantics(
                                label: 'NIVA PIN',
                                textField: true,
                                child: TextField(
                                  controller: auth.pinController,
                                  focusNode: focusNode,
                                  readOnly: locked,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                      AuthProvider.pinLength,
                                    ),
                                  ],
                                  // Auto-verify as soon as the last digit is in.
                                  onChanged: (value) {
                                    if (value.length ==
                                        AuthProvider.pinLength) {
                                      auth.verifyPinAndNavigate(context);
                                    }
                                  },
                                  onSubmitted: (_) =>
                                      auth.verifyPinAndNavigate(context),
                                  showCursor: false,
                                  enableInteractiveSelection: false,
                                  expands: true,
                                  maxLines: null,
                                  style: const TextStyle(
                                    color: Colors.transparent,
                                  ),
                                  decoration: const InputDecoration(
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    counterText: '',
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (
                                var i = 0;
                                i < AuthProvider.pinLength;
                                i++
                              ) ...[
                                if (i > 0) const SizedBox(width: 12),
                                Expanded(
                                  child: _PinBox(
                                    char: i < text.length ? text[i] : null,
                                    active:
                                        focusNode.hasFocus &&
                                        !locked &&
                                        i == activeIndex,
                                    hasError: hasError,
                                    obscure: obscure,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.topLeft,
                        child: message == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 6, left: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Icon(
                                        locked
                                            ? Icons.lock_clock_rounded
                                            : Icons.error_outline,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        message,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onToggleObscure,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.brandDark.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              obscure ? 'Show' : 'Hide',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandDark.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.char,
    required this.active,
    required this.hasError,
    required this.obscure,
  });

  final String? char;
  final bool active;
  final bool hasError;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final filled = char != null;
    final accent = hasError ? AppColors.error : AppColors.brand;
    final borderColor = hasError || active || filled
        ? accent
        : Colors.white.withValues(alpha: 0.9);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: filled && !hasError
              ? [
                  AppColors.brand.withValues(alpha: 0.22),
                  AppColors.brand.withValues(alpha: 0.10),
                ]
              : [
                  Colors.white.withValues(alpha: 0.85),
                  Colors.white.withValues(alpha: 0.55),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: active || hasError ? 1.8 : 1.2,
        ),
        boxShadow: active || hasError
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: filled
            ? (obscure
                  ? Container(
                      key: const ValueKey('dot'),
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.title,
                      ),
                    )
                  : Text(
                      char!,
                      key: ValueKey('digit-$char'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ))
            : active
            ? Container(
                key: const ValueKey('caret'),
                width: 2,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }
}

class PinVerifyButton extends StatelessWidget {
  const PinVerifyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return GlassPrimaryButton(
          onPressed: auth.isPinReady
              ? () => auth.verifyPinAndNavigate(context)
              : null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: auth.isPinVerified
                ? const Icon(
                    Icons.check_rounded,
                    key: ValueKey('done'),
                    color: Colors.white,
                    size: 26,
                  )
                : auth.isVerifying
                ? const SizedBox(
                    key: ValueKey('loader'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('Verify & Continue', key: ValueKey('label')),
          ),
        );
      },
    );
  }
}

/// Explains where the PIN comes from, so members know what to do if stuck.
class PinHelp extends StatelessWidget {
  const PinHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.support_agent_rounded,
            size: 22,
            color: AppColors.brandDark,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forgot your PIN?',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your PIN is set by your community admin. '
                  'Ask them to share or reset it.',
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
    );
  }
}
