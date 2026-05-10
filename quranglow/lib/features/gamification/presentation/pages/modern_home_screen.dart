import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late final ScrollController _scrollController;
  int _dailyGoal = 10; // Default selection

  // High-performance listener to toggle CTA footer visibility dynamically on scroll
  final ValueNotifier<bool> _showFooterNotifier = ValueNotifier(true);
  double _cachedActiveNodeY = -1.0;
  bool _isStatsExpanded = false; // For dynamic toggleable dashboard expansion

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
          _showGoalSelectorBottomSheet(context);
        }
      });
    }
  }

  Future<void> _saveGoalAndMarkSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_goal_selection', true);
    await prefs.setInt('daily_reading_goal', _dailyGoal);
    
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildContent(GameState gameState, String activeLevelTitle, int activeLevelSeq) {
    final levels = gameState.levels;
    final int totalLevelsCount = levels.length;
    final int completedCount = gameState.completedLevels;
    final int totalAyahs = 6236; // Total number of verses in the entire Quran as requested
    final int memorizedAyahs = levels
        .where((l) => l.isCompleted)
        .fold(0, (sum, l) => sum + l.ayahCount);
    
    final int streak = gameState.userProfile.streak;
    final double overallProgress = gameState.overallProgress;

    // Calculate detailed progress breakdowns
    final int totalListened = levels.where((l) => l.isListenCompleted).length;
    final int totalRead = levels.where((l) => l.isReadCompleted).length;
    final double listenProgress = totalLevelsCount == 0 ? 0.0 : totalListened / totalLevelsCount;
    final double readProgress = totalLevelsCount == 0 ? 0.0 : totalRead / totalLevelsCount;

    String getMotivationalPrompt(double p) {
      if (p < 0.05) return "عزم المؤمن خيرٌ من عمله.. ابدأ رحلتك اليوم واملأ قلبك بالنور.";
      if (p < 0.35) return "'أحبُّ الأعمالِ إلى الله أدومُها وإنْ قلَّ'.. استمر يا حامل النور.";
      if (p < 0.70) return "بُوركت خُطاك، هِمّة تُناطح السحاب.. أنت تقترب من الهدف العظيم!";
      return "ما شاء الله! 'وفي ذلك فليتنافس المتنافسون'.. ثباتٌ ونورٌ واقتراب.";
    }

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

              // 3b. Integrated Dashboard Tile: Stats + Click to Expand Progress Detail
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isStatsExpanded = !_isStatsExpanded;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _isStatsExpanded
                            ? const Color(0xFF1A3022).withValues(alpha: 0.92)
                            : Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: _isStatsExpanded ? 0.15 : 0.08),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          // Primary Summary Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildIconStatItem(
                                iconPath: 'assets/images/moon.png',
                                isCrescent: true,
                                title: 'الأوراد المنجزة',
                                value: '$completedCount/$totalLevelsCount أوراد',
                              ),
                              _buildIconStatItem(
                                iconData: Icons.menu_book_rounded,
                                title: 'الآيات المحفوظة',
                                value: '$memorizedAyahs/$totalAyahs آية',
                              ),
                              _buildIconStatItem(
                                iconData: Icons.calendar_month_rounded,
                                title: 'الالتزام اليومي',
                                value: '$streak يوم',
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Fixed Animated Expanded Section utilizing full available width
                          AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: double.infinity,
                              child: !_isStatsExpanded
                                ? Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    size: 22,
                                  )
                                : Column(
                                    key: const ValueKey('expanded_dashboard'),
                                    children: [
                                      const Divider(color: Colors.white10, height: 24, thickness: 1.2),
                                      
                                      // Custom Styled Top Row for Expanded
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.trending_up_rounded, color: Color(0xFFBDE156), size: 18),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'معدل الإنجاز الكلي',
                                                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${(overallProgress * 100).toStringAsFixed(1)}%',
                                                style: const TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                                            child: const Text(
                                              'مستوى التميز',
                                              style: TextStyle(color: Color(0xFFBDE156), fontWeight: FontWeight.bold, fontSize: 10),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      // Sleek Progress Bar
                                      Stack(
                                        children: [
                                          Container(
                                            height: 12,
                                            width: double.infinity,
                                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: overallProgress.clamp(0.02, 1.0),
                                            child: Container(
                                              height: 12,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(colors: [Color(0xFF89A658), Color(0xFFC5E17A), Color(0xFFE6F5BE)]),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(color: const Color(0xFFBDE156).withValues(alpha: 0.3), blurRadius: 6),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      // Audio/Reading split Subprogress
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildMiniProgressItem(
                                              title: 'التقدم الصوتي',
                                              icon: Icons.headphones_rounded,
                                              progress: listenProgress,
                                              accentColor: const Color(0xFF4DB6AC),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: _buildMiniProgressItem(
                                              title: 'التقدم الكتابي',
                                              icon: Icons.edit_note_rounded,
                                              progress: readProgress,
                                              accentColor: const Color(0xFFFFB74D),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 18),

                                      // Motivation box
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFBDE156).withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFFBDE156).withValues(alpha: 0.12)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFBDE156), size: 18),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                getMotivationalPrompt(overallProgress),
                                                style: const TextStyle(color: Color(0xFFD4E8A1), fontSize: 12, height: 1.3),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Icon(
                                        Icons.keyboard_arrow_up_rounded,
                                        color: Colors.white.withValues(alpha: 0.3),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                          '$activeLevelSeq من $totalLevelsCount مستوى',
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

  Widget _buildMiniProgressItem({
    required String title,
    required IconData icon,
    required double progress,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.white60),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
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

    double currentY = 70.0; // Reduced starting top padding to compress vertical distance from title

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

  String _getMotivationalMessage(int goal) {
    switch (goal) {
      case 10:
        return "بداية رائعة! 'أحبُّ الأعمال إلى الله أدومها وإن قلّ'.";
      case 20:
        return "همة مباركة! الاستمرار يورث النور في القلوب والتوفيق في الحياة.";
      case 30:
        return "ما شاء الله! همة كبار.. 'وفي ذلك فليتنافس المتنافسون'.";
      default:
        return "خطوة مباركة للبدء في رحلة القرآن العظيمة.";
    }
  }

  Widget _buildGoalSelector({
    required int currentSelected,
    required ValueChanged<int> onSelected,
  }) {
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
              final isActive = currentSelected == goal;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(goal),
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
                                color: const Color(0xFF4E7440).withValues(alpha: 0.4),
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

  // Beautiful modal launcher with built-in interactive internal state!
  void _showGoalSelectorBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false, // Force choice on first time setup
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    _buildGoalSelector(
                      currentSelected: _dailyGoal,
                      onSelected: (val) {
                        setModalState(() => _dailyGoal = val);
                        // Update external widget too just in case
                        setState(() => _dailyGoal = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Injected dynamic motivational prompt banner
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey<int>(_dailyGoal),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBDE156).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBDE156).withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          _getMotivationalMessage(_dailyGoal),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFC5E17A),
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
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
                        onPressed: () {
                          Navigator.pop(context);
                          _saveGoalAndMarkSeen(); // Perform save logic and trigger Toast!
                        },
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
