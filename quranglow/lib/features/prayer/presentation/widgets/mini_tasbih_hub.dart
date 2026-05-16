import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MiniTasbihHub extends ConsumerStatefulWidget {
  const MiniTasbihHub({super.key});

  @override
  ConsumerState<MiniTasbihHub> createState() => _MiniTasbihHubState();
}

class _MiniTasbihHubState extends ConsumerState<MiniTasbihHub>
    with TickerProviderStateMixin {
  // Tasbih logic
  int _count = 0;
  int _adhkarIndex = 0;

  static const _adhkar = [
    'سُبْحَانَ اللهِ',
    'الْحَمْدُ لِلَّهِ',
    'لا إِلهَ إِلاَّ اللهُ',
    'اللهُ أَكْبَرُ',
    'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
    'لا حَوْلَ وَلا قُوَّةَ إِلاَّ بِاللهِ',
    'أَسْتَغْفِرُ اللهَ العَظِيمَ',
  ];

  // Animations
  late final AnimationController _scaleController;
  late final AnimationController _pulseController;
  late final AnimationController _glowController;



  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
      lowerBound: 0.90,
      upperBound: 1.0,
      value: 1.0,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();


  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _glowController.dispose();

    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _scaleController.forward(from: 0.90);
    setState(() {
      _count++;
    });
  }

  void _resetCount() {
    HapticFeedback.heavyImpact();
    setState(() {
      _count = 0;
    });
  }

  void _nextDhikr() {
    HapticFeedback.lightImpact();
    setState(() {
      _adhkarIndex = (_adhkarIndex + 1) % _adhkar.length;
    });
  }



  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.surface, cs.surfaceContainerLow],
        ),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Section - Professional mini Tasbih Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Circular glowing dynamic counter on the right (RTL friendly placement)
                GestureDetector(
                  onTap: _handleTap,
                  child: ScaleTransition(
                    scale: _scaleController,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating outer gradient border ring for premium aesthetic
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _glowController.value * 2 * math.pi,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      cs.primary.withValues(alpha: 0.1),
                                      cs.primary,
                                      cs.primary.withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Inner core tap container
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primaryContainer,
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.25),
                                blurRadius: 12 * _pulseController.value,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_count',
                                style: TextStyle(
                                  fontFamily: 'System',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: cs.onPrimaryContainer,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'تكرار',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Tajawal',
                                  color: cs.onPrimaryContainer.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Center Column - Dhikr Text reader
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'القارئ التسبيحي للفقراء',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: _resetCount,
                            icon: Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                            tooltip: 'تصفير العداد',
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: _nextDhikr,
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.2, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  key: ValueKey<int>(_adhkarIndex),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _adhkar[_adhkarIndex],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Uthman',
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 22,
                              color: cs.primary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ],
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
