import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

class GrandAchievementDialog extends StatelessWidget {
  const GrandAchievementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(isDark ? 0.7 : 0.85),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: cs.primary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ✨ Background Pattern/Image
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/images/bustan_splash.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🌟 Celebration Animation
                    SizedBox(
                      height: 200,
                      child: Lottie.asset(
                        'assets/anim/Quran.json',
                        repeat: true,
                      ),
                    ).animate().scale(
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        ),

                    const SizedBox(height: 16),

                    // 🏆 Title
                    Text(
                      'إنجاز عظيم!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        height: 1.2,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 12),

                    // 📜 Message
                    Text(
                      'مبارك لك ختم رحلة البستان كاملة. لقد أتممت كافة مراحل التعلم والتدبر بنجاح. جعلها الله في ميزان حسناتك ونفع بك الإسلام والمسلمين.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withOpacity(0.8),
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 32),

                    // ✨ Stats Row (Simplified)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          icon: Icons.auto_awesome_rounded,
                          label: 'التميز',
                          value: 'كامل',
                          color: Colors.amber,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: cs.outlineVariant.withOpacity(0.5),
                        ),
                        _StatItem(
                          icon: Icons.verified_user_rounded,
                          label: 'الحالة',
                          value: 'خريج',
                          color: cs.secondary,
                        ),
                      ],
                    ).animate().fadeIn(delay: 1000.ms),

                    const SizedBox(height: 40),

                    // ✅ Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: cs.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'الحمد لله، تم',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1200.ms).scale(begin: const Offset(0.9, 0.9)),
                  ],
                ),
              ),

              // 🎊 Confetti decoration (Optional dots)
              ...List.generate(6, (index) {
                return Positioned(
                  top: 20 + (index * 40).toDouble(),
                  left: index % 2 == 0 ? -10 : null,
                  right: index % 2 != 0 ? -10 : null,
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.amber.withOpacity(0.3),
                    size: 12 + (index * 4).toDouble(),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                      begin: -5,
                      end: 5,
                      duration: (1000 + (index * 200)).ms,
                    );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: cs.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
