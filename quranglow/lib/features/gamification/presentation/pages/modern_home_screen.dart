import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/widgets/components/station_tasks_sheet.dart';
import 'package:quranglow/features/gamification/presentation/widgets/modern_home/refined_path_painter.dart';
import 'package:quranglow/features/gamification/presentation/widgets/modern_home/active_level_footer.dart';

class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen> {
  final double _rowHeight = 220.0;
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
          final double centerViewOffset = (_cachedActiveNodeY - 350.0).clamp(0.0, _scrollController.position.maxScrollExtent);
          _scrollController.animateTo(
            centerViewOffset,
            duration: const Duration(milliseconds: 1600),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
      
      // 2. Show the Goal Selection Dialog automatically on launch!
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _showGoalSelectorBottomSheet(context);
        }
      });
    });
  }

  void _onScrollUpdate() {
    if (!_scrollController.hasClients || _cachedActiveNodeY < 0) return;
    
    final double scrollOffset = _scrollController.offset;
    
    // Smart Visibility Logic: Detect if the Active Node is physically within the primary viewport range!
    // The viewport height is typically 700-900px. 
    // If node is roughly between scrollOffset and scrollOffset + 600, it's in view!
    final bool isNodeInViewport = (scrollOffset > _cachedActiveNodeY - 700) && 
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
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (gameState) {
        // PRE-CALCULATE the EXACT target Y coordinate of the Active Node once during build cycle
        // This synchronizes with actual render offsets generator logic!
        final levels = gameState.levels;
        int activeIdx = levels.indexWhere((l) => l.isUnlocked && !l.isCompleted);
        if (activeIdx == -1) activeIdx = 0;
        
        double currentY = 150.0;
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

  Widget _buildContent(GameState gameState, String activeLevelTitle, int activeLevelSeq) {
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

        // 2. Soft glowing orb mesh background (Extreme Premium)
        Positioned(
          top: -120,
          right: -80,
          child:
              Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2E7D32,
                          ).withValues(alpha: 0.25),
                          blurRadius: 100,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    duration: 5.seconds,
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                  ),
        ),
        Positioned(
          top: 350,
          left: -120,
          child:
              Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF8B6F47,
                          ).withValues(alpha: 0.15),
                          blurRadius: 120,
                          spreadRadius: 60,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    duration: 6.seconds,
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                  ),
        ),

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
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                              fontSize: 26, // Slightly scaled down for elegance
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

              // 3b. Top Stats Tile (Grouped Glassmorphism as requested)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildIconStatItem(
                          iconPath: 'assets/images/moon.png',
                          isCrescent: true,
                          title: 'الأوراد المنجزة',
                          value: '15/30 أوراد',
                        ),
                        _buildIconStatItem(
                          iconData: Icons.menu_book_rounded,
                          title: 'الآيات المحفوظة',
                          value: '450/1205 آية',
                        ),
                        _buildIconStatItem(
                          iconData: Icons.calendar_month_rounded,
                          title: 'الالتزام اليومي',
                          value: '25 يوم',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3c. Top Progress Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF223E2D).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '%',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'نسبة التقدم',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.trending_up_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: 0.85,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFBBD068),
                                    Color(0xFF89A658),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),


              const SliverToBoxAdapter(child: SizedBox(height: 40)),

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
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          '1 من 781 مستوى',
                          style: TextStyle(color: Colors.white60, fontSize: 14),
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
              bottom: isVisible ? 115 : -120, // Slide down totally out of bounds when hidden!
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: isVisible ? 1.0 : 0.0,
                child: ActiveLevelFooter(
                  currentLevel: activeLevelSeq,
                  levelDetails: 'سورة $activeLevelTitle',
                  onStart: () {
                    // Immediate shortcut handler
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

  Widget _buildIconStatItem({
    IconData? iconData,
    String? iconPath,
    required String title,
    required String value,
    bool isCrescent = false,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isCrescent)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            isCrescent
                ? const Icon(
                    Icons.nights_stay_rounded,
                    color: Color(0xFFFFF59D),
                    size: 34,
                  )
                : Icon(iconData, color: Colors.white70, size: 32),
          ],
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.white60)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  // Dynamic procedural map rendering with injected Section Breaks every 10 levels
  Widget _buildPrecisePathMap(GameState gameState) {
    final levels = gameState.levels;
    final double width = MediaQuery.of(context).size.width;
    final double centerX = width / 2;

    final int totalLevels = levels.length;
    final double spacingY = 320.0;
    final double headerGap = 220.0; // Extra space reserved for injected Station Headers

    final List<Offset> offsets = [];
    final Map<int, double> headerLocationsY = {}; // Store where headers appear

    double currentY = 150.0;

    for (int index = 0; index < totalLevels; index++) {
      // Check for insertion of dynamic Section Divider every 10 levels (e.g., Level 1, 11, 21...)
      if (index % 10 == 0) {
        headerLocationsY[index] = currentY;
        currentY += headerGap; // Expand map content to fit the injected visual header
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

    int activeVisualIdx = levels.indexWhere((l) => l.isUnlocked && !l.isCompleted);
    if (activeVisualIdx == -1) activeVisualIdx = 0;

    return SizedBox(
      height: mapTotalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Path rendering painter layer
          Positioned.fill(
            child: CustomPaint(
              painter: RefinedPathPainter(offsets: offsets, activeIndex: activeVisualIdx),
            ),
          ),

          // Render Injected Section Headers (Station Break banners)
          ...headerLocationsY.entries.map((entry) {
            final stationNum = (entry.key ~/ 10) + 1;
            return Positioned(
              top: entry.value - 40,
              left: 16,
              right: 16,
              child: _buildSectionHeader(stationNum),
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
                      const SnackBar(content: Text('هذا المستوى مغلق، أكمل المستويات السابقة أولاً')),
                    );
                  }
                },
                child: _buildRefinedNode(levels[i]),
              ),
            ),
        ],
      ),
    );
  }

  // Fully dynamics Node Generator tied directly to persistent GameLevel state schema
  Widget _buildRefinedNode(GameLevel level) {
    String assetPath = 'assets/images/gate_locked.png';
    bool isCompleted = level.isCompleted;
    bool isActive = level.isUnlocked && !level.isCompleted;
    bool isLocked = !level.isUnlocked;

    if (isCompleted) {
      assetPath = 'assets/images/quran_completed.png';
    } else if (isActive) {
      assetPath = 'assets/images/gate_active.png';
    } else {
      // Visual distinction for locked gates (unlocked-visual vs locked-padlock alternate)
      assetPath = (level.sequence % 2 == 0) 
          ? 'assets/images/gate_unlocked.png' 
          : 'assets/images/gate_locked.png';
    }

    final title = 'آيات ${level.ayahStart}-${level.ayahEnd}';
    final subTitle = level.surahName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars Above Completed Nodes
        if (isCompleted)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              level.starsEarned > 0 ? level.starsEarned : 3,
              (x) => Icon(
                Icons.star_rounded,
                color: const Color(0xFFE0B566).withValues(alpha: 0.8),
                size: 16,
              ),
            ),
          )
        else
          const SizedBox(height: 16),

        // Visual Asset
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Subtle Ground Drop Shadow
            Positioned(
              bottom: 10,
              child: Container(
                width: 60,
                height: 15,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Majestic Concentric Glow Rings surrounding node
            Container(
                  width: isActive ? 130 : 110,
                  height: isActive ? 130 : 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isActive ? const Color(0xFFBDE156) : Colors.white)
                          .withValues(alpha: isActive ? 0.4 : 0.15),
                      width: 1.5,
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  duration: 3.seconds,
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  curve: Curves.easeInOutSine,
                ),

            if (isActive)
              // Outer pulsating circle for active highlight
              Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFBDE156).withValues(alpha: 0.15),
                        width: 1.0,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    duration: 2.seconds,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.1, 1.1),
                  )
                  .fadeOut(duration: 2.seconds),

            if (isActive)
              // Backlight glow for the plant arch
              Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFE082).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    duration: 1.5.seconds,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.1, 1.1),
                  ),

            Image.asset(
              assetPath,
              width: isActive
                  ? 125
                  : isLocked
                  ? 115
                  : 105,
              height: isActive
                  ? 125
                  : isLocked
                  ? 115
                  : 105,
              fit: BoxFit.contain,
            ),
          ],
        ),

        // Subtitles beneath non-locked nodes
        if (!isLocked)
          Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                subTitle,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildGoalSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'حدد هدفك اليومي للمراجعة:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [10, 20, 30].map((goal) {
              final isActive = _dailyGoal == goal;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _dailyGoal = goal),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF4E7440)
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF4E7440,
                                ).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$goal',
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            color: isActive ? Colors.white : Colors.white70,
                          ),
                        ),
                        Text(
                          'آية / يوم',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white70 : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Beautiful modal launcher to trigger immediate user goal setup!
  void _showGoalSelectorBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF15251B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'اختر وردك القرآني المفضل',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'حدد هدف المراجعة اليومية للبدء في رحلة الحفظ الممتعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                _buildGoalSelector(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBDE156),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'حفظ والانطلاق',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Visual Section Header inserted every 10 levels to break progress into readable Stations
  Widget _buildSectionHeader(int stationNumber) {
    // Map arabic numbering or themes based on station number logic
    final title = 'المحطة $stationNumber';
    final subtitle = 'المرحلة القادمة من رحلة النور';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFBDE156).withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Station Icon Box
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFFBDE156).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBDE156).withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.flag_circle_rounded,
              color: Color(0xFFBDE156),
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
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
