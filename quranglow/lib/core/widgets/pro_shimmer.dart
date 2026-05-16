import 'package:flutter/material.dart';

class ProShimmer extends StatefulWidget {
  const ProShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
    this.shape = BoxShape.rectangle,
  });

  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  @override
  State<ProShimmer> createState() => _ProShimmerState();
}

class _ProShimmerState extends State<ProShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color baseColor = isDark 
        ? cs.surfaceContainerHigh.withValues(alpha: 0.6)
        : cs.surfaceContainerHighest.withValues(alpha: 0.4);
    final Color highlightColor = isDark 
        ? cs.surfaceContainerLowest.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle 
                ? null 
                : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [
                0.2,
                0.5,
                0.8,
              ],
              transform: _SlidingGradientTransform(slidePercent: _animation.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
