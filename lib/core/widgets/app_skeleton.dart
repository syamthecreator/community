

import 'package:flutter/material.dart';

const Color _skBase = Color(0xFFD6E5E0);
const Color _skHighlight = Color(0xFFF3FAF8);

class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, required this.child});
  final Widget child;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          begin: const Alignment(-1, -0.3),
          end: const Alignment(1, 0.3),
          colors: const [_skBase, _skHighlight, _skBase],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlideTransform(_c.value),
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.progress);
  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 12,
  });
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
  );
}

class SkeletonSwitcher extends StatelessWidget {
  const SkeletonSwitcher({
    super.key,
    required this.loading,
    required this.skeleton,
    required this.child,
  });
  final bool loading;
  final Widget skeleton;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: loading
          ? KeyedSubtree(
              key: const ValueKey('skeleton'),
              child: IgnorePointer(child: SkeletonShimmer(child: skeleton)),
            )
          : KeyedSubtree(key: const ValueKey('content'), child: child),
    );
  }
}


class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 8});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (_, i) => Row(
        children: [
          const SkeletonCircle(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120 + (i % 3) * 30, height: 14),
                const SizedBox(height: 8),
                SkeletonBox(width: 70 + (i % 2) * 40, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonChatList extends StatelessWidget {
  const SkeletonChatList({super.key});

  static const _sizes = [
    (0.55, 62.0),
    (0.40, 46.0),
    (0.62, 84.0),
    (0.48, 52.0),
    (0.58, 70.0),
    (0.36, 44.0),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
      children: [
        const Center(child: SkeletonBox(width: 70, height: 24, radius: 20)),
        const SizedBox(height: 16),
        for (int i = 0; i < _sizes.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: i.isOdd
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (i.isEven) ...[
                  const SkeletonCircle(size: 36),
                  const SizedBox(width: 8),
                ],
                SkeletonBox(
                  width: w * _sizes[i].$1,
                  height: _sizes[i].$2,
                  radius: 20,
                ),
                if (i.isOdd) ...[
                  const SizedBox(width: 8),
                  const SkeletonCircle(size: 36),
                ],
              ],
            ),
          ),
      ],
    );
  }
}