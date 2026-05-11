import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/level_gameplay_controller.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';

class LevelGameplayScreen extends ConsumerWidget {
  final GameLevel level;

  const LevelGameplayScreen({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(levelGameplayControllerProvider(level));
    final controller = ref.read(levelGameplayControllerProvider(level).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Theme Attributes
    final bgColor = isDark ? const Color(0xFF0B1A13) : const Color(0xFFF8FAFA);
    final textColor = isDark ? Colors.white : const Color(0xFF1B3227);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF1B3227).withValues(alpha: 0.65);
    final appBarColor = Colors.transparent;
    final gradientTop = isDark ? const Color(0xFF153524) : const Color(0xFFEBF3E8);
    final gradientBottom = isDark ? const Color(0xFF0B1A13) : const Color(0xFFF8FAFA);
    final ayahCardBase = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final ayahBorderBase = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFF1B3227).withValues(alpha: 0.08);
    final ayahAccent = const Color(0xFF689F38); // Consistent energetic actionable green

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.surahName,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.2),
              ),
              Text(
                'آيات ${level.ayahStart} - ${level.ayahEnd}',
                style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () {},
            ),
          ],
        ),
        body: state.isLoading
            ? Center(child: CircularProgressIndicator(color: ayahAccent))
            : state.error != null
                ? Center(
                    child: Text(
                      'خطأ: ${state.error}',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  )
                : Stack(
                    children: [
                      // Background Ambient Gradient Layer
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topCenter,
                              radius: 1.4,
                              colors: [gradientTop, gradientBottom],
                            ),
                          ),
                        ),
                      ),

                      Column(
                        children: [
                          // 1. Dynamic Status Bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                            child: _buildStatusBar(state, subTextColor, ayahAccent, isDark),
                          ),

                          // 2. Main Scrolling Engine
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: state.ayahs.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final ayah = state.ayahs[index];
                                final isActive = state.currentPlayingAyahIndex == index;
                                
                                final cardBg = isActive
                                    ? ayahAccent.withValues(alpha: isDark ? 0.15 : 0.08)
                                    : ayahCardBase;
                                final cardBorder = isActive
                                    ? ayahAccent.withValues(alpha: 0.4)
                                    : ayahBorderBase;

                                return GestureDetector(
                                  onTap: () => controller.seekToAyah(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutExpo,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: cardBorder, width: isActive ? 1.5 : 1.0),
                                      boxShadow: !isDark && !isActive 
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.03),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: isActive ? ayahAccent : (isDark ? Colors.white12 : const Color(0xFF1B3227).withValues(alpha: 0.08)),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${ayah.ayahNumber}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w900,
                                                  color: isActive ? Colors.white : subTextColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            if (isActive)
                                              Text(
                                                'قيد الاستماع...',
                                                style: TextStyle(
                                                  color: ayahAccent,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          ayah.text,
                                          style: TextStyle(
                                            fontSize: 27,
                                            height: 1.8,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Kitab',
                                            color: isActive ? textColor : subTextColor,
                                            letterSpacing: -0.1,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // 3. Premium Controls Footplate
                          _buildPlaybackControlBar(controller, state, ref, context, isDark, ayahAccent, textColor),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatusBar(LevelGameplayState state, Color subTextColor, Color accent, bool isDark) {
    final double progress = state.ayahs.isEmpty ? 0 : (state.currentPlayingAyahIndex + 1) / state.ayahs.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'معدل استماع الآيات',
              style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: isDark ? Colors.white10 : const Color(0xFF1B3227).withValues(alpha: 0.05),
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControlBar(
    LevelGameplayController controller,
    LevelGameplayState state,
    WidgetRef ref,
    BuildContext context,
    bool isDark,
    Color accent,
    Color textColor,
  ) {
    final containerColor = isDark ? const Color(0xFF102419) : Colors.white;
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.4 : 0.08);
    final iconTint = isDark ? Colors.white70 : const Color(0xFF1B3227).withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
        border: isDark ? null : Border(top: BorderSide(color: const Color(0xFF1B3227).withValues(alpha: 0.05))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 34,
                icon: Icon(Icons.skip_next_rounded, color: iconTint),
                onPressed: () => controller.seekToAyah(state.currentPlayingAyahIndex - 1),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: controller.playPause,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, accent.withValues(alpha: 0.85)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                iconSize: 34,
                icon: Icon(Icons.skip_previous_rounded, color: iconTint),
                onPressed: () => controller.seekToAyah(state.currentPlayingAyahIndex + 1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF1B3227).withValues(alpha: 0.05),
                foregroundColor: textColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.transparent),
                ),
              ),
              onPressed: () async {
                await ref.read(gamificationControllerProvider.notifier).completeSubTask(level.id, 'listen');
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(
                'تمت القراءة والإنصات بنجاح',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.2,
                  color: isDark ? Colors.white : const Color(0xFF1B3227),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
