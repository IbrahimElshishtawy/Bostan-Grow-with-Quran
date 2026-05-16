import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/setting/reader_settings.dart';
import 'package:quranglow/features/ui/routes/app_routes.dart';

import 'dhikr_quick_list.dart';

class TasbihCounter extends ConsumerStatefulWidget {
  const TasbihCounter({super.key});

  @override
  ConsumerState<TasbihCounter> createState() => _TasbihCounterState();
}

class _TasbihCounterState extends ConsumerState<TasbihCounter>
    with TickerProviderStateMixin {
  int _count = 0;
  int _rounds = 0;
  int _selectedDhikrIndex = 0;

  // Animation controller for the button press effect
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  // Animation controller for the continuous pulsing "live" effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _inc(AppSettings settings) async {
    _pressController.forward().then((_) => _pressController.reverse());

    setState(() {
      _count++;
      ref.read(trackingServiceProvider).incRemembrance(1);
      
      if (_count >= settings.tasbihTarget) {
        _rounds++;
        _count = 0;
        
        // Cycle to next dhikr automatically!
        _selectedDhikrIndex = (_selectedDhikrIndex + 1) % DhikrQuickList.items.length;
        
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('أتممت دورة $_rounds بنجاح! انتقلت إلى: ${DhikrQuickList.items[_selectedDhikrIndex]}'),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    });

    if (settings.tasbihVibrate) {
      HapticFeedback.vibrate();
    }
    if (settings.tasbihSound) {
      SystemSound.play(SystemSoundType.click);
    }

    _syncTasbih(settings);
  }

  void _reset(AppSettings settings) {
    setState(() {
      _count = 0;
      _rounds = 0;
      _selectedDhikrIndex = 0;
    });
    _syncTasbih(settings);
  }

  void _syncTasbih(AppSettings settings) {
    ref.read(firebaseSyncServiceProvider).syncTasbih({
      'count': _count,
      'target': settings.tasbihTarget,
      'rounds': _rounds,
      'vibrate': settings.tasbihVibrate,
      'sound': settings.tasbihSound,
      'dhikr': DhikrQuickList.items[_selectedDhikrIndex],
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('خطأ: $error')),
      data: (settings) {
        final progress = (_count / settings.tasbihTarget)
            .clamp(0.0, 1.0)
            .toDouble();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            // Ultra-Shrunk Elegant Header
            _SpiritualHeader(
              selectedDhikr: DhikrQuickList.items[_selectedDhikrIndex],
              rounds: _rounds,
              onReset: () => _reset(settings),
              onOpenSettings: () =>
                  Navigator.pushNamed(context, AppRoutes.setting),
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Centerpiece: The Pulsing Tasbih Dial
            Center(
              child: GestureDetector(
                onTap: () => _inc(settings),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: _TasbihDial(
                      count: _count,
                      target: settings.tasbihTarget,
                      progress: progress,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Controls & Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MiniControlBox(
                  icon: Icons.vibration_rounded,
                  label: 'هزاز',
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setTasbihVibrate(!settings.tasbihVibrate),
                  isDark: isDark,
                  isActive: settings.tasbihVibrate,
                ),
                _InfoMetric(
                  icon: Icons.flag_rounded,
                  title: 'الهدف',
                  value: '${settings.tasbihTarget}',
                ),
                _MiniControlBox(
                  icon: Icons.volume_up_rounded,
                  label: 'صوت',
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setTasbihSound(!settings.tasbihSound),
                  isDark: isDark,
                  isActive: settings.tasbihSound,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Professional manual selection area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.touch_app_rounded, color: cs.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'تبديل الذكر يدوياً',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Tajawal',
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DhikrQuickList(
                    selectedItem: DhikrQuickList.items[_selectedDhikrIndex],
                    onTapItem: (item) {
                      setState(() => _selectedDhikrIndex = DhikrQuickList.items.indexOf(item));
                      _syncTasbih(settings);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpiritualHeader extends StatelessWidget {
  final String selectedDhikr;
  final int rounds;
  final VoidCallback onOpenSettings;
  final VoidCallback onReset;
  final bool isDark;

  const _SpiritualHeader({
    required this.selectedDhikr,
    required this.rounds,
    required this.onOpenSettings,
    required this.onReset,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final gradientColors = isDark
        ? [const Color(0xFF1E3A2F), const Color(0xFF11221B)]
        : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)];

    final textColor = isDark ? Colors.white : const Color(0xFF1B3B2B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.rotate_right_rounded,
                      size: 13,
                      color: textColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'جولة: $rounds',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onReset,
                    icon: Icon(Icons.refresh_rounded, color: textColor, size: 18),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onOpenSettings,
                    icon: Icon(Icons.tune_rounded, color: textColor, size: 18),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              selectedDhikr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                height: 1.2,
                fontWeight: FontWeight.w900,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasbihDial extends StatelessWidget {
  final int count;
  final int target;
  final double progress;
  final bool isDark;

  const _TasbihDial({
    required this.count,
    required this.target,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final glowColor = primaryColor.withValues(alpha: 0.3);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _DialPainter(
                  progress: animatedProgress,
                  trackColor: trackColor,
                  progressColor: primaryColor,
                  glowColor: glowColor,
                ),
              ),
            ),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [const Color(0xFF234231), const Color(0xFF15291E)]
                      : [const Color(0xFFF1F8F4), const Color(0xFFDCEBDE)],
                  center: const Alignment(-0.3, -0.5),
                  radius: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.8),
                    blurRadius: 10,
                    spreadRadius: -2,
                    offset: const Offset(-2, -2),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1A3324),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'من $target',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.glowColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    const startAngle = -1.5708;
    final sweepAngle = 6.28318 * progress;

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      6.28318,
      false,
      trackPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.glowColor != glowColor;
  }
}

class _MiniControlBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isActive;

  const _MiniControlBox({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white38 : Colors.black38);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B3B2B).withValues(alpha: 0.4)
            : const Color(0xFFE8F5E9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
              : const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 22),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
