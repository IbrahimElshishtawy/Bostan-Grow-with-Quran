import 'package:flutter/material.dart';

/// Core modern shimmer effect provider
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({super.key, required this.child, this.isLoading = true});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF222222) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, -0.3),
              end: Alignment(1.0 + _controller.value * 2, 0.3),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.4, 0.5, 0.6],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// Helper building method exposed globally for uniform pills
Widget _buildSkeletonPill({
  required double width,
  required double height,
  required Color color,
  double? radius,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius ?? (height / 2)),
    ),
  );
}

/// 📜 1. SKELETON FOR MUSHAF READER (Simulates Quran Lines & Header)
class MushafSkeleton extends StatelessWidget {
  const MushafSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[300]!;

    return ShimmerLoading(
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Decorative Header Placeholder (Bismillah/Surah Title area)
            _buildSkeletonPill(
              width: 160,
              height: 32,
              color: barColor,
              radius: 8,
            ),
            const SizedBox(height: 40),

            // Mimicking full justifies Quran lines
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                separatorBuilder: (_, _) => const SizedBox(height: 20),
                itemBuilder: (_, index) {
                  // Simulate real scattered Quran words using a Wrap instead of a single bar!
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(5 + (index % 3), (wIdx) {
                      // Generate various dynamic width factors simulating words lengths
                      final baseWidth = 40.0 + ((wIdx * 17 + index * 13) % 60);
                      return _buildSkeletonPill(
                        width: baseWidth,
                        height: 20,
                        color: barColor,
                        radius: 4,
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎧 2. SKELETON FOR AUDIO PLAYER (Artwork + Bars + Controls)
class PlayerSkeleton extends StatelessWidget {
  const PlayerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final barColor = isDark ? const Color(0xFF2D2D2D) : Colors.grey[300]!;

    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Upper Selector Row Placeholder
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            // Main Artwork Big Box
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Text Labels
            _buildSkeletonPill(width: 140, height: 16, color: barColor),
            const SizedBox(height: 12),
            _buildSkeletonPill(width: 220, height: 12, color: barColor),
            const SizedBox(height: 32),

            // Transport Slider Placeholder
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: barColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 32),

            // Play/Pause Controls Row Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSkeletonPill(width: 40, height: 40, color: barColor),
                _buildSkeletonPill(width: 64, height: 64, color: barColor),
                _buildSkeletonPill(width: 40, height: 40, color: barColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 🕌 3. SKELETON FOR PRAYER PAGE (Compass Circle + Time Cards)
class PrayerPageSkeleton extends StatelessWidget {
  const PrayerPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF222222) : Colors.grey[300]!;

    return ShimmerLoading(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: 40,
          left: 16,
          right: 16,
          bottom: 32,
        ),
        child: Column(
          children: [
            // Header date label
            _buildSkeletonPill(width: 180, height: 16, color: barColor),
            const SizedBox(height: 24),

            // Circular Qibla Compass Placeholder
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: barColor, width: 4),
              ),
            ),
            const SizedBox(height: 32),

            // Countdown Card
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: barColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 24),

            // Vertically stacked individual prayer card rows
            ...List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🥇 4. SKELETON FOR SURAH LIST (Mirrors the new Gold-framed cards layout)
class SurahListSkeleton extends StatelessWidget {
  const SurahListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final barColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey[200]!;
    final shapeColor = isDark ? const Color(0xFF333333) : Colors.grey[300]!;

    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: shapeColor.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Rotating Box Badge Placeholder
              Transform.rotate(
                angle: 0.785,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Text lines
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonPill(
                      width: 120,
                      height: 16,
                      color: barColor,
                      radius: 4,
                    ),
                    const SizedBox(height: 8),
                    _buildSkeletonPill(
                      width: 70,
                      height: 10,
                      color: barColor,
                      radius: 3,
                    ),
                  ],
                ),
              ),

              // Tail arrow
              _buildSkeletonPill(width: 12, height: 12, color: shapeColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🌟 5. PRESET SKELETON (Provided screenshot shape, kept for general compatibility)
class PremiumSkeletonCard extends StatelessWidget {
  const PremiumSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final barColor = isDark ? const Color(0xFF333333) : Colors.grey[300]!;

    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonPill(width: 100, height: 24, color: barColor),
                  const SizedBox(height: 24),
                  _buildSkeletonPill(width: 200, height: 24, color: barColor),
                  const SizedBox(height: 24),
                  _buildSkeletonPill(width: 260, height: 24, color: barColor),
                  const SizedBox(height: 24),
                  _buildSkeletonPill(width: 250, height: 24, color: barColor),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _buildSkeletonPill(
                width: 100,
                height: 24,
                color: barColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
