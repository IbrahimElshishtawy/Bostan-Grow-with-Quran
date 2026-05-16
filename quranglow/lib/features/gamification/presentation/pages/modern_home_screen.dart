import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/widgets/components/station_tasks_sheet.dart';
import 'package:quranglow/features/gamification/presentation/widgets/modern_home/refined_path_painter.dart';
import 'package:quranglow/features/gamification/presentation/widgets/modern_home/active_level_footer.dart';
import 'package:quranglow/features/gamification/presentation/widgets/modern_home/expandable_dashboard_card.dart';
import 'package:quranglow/features/gamification/presentation/widgets/modern_home/game_level_node.dart';
import 'package:quranglow/features/gamification/presentation/widgets/modern_home/station_section_header.dart';
import 'package:quranglow/features/gamification/presentation/widgets/modern_home/goal_selector_sheet.dart';
import 'package:quranglow/features/gamification/presentation/widgets/dialogs/grand_achievement_dialog.dart';
import 'package:quranglow/core/widgets/shimmer_loading.dart';

class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen> {
  late final ScrollController _scrollController;
  int _dailyGoal = 10; // Default selection

  // High-performance listener to toggle CTA footer visibility dynamically on scroll
  final ValueNotifier<bool> _showFooterNotifier = ValueNotifier(true);
  double _cachedActiveNodeY = -1.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScrollUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Perform Initial Focus Scroll exactly onto the CURRENT Level to begin!
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _scrollController.hasClients && _cachedActiveNodeY > 0) {
          final double centerViewOffset = (_cachedActiveNodeY - 350.0).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.animateTo(
            centerViewOffset,
            duration: const Duration(milliseconds: 1600),
            curve: Curves.fastOutSlowIn,
          );
        }
      });

      // 2. Check if it is the user's first session to show goal picker
      _checkFirstTime();
    });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenGoal = prefs.getBool('has_seen_goal_selection') ?? false;

    if (!hasSeenGoal) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          GoalSelectorSheet.show(
            context,
            initialGoal: _dailyGoal,
            onSave: (int selectedGoal) {
              _saveGoalAndMarkSeen(selectedGoal);
            },
          );
        }
      });
    }
  }

  Future<void> _saveGoalAndMarkSeen(int selectedGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_goal_selection', true);
    await prefs.setInt('daily_reading_goal', selectedGoal);

    // CRITICAL: Tell the gamification system to instantly dynamically regenerate the roadmap!
    ref
        .read(gamificationControllerProvider.notifier)
        .updateDailyGoalAndRegenerate(selectedGoal);

    setState(() {
      _dailyGoal = selectedGoal;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ما شاء الله! تم حفظ هدفك اليومي، جعلها الله بداية مباركة.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4E7440),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onScrollUpdate() {
    if (!_scrollController.hasClients || _cachedActiveNodeY < 0) return;

    final double scrollOffset = _scrollController.offset;

    // Smart Visibility Logic: Detect if the Active Node is physically within the primary viewport range!
    // The viewport height is typically 700-900px.
    // If node is roughly between scrollOffset and scrollOffset + 600, it's in view!
    final bool isNodeInViewport =
        (scrollOffset > _cachedActiveNodeY - 700) &&
        (scrollOffset < _cachedActiveNodeY + 100);

    // Footer visibility state SHOULD be INVERTED! (Visible when Node IS NOT in viewport)
    final bool shouldShow = !isNodeInViewport;

    if (_showFooterNotifier.value != shouldShow) {
      _showFooterNotifier.value = shouldShow;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollUpdate);
    _scrollController.dispose();
    _showFooterNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameStateAsync = ref.watch(gamificationControllerProvider);

    return gameStateAsync.when(
      loading: () => Scaffold(
        body: ListView.builder(
          padding: const EdgeInsets.only(top: 60),
          itemCount: 3,
          itemBuilder: (_, _) => const PremiumSkeletonCard(),
        ),
      ),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (gameState) {
        // ✨ JOURNEY COMPLETION CELEBRATION TRIGGER
        // If the user has finished all levels but hasn't seen the grand achievement dialog yet!
        if (gameState.overallProgress >= 1.0 &&
            !gameState.userProfile.hasSeenJourneyCompletionDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const GrandAchievementDialog(),
              );
              // Mark as seen so it doesn't pop up again!
              ref
                  .read(gamificationControllerProvider.notifier)
                  .markJourneyCompletionAsSeen();
            }
          });
        }

        // PRE-CALCULATE the EXACT target Y coordinate of the Active Node once during build cycle
        // This synchronizes with actual render offsets generator logic!
        final levels = gameState.levels;
        int activeIdx = levels.indexWhere(
          (l) => l.isUnlocked && !l.isCompleted,
        );
        if (activeIdx == -1) activeIdx = 0;

        double currentY = 70.0; // Updated baseline to match precise map logic
        for (int i = 0; i < levels.length; i++) {
          if (i % 10 == 0) currentY += 220.0; // Match Header Gap logic!
          if (i == activeIdx) {
            _cachedActiveNodeY = currentY;
            break;
          }
          currentY += 320.0; // Match spacing logic!
        }

        // Find current active level details for the Footer bindings!
        final activeLevel = levels[activeIdx];
        final activeLevelTitle = activeLevel.surahName;

        return _buildContent(
          gameState,
          activeLevelTitle,
          activeIdx + 1,
          activeLevel,
        );
      },
    );
  }

  Widget _buildContent(
    GameState gameState,
    String activeLevelTitle,
    int activeLevelSeq,
    GameLevel activeLevel,
  ) {
    final levels = gameState.levels;
    final int totalLevelsCount = levels.length;
    final int completedCount = gameState.completedLevels;
    final int totalAyahs =
        6236; // Total number of verses in the entire Quran as requested
    final int memorizedAyahs = levels
        .where((l) => l.isCompleted)
        .fold(0, (sum, l) => sum + l.ayahCount);

    final int streak = gameState.userProfile.streak;
    final double overallProgress = gameState.overallProgress;

    // Calculate detailed progress breakdowns
    final int totalListened = levels.where((l) => l.isListenCompleted).length;
    final int totalRead = levels.where((l) => l.isReadCompleted).length;
    final double listenProgress = totalLevelsCount == 0
        ? 0.0
        : totalListened / totalLevelsCount;
    final double readProgress = totalLevelsCount == 0
        ? 0.0
        : totalRead / totalLevelsCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF111A14)
            : const Color(0xFFFDFBF7),
        body: Stack(
          children: [
            // 1. Premium Generated Visual Background Layer
            Positioned.fill(
              child: Image.asset(
                isDark
                    ? 'assets/images/app_bg_dark.png'
                    : 'assets/images/app_bg_light.png',
                fit: BoxFit.cover,
              ),
            ),

            // 1b. Ultra-Premium Islamic Pattern Texture Tiled (Very Faint & Subtle)
            Positioned.fill(
              child: Opacity(
                opacity: 0.02, // Barely visible, super elegant texture
                child: Image.asset(
                  'assets/images/islamic_pattern.png',
                  repeat: ImageRepeat.repeat,
                  width: 200, // Scale the tile down
                  height: 200,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFF8B6D3A).withValues(alpha: 0.1),
                ),
              ),
            ),

            // The soft glowing orb containers removed as requested

            // 3. Scrollable Map Content
            Positioned.fill(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Top Padding Clearance to push map significantly below the floating header
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 330), // Increased push down
                  ),

                  // 3f. Hifz Path Title inside sandy area
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF384E36),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'مسار الحفظ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(
                                              0xFF1A2E21,
                                            ).withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text(
                              '$activeLevelSeq من $totalLevelsCount مستوى',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3g. The Advanced Path Map with Precise Coordinates
                  SliverToBoxAdapter(child: _buildPrecisePathMap(gameState)),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
            // 3b. PERSISTENT FLOATING TOP HEADER + DASHBOARD (Anchored!)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(bottom: 12),
                // Subtle protection gradient background so content is readable while map scrolls under
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark
                          ? const Color(0xFF111A14).withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.95),
                      isDark
                          ? const Color(0xFF111A14).withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.8),
                      isDark
                          ? const Color(0xFF111A14).withValues(alpha: 0.0)
                          : Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.8, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 65,
                    ), // Lowered down from the top camera notch for safe room
                    // Top Header Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Scaffold.of(context).openDrawer(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Icon(
                                Icons.menu_rounded,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A2E21),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                'مسار الحفظ',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : Color(0xFF1A2E21),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'درب التميز',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 28),
                        ],
                      ),
                    ),

                    const SizedBox(height: 13),

                    const SizedBox(height: 13),

                    // Floating Stats Board
                    ExpandableDashboardCard(
                      completedCount: completedCount,
                      totalLevelsCount: totalLevelsCount,
                      memorizedAyahs: memorizedAyahs,
                      totalAyahs: totalAyahs,
                      streak: streak,
                      overallProgress: overallProgress,
                      listenProgress: listenProgress,
                      readProgress: readProgress,
                    ),

                    // Removed Quick Access Spiritual Hub based on user request
                  ],
                ),
              ),
            ),

            // 4. Persistent Floating Footer (Extract Premium Widget) with Dynamic Auto-Hide Logic!
            ValueListenableBuilder<bool>(
              valueListenable: _showFooterNotifier,
              builder: (context, isVisible, _) {
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutQuart,
                  bottom: isVisible
                      ? 115
                      : -120, // Slide down totally out of bounds when hidden!
                  left: 16,
                  right: 16,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: isVisible ? 1.0 : 0.0,
                    child: ActiveLevelFooter(
                      currentLevel: activeLevelSeq,
                      levelDetails: 'سورة $activeLevelTitle',
                      onStart: () {
                        // 1. Immediate action: Open the Level Sheet so the user can start instantly!
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              StationTasksSheet(level: activeLevel),
                        );

                        // 2. Background aesthetic: Fast scroll back into focus range!
                        if (_scrollController.hasClients &&
                            _cachedActiveNodeY > 0) {
                          final double offset = (_cachedActiveNodeY - 350.0)
                              .clamp(
                                0.0,
                                _scrollController.position.maxScrollExtent,
                              );
                          _scrollController.animateTo(
                            offset,
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.fastOutSlowIn,
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic procedural map rendering with injected Section Breaks every 10 levels
  Widget _buildPrecisePathMap(GameState gameState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levels = gameState.levels;
    final double width = MediaQuery.of(context).size.width;
    final double centerX = width / 2;

    final int totalLevels = levels.length;
    final double spacingY = 260.0;
    final double headerGap =
        140.0; // Extra space reserved for injected Station Headers

    final List<Offset> offsets = [];
    final Map<int, double> headerLocationsY = {}; // Store where headers appear

    double currentY =
        70.0; // Reduced starting top padding to compress vertical distance from title

    for (int index = 0; index < totalLevels; index++) {
      // Check for insertion of dynamic Section Divider every 10 levels (e.g., Level 1, 11, 21...)
      if (index % 10 == 0) {
        headerLocationsY[index] = currentY;
        currentY +=
            headerGap; // Expand map content to fit the injected visual header
      }

      double dx = centerX;
      if (index % 4 == 1) {
        dx += 90;
      } else if (index % 4 == 3) {
        dx -= 90;
      }

      offsets.add(Offset(dx, currentY));
      currentY += spacingY;
    }

    final double mapTotalHeight = currentY + 200.0;

    int activeVisualIdx = levels.indexWhere(
      (l) => l.isUnlocked && !l.isCompleted,
    );
    if (activeVisualIdx == -1) activeVisualIdx = 0;

    // Cache the Y coordinate for the auto-scroll logic in initState
    _cachedActiveNodeY = offsets[activeVisualIdx].dy;

    return SizedBox(
      height: mapTotalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Path rendering painter layer
          Positioned.fill(
            child: CustomPaint(
              painter: RefinedPathPainter(
                offsets: offsets,
                activeIndex: activeVisualIdx,
                isDark: isDark,
              ),
            ),
          ),

          // Render Injected Section Headers (Station Break banners)
          ...headerLocationsY.entries.map((entry) {
            final stationNum = (entry.key ~/ 10) + 1;
            return Positioned(
              top: entry.value - 40,
              left: 16,
              right: 16,
              child: StationSectionHeader(stationNumber: stationNum),
            );
          }),

          // Iterate and place individual Game Nodes
          for (int i = 0; i < levels.length; i++)
            Positioned(
              left: offsets[i].dx - 75,
              top: offsets[i].dy - 75,
              width: 150,
              child: GestureDetector(
                onTap: () {
                  // Safeguard: Only allow clicking unlocked levels!
                  if (levels[i].isUnlocked) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => StationTasksSheet(level: levels[i]),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'هذا المستوى مغلق، أكمل المستويات السابقة أولاً',
                        ),
                      ),
                    );
                  }
                },
                child: GameLevelNode(level: levels[i]),
              ),
            ),
        ],
      ),
    );
  }
}
