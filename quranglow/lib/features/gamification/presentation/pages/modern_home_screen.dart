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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (gameState) {
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

        return _buildContent(gameState, activeLevelTitle, activeIdx + 1);
      },
    );
  }

  Widget _buildContent(
    GameState gameState,
    String activeLevelTitle,
    int activeLevelSeq,
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFC1B298),
        body: Stack(
          children: [
            // 1. Premium Generated Visual Background Layer
            Positioned.fill(
              child: Image.asset('assets/images/app_bg.png', fit: BoxFit.cover),
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
                  color: Colors.white, // Light overlay texture
                ),
              ),
            ),

            // The soft glowing orb containers removed as requested

            // 3. Scrollable Content
            Positioned.fill(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 45),
                  ), // Balanced breathing room for status bar
                  // 3a. Header: Top Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. The Drawer Button placed first (RTL will map to physical RIGHT)
                          GestureDetector(
                            onTap: () => Scaffold.of(context).openDrawer(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: const Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // 2. The Centered Titles
                          Column(
                            children: [
                              const Text(
                                'مسار الحفظ',
                                style: TextStyle(
                                  fontSize:
                                      26, // Slightly scaled down for elegance
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'درب التميز',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),

                          // 3. The balancing spacer placed last (RTL maps to physical LEFT)
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // 3b. The Modular Dashboard Widget extracted for neatness!
                  SliverToBoxAdapter(
                    child: ExpandableDashboardCard(
                      completedCount: completedCount,
                      totalLevelsCount: totalLevelsCount,
                      memorizedAyahs: memorizedAyahs,
                      totalAyahs: totalAyahs,
                      streak: streak,
                      overallProgress: overallProgress,
                      listenProgress: listenProgress,
                      readProgress: readProgress,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

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
                                  const SizedBox(width: 12),
                                  Text(
                                    'مسار الحفظ',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
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
                                color: Colors.white60,
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
                        // Fast scroll back into focus range of active level!
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
    final levels = gameState.levels;
    final double width = MediaQuery.of(context).size.width;
    final double centerX = width / 2;

    final int totalLevels = levels.length;
    final double spacingY = 320.0;
    final double headerGap =
        220.0; // Extra space reserved for injected Station Headers

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
