/// Level node widget for displaying individual levels in the progression map

library level_node_widget;

import 'package:flutter/material.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';
import 'package:quranglow/features/gamification/presentation/widgets/level_node_painter.dart';

class LevelNodeWidget extends StatefulWidget {
  const LevelNodeWidget({
    required this.level,
    required this.isActive,
    required this.onTap,
    this.showPath = true,
    this.pathProgress = 0,
    super.key,
  });

  final GameLevel level;
  final bool isActive;
  final VoidCallback onTap;
  final bool showPath;
  final double pathProgress;

  @override
  State<LevelNodeWidget> createState() => _LevelNodeWidgetState();
}

class _LevelNodeWidgetState extends State<LevelNodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LevelNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showPath && widget.level.sequence > 1)
          SizedBox(
            height: 60,
            child: CustomPaint(
              painter: LevelPathPainter(
                isCompleted: widget.level.isCompleted,
                isActive: widget.isActive,
                progress: widget.pathProgress,
              ),
              size: Size.infinite,
            ),
          ),
        GestureDetector(
          onTap: widget.level.isUnlocked ? widget.onTap : null,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isActive ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: GameificationColors.primaryGreen
                                  .withValues(alpha: 0.5 * _glowAnimation.value),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : [GameificationColors.softShadow],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _getGradient(),
                          border: Border.all(
                            color: _getBorderColor(),
                            width: 3,
                          ),
                        ),
                      ),

                      // Lock overlay
                      if (!widget.level.isUnlocked)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),

                      // Content
                      if (widget.level.isUnlocked)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Level type icon
                            _getLevelTypeIcon(),
                            const SizedBox(height: 4),
                            // Stars
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.level.maxStars,
                                (index) => Icon(
                                  Icons.star,
                                  size: 12,
                                  color: index < widget.level.starsEarned
                                      ? GameificationColors.goldAccent
                                      : Colors.grey[300],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Level info
        SizedBox(
          width: 120,
          child: Column(
            children: [
              Text(
                widget.level.surahName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.level.isUnlocked
                          ? Colors.black87
                          : Colors.grey,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Ayah ${widget.level.ayahStart}-${widget.level.ayahEnd}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              // XP reward
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: GameificationColors.goldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${widget.level.xpReward} XP',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: GameificationColors.goldAccent,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  LinearGradient _getGradient() {
    if (!widget.level.isUnlocked) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey[300]!,
          Colors.grey[200]!,
        ],
      );
    }

    if (widget.level.isCompleted) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GameificationColors.primaryGreen,
          GameificationColors.primaryGreenLight,
        ],
      );
    }

    if (widget.isActive) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GameificationColors.goldAccent,
          GameificationColors.goldLight,
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.blue[300]!,
        Colors.blue[200]!,
      ],
    );
  }

  Color _getBorderColor() {
    if (!widget.level.isUnlocked) {
      return Colors.grey[400]!;
    }
    if (widget.level.isCompleted) {
      return GameificationColors.primaryGreen;
    }
    if (widget.isActive) {
      return GameificationColors.goldAccent;
    }
    return Colors.blue[400]!;
  }

  Widget _getLevelTypeIcon() {
    IconData icon;
    Color color;

    switch (widget.level.type) {
      case LevelType.surah:
        icon = Icons.menu_book;
        color = GameificationColors.primaryGreen;
        break;
      case LevelType.tajweed:
        icon = Icons.music_note;
        color = GameificationColors.goldAccent;
        break;
      case LevelType.review:
        icon = Icons.refresh;
        color = Colors.blue;
        break;
      case LevelType.bossTest:
        icon = Icons.shield;
        color = Colors.orange;
        break;
      case LevelType.dailyChallenge:
        icon = Icons.flash_on;
        color = Colors.purple;
        break;
    }

    return Icon(icon, size: 24, color: color);
  }
}
