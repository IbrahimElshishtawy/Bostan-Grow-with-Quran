import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';
import 'package:quranglow/features/gamification/presentation/widgets/gamification_header.dart';

class ModernHomeScreen extends ConsumerWidget {
  const ModernHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStateAsync = ref.watch(gamificationControllerProvider);

    return gameStateAsync.when(
      loading: () => const _LoadingScreen(),
      error: (error, st) => _ErrorScreen(error: error),
      data: (gameState) => _HomeScreenContent(gameState: gameState),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GameificationColors.backgroundGradient,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              GameificationColors.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GameificationColors.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: GameificationColors.primaryGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScreenContent extends ConsumerWidget {
  const _HomeScreenContent({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: GameificationColors.backgroundGradient,
            ),
          ),

          // Floating decorations
          const _FloatingDecorations(),

          // Main content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: GameificationHeader(
                  userProfile: gameState.userProfile,
                  gameState: gameState,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Main progression path
              SliverToBoxAdapter(
                child: _ProgressionPath(gameState: gameState),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _FloatingDecorations extends StatefulWidget {
  const _FloatingDecorations();

  @override
  State<_FloatingDecorations> createState() => _FloatingDecorationsState();
}

class _FloatingDecorationsState extends State<_FloatingDecorations>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<Offset> _animation1;
  late Animation<Offset> _animation2;

  @override
  void initState() {
    super.initState();

    _controller1 = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _animation1 = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 20),
    ).animate(CurvedAnimation(parent: _controller1, curve: Curves.easeInOut));

    _animation2 = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -15),
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating mosque decoration (top right)
        SlideTransition(
          position: _animation1,
          child: Positioned(
            top: 100,
            right: 20,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.mosque,
                size: 120,
                color: GameificationColors.primaryGreen,
              ),
            ),
          ),
        ),

        // Floating star decoration (bottom left)
        SlideTransition(
          position: _animation2,
          child: Positioned(
            bottom: 200,
            left: 30,
            child: Opacity(
              opacity: 0.06,
              child: Icon(
                Icons.star,
                size: 100,
                color: GameificationColors.goldAccent,
              ),
            ),
          ),
        ),

        // Floating crescent moon (top left)
        SlideTransition(
          position: _animation1,
          child: Positioned(
            top: 150,
            left: 40,
            child: Opacity(
              opacity: 0.07,
              child: Icon(
                Icons.wb_twilight,
                size: 80,
                color: GameificationColors.primaryGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressionPath extends StatelessWidget {
  const _ProgressionPath({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Section title
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Journey',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: GameificationColors.primaryGreen,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${gameState.completedLevels} of ${gameState.totalLevels} levels completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 12),
                // Overall progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: gameState.overallProgress,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      GameificationColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Levels path
          _LevelsPath(levels: gameState.levels, currentLevel: gameState.currentLevel),
        ],
      ),
    );
  }
}

class _LevelsPath extends StatelessWidget {
  const _LevelsPath({
    required this.levels,
    required this.currentLevel,
  });

  final List<GameLevel> levels;
  final GameLevel? currentLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        levels.length,
        (index) {
          final level = levels[index];
          final isActive = level.id == currentLevel?.id;
          final isCompleted = level.isCompleted;
          final isLocked = !level.isUnlocked;

          return Column(
            children: [
              // Curved path connector (except for first level)
              if (index > 0)
                SizedBox(
                  height: 60,
                  child: CustomPaint(
                    painter: _CurvedPathPainter(
                      isCompleted: levels[index - 1].isCompleted,
                      isActive: isActive,
                    ),
                    size: Size.infinite,
                  ),
                ),

              // Level node
              _LevelNodeCard(
                level: level,
                isActive: isActive,
                isCompleted: isCompleted,
                isLocked: isLocked,
                onTap: () => _showLevelDetail(context, level),
              ),

              // Spacing between levels
              if (index < levels.length - 1) const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  void _showLevelDetail(BuildContext context, GameLevel level) {
    if (!level.isUnlocked) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LevelDetailSheet(level: level),
    );
  }
}

class _CurvedPathPainter extends CustomPainter {
  _CurvedPathPainter({
    required this.isCompleted,
    required this.isActive,
  });

  final bool isCompleted;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted
          ? GameificationColors.primaryGreen
          : Colors.grey[400]!
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (isActive) {
      paint.color = GameificationColors.goldAccent;
      paint.strokeWidth = 4;
    }

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.quadraticBezierTo(
      size.width / 2 + 20,
      size.height / 2,
      size.width / 2,
      size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CurvedPathPainter oldDelegate) {
    return oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isActive != isActive;
  }
}

class _LevelNodeCard extends StatefulWidget {
  const _LevelNodeCard({
    required this.level,
    required this.isActive,
    required this.isCompleted,
    required this.isLocked,
    required this.onTap,
  });

  final GameLevel level;
  final bool isActive;
  final bool isCompleted;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  State<_LevelNodeCard> createState() => _LevelNodeCardState();
}

class _LevelNodeCardState extends State<_LevelNodeCard>
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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
  void didUpdateWidget(_LevelNodeCard oldWidget) {
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
    return GestureDetector(
      onTap: widget.isLocked ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isActive ? _scaleAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: GameificationColors.primaryGreen
                              .withValues(alpha: 0.4 * _glowAnimation.value),
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                      ]
                    : [GameificationColors.softShadow],
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    GameificationColors.radiusXLarge,
                  ),
                  side: BorderSide(
                    color: _getBorderColor(),
                    width: 2,
                  ),
                ),
                color: _getCardColor(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Level icon circle
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _getGradient(),
                          boxShadow: [GameificationColors.softShadow],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              _getLevelIcon(),
                              size: 32,
                              color: Colors.white,
                            ),
                            if (widget.isLocked)
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Level info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.level.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: widget.isLocked
                                        ? Colors.grey[500]
                                        : Colors.black87,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.level.surahName,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            // Stars and XP
                            Row(
                              children: [
                                // Stars
                                Row(
                                  children: List.generate(
                                    widget.level.maxStars,
                                    (index) => Icon(
                                      Icons.star,
                                      size: 14,
                                      color: index < widget.level.starsEarned
                                          ? GameificationColors.goldAccent
                                          : Colors.grey[300],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // XP
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GameificationColors.goldAccent
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+${widget.level.xpReward} XP',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color:
                                              GameificationColors.goldAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Completion indicator
                      if (widget.isCompleted)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GameificationColors.primaryGreen
                                .withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: GameificationColors.primaryGreen,
                            size: 24,
                          ),
                        )
                      else if (widget.isActive)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GameificationColors.goldAccent
                                .withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.play_circle,
                            color: GameificationColors.goldAccent,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCardColor() {
    if (widget.isLocked) return Colors.grey[100]!;
    if (widget.isActive) return Colors.white;
    if (widget.isCompleted) return Colors.white;
    return Colors.white;
  }

  Color _getBorderColor() {
    if (widget.isLocked) return Colors.grey[300]!;
    if (widget.isCompleted) return GameificationColors.primaryGreen;
    if (widget.isActive) return GameificationColors.goldAccent;
    return Colors.grey[300]!;
  }

  LinearGradient _getGradient() {
    if (widget.isLocked) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey[400]!, Colors.grey[300]!],
      );
    }
    if (widget.isCompleted) {
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
      colors: [Colors.blue[300]!, Colors.blue[200]!],
    );
  }

  IconData _getLevelIcon() {
    switch (widget.level.type) {
      case LevelType.surah:
        return Icons.menu_book;
      case LevelType.tajweed:
        return Icons.music_note;
      case LevelType.review:
        return Icons.refresh;
      case LevelType.bossTest:
        return Icons.shield;
      case LevelType.dailyChallenge:
        return Icons.flash_on;
    }
  }
}

class _LevelDetailSheet extends StatelessWidget {
  const _LevelDetailSheet({required this.level});

  final GameLevel level;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(GameificationColors.radiusXLarge),
              topRight: Radius.circular(GameificationColors.radiusXLarge),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Level header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: GameificationColors.primaryGradient,
                    ),
                    child: Icon(
                      _getLevelTypeIcon(level.type),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          level.type.label,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                level.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.star,
                      label: 'Stars',
                      value: '${level.starsEarned}/${level.maxStars}',
                      color: GameificationColors.goldAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.flash_on,
                      label: 'XP Reward',
                      value: '+${level.xpReward}',
                      color: GameificationColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius:
                      BorderRadius.circular(GameificationColors.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${level.surahName} - Ayah ${level.ayahStart} to ${level.ayahEnd}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${level.ayahCount} verses • Difficulty: ${level.difficulty}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action button
              if (level.isUnlocked)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Level'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameificationColors.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.lock),
                  label: const Text('Locked'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getLevelTypeIcon(LevelType type) {
    switch (type) {
      case LevelType.surah:
        return Icons.menu_book;
      case LevelType.tajweed:
        return Icons.music_note;
      case LevelType.review:
        return Icons.refresh;
      case LevelType.bossTest:
        return Icons.shield;
      case LevelType.dailyChallenge:
        return Icons.flash_on;
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GameificationColors.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [GameificationColors.softShadow],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Quran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
