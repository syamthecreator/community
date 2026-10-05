import 'package:community/core/network/connectivity_service.dart';
import 'package:community/core/theme/app_colors.dart';
import 'package:community/core/widgets/glass_morphism.dart';
import 'package:community/core/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  int _shake = 0;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    final online = await context.read<ConnectivityService>().check(
      manual: true,
    );
    if (!online && mounted) setState(() => _shake++);
  }

  Widget _hero() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) {
        final t = _pulse.value;
        return SizedBox(
          width: 190,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120 + 70 * t,
                height: 120 + 70 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.30 * (1 - t)),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.error.withValues(alpha: 0.22),
                      AppColors.error.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.coral,
                      AppColors.error,
                    ],
                  ),
                  border: Border.all(color: AppColors.kwhite, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.40),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 44,
                  color: AppColors.kwhite,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.brandDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.title,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checking = context.select<ConnectivityService, bool>(
      (s) => s.isChecking,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GlassBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeSlideIn(child: _hero()),
                  const SizedBox(height: 8),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 100),
                    child: Text(
                      'No internet connection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.title,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 180),
                    child: Text(
                      'Messages, reports and SOS alerts need an active '
                      'connection. Please check your network and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.body,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 260),
                    child: GlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        children: [
                          _tip(Icons.wifi_rounded, 'Turn on Wi-Fi or mobile data'),
                          _tip(
                            Icons.airplanemode_inactive_rounded,
                            'Make sure Airplane mode is off',
                          ),
                          _tip(
                            Icons.router_rounded,
                            'Move closer to your router or signal',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 340),
                    child: Shake(
                      trigger: _shake,
                      child: GlassPrimaryButton(
                        onPressed: checking ? null : _retry,
                        child: checking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.kwhite,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text('Try again'),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 400),
                    child: Text(
                      'We will reconnect automatically',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.hint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}