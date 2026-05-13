import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class LevelNodeWidget extends StatefulWidget {
  const LevelNodeWidget({
    required this.level,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final GameLevel level;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<LevelNodeWidget> createState() => _LevelNodeWidgetState();
}

class _LevelNodeWidgetState extends State<LevelNodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double _buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LevelNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.level.isUnlocked) return;
    setState(() => _buttonScale = 0.85); // Smooth press down physics
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.level.isUnlocked) return;
    setState(() => _buttonScale = 1.0); // Spring back bounce physics
    widget.onTap();
  }

  void _handleTapCancel() {
    if (!widget.level.isUnlocked) return;
    setState(() => _buttonScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final locked = !widget.level.isUnlocked;
    final completed = widget.level.isCompleted;
    final mastered = widget.level.masteryLevel > 0;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: AnimatedScale(
                scale: _buttonScale,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Pulsing Glow behind active station
                    if (widget.isActive && !locked)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 104 + (_pulseController.value * 24),
                            height: 104 + (_pulseController.value * 24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: GameificationColors.goldAccent.withValues(
                                alpha: 0.15 * (1.0 - _pulseController.value),
                              ),
                            ),
                          );
                        },
                      ),

                    // 2. Node Outer Progress Ring
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: locked
                              ? Colors.grey[300]!
                              : completed
                              ? mastered
                                    ? GameificationColors.goldAccent
                                    : GameificationColors.primaryGreen
                              : widget.isActive
                              ? GameificationColors.goldAccent
                              : GameificationColors.primaryGreenLight,
                          width: 4,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircularProgressIndicator(
                          value: widget.level.taskProgress,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completed
                                ? mastered
                                      ? GameificationColors.goldAccent
                                      : GameificationColors.primaryGreen
                                : GameificationColors.goldLight,
                          ),
                          strokeWidth: 4,
                        ),
                      ),
                    ),

                    // 3. Inner Circle Icon Button
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: locked
                            ? []
                            : [
                                BoxShadow(
                                  color:
                                      (completed
                                              ? mastered
                                                    ? GameificationColors
                                                          .goldAccent
                                                    : GameificationColors
                                                          .primaryGreen
                                              : GameificationColors.goldAccent)
                                          .withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                        gradient: _getGradient(locked, completed, mastered),
                      ),
                      child: Icon(
                        locked
                            ? Icons.lock_rounded
                            : widget.level.isMystery
                            ? Icons.card_giftcard_rounded
                            : _getStationIcon(widget.level.type),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    // 4. Mystery Star Sparkle Overlay
                    if (widget.level.isMystery && !completed)
                      Positioned(
                        top: -8,
                        right: -8,
                        child:
                            const Icon(
                                  Icons.auto_awesome,
                                  color: GameificationColors.goldAccent,
                                  size: 24,
                                )
                                .animate(onPlay: (c) => c.repeat())
                                .rotate(duration: 4.seconds)
                                .scale(
                                  duration: 1.seconds,
                                  curve: Curves.easeInOut,
                                ),
                      ),

                    // 5. Gold Mastery Crown Above Node
                    if (mastered)
                      Positioned(
                        top: -20,
                        child:
                            const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: GameificationColors.goldAccent,
                                  size: 26,
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .shimmer(duration: 2.seconds)
                                .slideY(begin: 0.1, end: -0.1),
                      ),

                    // 6. Mini Task Count Badge (e.g. 2/5 completed)
                    if (!locked && !completed)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: GameificationColors.darkNavyLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: GameificationColors.goldAccent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${(widget.level.taskProgress * 5).round()}/5',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Station Title & Info (Arabic + English)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isActive
                      ? GameificationColors.goldAccent.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.level.surahName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: locked
                          ? Colors.grey
                          : GameificationColors.primaryGreenDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.level.isMystery
                        ? 'محطة المفاجآت والكنز'
                        : widget.level.type.arabicLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: locked
                          ? Colors.grey
                          : GameificationColors.goldDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: locked
                            ? Colors.grey
                            : GameificationColors.goldAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.level.ayahStart}-${widget.level.ayahEnd}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms).scale(delay: 100.ms),
          ],
        ),
      ),
      ),
    );
  }

  LinearGradient _getGradient(bool locked, bool completed, bool mastered) {
    if (locked) {
      return LinearGradient(
        colors: [Colors.grey[400]!, Colors.grey[500]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (mastered) {
      return const LinearGradient(
        colors: [GameificationColors.goldAccent, Colors.orangeAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (completed) {
      return const LinearGradient(
        colors: [
          GameificationColors.primaryGreen,
          GameificationColors.primaryGreenLight,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (widget.isActive) {
      return const LinearGradient(
        colors: [GameificationColors.goldAccent, GameificationColors.goldLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getStationIcon(StationType type) {
    switch (type) {
      case StationType.learning:
        return Icons.auto_stories;
      case StationType.listening:
        return Icons.headphones_rounded;
      case StationType.reading:
        return Icons.menu_book_rounded;
      case StationType.writing:
        return Icons.edit_note_rounded;
      case StationType.memorization:
        return Icons.psychology_rounded;
      case StationType.revisionGate:
        return Icons.door_sliding_rounded;
      case StationType.bossChallenge:
        return Icons.workspace_premium_rounded;
      case StationType.mysteryStation:
        return Icons.card_giftcard_rounded;
    }
  }
}
