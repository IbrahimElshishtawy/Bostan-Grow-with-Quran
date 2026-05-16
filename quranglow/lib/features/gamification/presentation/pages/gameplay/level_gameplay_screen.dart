import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/level_gameplay_controller.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quranglow/core/widgets/loading_widget.dart';

class LevelGameplayScreen extends ConsumerStatefulWidget {
  final GameLevel level;

  const LevelGameplayScreen({
    super.key,
    required this.level,
  });

  @override
  ConsumerState<LevelGameplayScreen> createState() => _LevelGameplayScreenState();
}

class _LevelGameplayScreenState extends ConsumerState<LevelGameplayScreen> {
  final Map<int, GlobalKey> _ayahKeys = {};

  GlobalKey _getOrCreateKey(int index) {
    return _ayahKeys.putIfAbsent(index, () => GlobalKey());
  }

  void _scrollToAyah(int index) {
    final key = _ayahKeys[index];
    if (key != null && key.currentContext != null) {
      Future.microtask(() {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.35, // Perfectly positioned slightly down from top
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(levelGameplayControllerProvider(widget.level));
    final controller = ref.read(levelGameplayControllerProvider(widget.level).notifier);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🚀 Auto-Scroll Synchronization Listener
    ref.listen<LevelGameplayState>(
      levelGameplayControllerProvider(widget.level),
      (previous, next) {
        if (previous?.currentPlayingAyahIndex != next.currentPlayingAyahIndex) {
          _scrollToAyah(next.currentPlayingAyahIndex);
        }
      },
    );

    // Dynamic Theme Attributes
    final bgColor = isDark ? const Color(0xFF0B1A13) : const Color(0xFFF8FAFA);
    final textColor = isDark ? Colors.white : const Color(0xFF1B3227);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF1B3227).withValues(alpha: 0.65);
    final appBarColor = Colors.transparent;
    final gradientTop = isDark ? const Color(0xFF153524) : const Color(0xFFEBF3E8);
    final gradientBottom = isDark ? const Color(0xFF0B1A13) : const Color(0xFFF8FAFA);
    final ayahCardBase = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final ayahBorderBase = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFF1B3227).withValues(alpha: 0.08);
    final ayahAccent = const Color(0xFF689F38); 

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
                widget.level.surahName,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.2),
              ),
              Text(
                'آيات ${widget.level.ayahStart} - ${widget.level.ayahEnd}',
                style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: state.isLoading
            ? Center(child: LoadingWidget(message: 'جاري تجهيز محطة الاستماع...', color: ayahAccent))
            : state.error != null
                ? Center(
                    child: Text(
                      'خطأ: ${state.error}',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  )
                : Stack(
                    children: [
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

                          // 2. Main Continuous Scrolling Engine with Dynamic Position Keys
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Column(
                                children: List.generate(state.ayahs.length, (index) {
                                  final ayah = state.ayahs[index];
                                  final isActive = state.currentPlayingAyahIndex == index;
                                  
                                  final cardBg = isActive
                                      ? ayahAccent.withValues(alpha: isDark ? 0.15 : 0.08)
                                      : ayahCardBase;
                                  final cardBorder = isActive
                                      ? ayahAccent.withValues(alpha: 0.4)
                                      : ayahBorderBase;

                                  return Padding(
                                    key: _getOrCreateKey(index), // 🎯 Critical key registration!
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: GestureDetector(
                                      onTap: () => controller.seekToAyah(index),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 350),
                                        curve: Curves.easeOutExpo,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(16),
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
                                                  ).animate().fadeIn(duration: 300.ms).shimmer(duration: 1200.ms),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              ayah.text,
                                              style: TextStyle(
                                                fontSize: 28, // Slightly larger
                                                height: 1.8, // Better spacing for clarity
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Kitab',
                                                color: isActive ? textColor : subTextColor.withValues(alpha: 0.8),
                                                letterSpacing: -0.2,
                                                shadows: isActive ? [
                                                  Shadow(
                                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ] : null,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),

                          // 3. Dynamic Gated Completion Panel
                          _buildPlaybackControlBar(controller, state, context, isDark, ayahAccent, textColor),
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
    BuildContext context,
    bool isDark,
    Color accent,
    Color textColor,
  ) {
    final containerColor = isDark ? const Color(0xFF102419) : Colors.white;
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.4 : 0.08);
    final iconTint = isDark ? Colors.white70 : const Color(0xFF1B3227).withValues(alpha: 0.7);
    
    // Logic for DYNAMIC button text and actions
    final bool canFinish = state.isFinished;
    
    String buttonLabel = 'استمع لبقية الآيات للإتمام';
    if (canFinish) {
      buttonLabel = 'تمت القراءة والإنصات بنجاح ✅';
    } else if (state.isPlaying) {
      buttonLabel = 'جاري الاستماع...';
    } else {
      buttonLabel = 'تم الإيقاف مؤقتاً';
    }

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
                  child: state.isAudioLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      : Icon(
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
          
          // 🔒 The Gated Action Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canFinish 
                      ? accent // Radiant green when fully usable!
                      : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF1B3227).withValues(alpha: 0.05)),
                  foregroundColor: canFinish ? Colors.white : textColor,
                  elevation: canFinish ? 4 : 0,
                  shadowColor: accent.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: canFinish 
                          ? Colors.transparent 
                          : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.transparent),
                    ),
                  ),
                ),
                onPressed: canFinish 
                  ? () async {
                      await ref.read(gamificationControllerProvider.notifier).completeSubTask(widget.level.id, 'listen');
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  : null, // Locks interaction until audio physically concludes!
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.2,
                    color: canFinish 
                        ? Colors.white 
                        : (isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF1B3227).withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ),
          ).animate(target: canFinish ? 1.0 : 0.0)
           .shimmer(delay: 400.ms, duration: 1500.ms, color: Colors.white24)
           .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1), curve: Curves.elasticOut),
        ],
      ),
    );
  }
}
