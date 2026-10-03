import 'package:community/core/widgets/glass.dart';
import 'package:community/core/widgets/motion.dart';
import 'package:community/features/authentication/presentation/screens/auth_screen.dart';
import 'package:community/features/authentication/presentation/widgets/auth_step.dart';
import 'package:community/features/authentication/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PhoneStep extends StatefulWidget {
  const PhoneStep({super.key});

  @override
  State<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<PhoneStep> {
  final FocusNode _phoneFocus = FocusNode();

  @override
  void dispose() {
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              FadeSlideIn(child: AuthScreen.header()),
              const SizedBox(height: 22),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: authStepper(step: 1),
              ),
              const SizedBox(height: 22),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AuthScreen.phoneNumberField(focusNode: _phoneFocus),
                      const SizedBox(height: 18),
                      _continueButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: AuthScreen.terms(),
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
        FadeSlideIn(
          delay: const Duration(milliseconds: 420),
          child: AuthScreen.footer(),
        ),
      ],
    );
  }

  /// Was: AuthContinueButton
  Widget _continueButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return GlassPrimaryButton(
          onPressed: auth.isPhoneReady
              ? () => auth.continueAuth(context)
              : null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: auth.isPhoneVerified
                ? const Icon(
                    Icons.check_rounded,
                    key: ValueKey('done'),
                    color: Colors.white,
                    size: 26,
                  )
                : auth.isLoading
                ? const SizedBox(
                    key: ValueKey('loader'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue', key: ValueKey('label')),
          ),
        );
      },
    );
  }
}