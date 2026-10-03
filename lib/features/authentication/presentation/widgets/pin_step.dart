
import 'package:community/core/widgets/app_back_button.dart';
import 'package:community/core/widgets/glass.dart';
import 'package:community/core/widgets/motion.dart';
import 'package:community/features/authentication/presentation/screens/verfication_screen.dart';
import 'package:community/features/authentication/presentation/widgets/auth_step.dart';
import 'package:community/features/authentication/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PinStep extends StatefulWidget {
  const PinStep({super.key});

  @override
  State<PinStep> createState() => _PinStepState();
}

class _PinStepState extends State<PinStep> {
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
    final phone = context.read<AuthProvider>().phoneController.text;

    return Column(
      children: [
        AppBackButton(onPressed: () => context.read<AuthProvider>().backToPhone()),
        const Spacer(flex: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              FadeSlideIn(child: PinHeader(phoneNumber: phone)),
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
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
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
    );
  }
}

// ---- PinHeader, PinInput, _PinBox, PinVerifyButton, PinHelp ----
// Paste them EXACTLY as in your current verfication_screen.dart.
// ONE change, inside PinHeader: the "Change" chip's onTap becomes
//   onTap: () => context.read<AuthProvider>().backToPhone(),
// instead of Navigator.maybePop(context).