import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/widgets/components/station_tasks_sheet.dart';

class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen> {
  final double _rowHeight = 220.0;
  late final ScrollController _scrollController;
  int _dailyGoal = 10; // Default selection

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Dynamic scroll focusing to roughly around 600-700 range to match our upcoming vertical scale!
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            650.0, // Perfect center target for stretched map
            duration: const Duration(milliseconds: 1200),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameStateAsync = ref.watch(gamificationControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFC1B298), // Darker sandy base
        body: gameStateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
          data: (gameState) => _buildContent(gameState),
        ),
      ),
    );
  }

  Widget _buildContent(GameState gameState) {
    return Stack(
      children: [
        // 1. Base Background Layer (Precise Gradient match)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF101812), // Near Black Green Top
                  Color(0xFF1D3527), // Deep Green Main
                  Color(0xFF504232), // Deep Sandy Brown transition
                  Color(0xFFD4C4AA), // Light Sandy Bottom
                ],
                stops: [0.0, 0.2, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // 2. Soft glowing orb mesh background (Extreme Premium)
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 5.seconds, begin: const Offset(1,1), end: const Offset(1.3, 1.3)),
        ),
        Positioned(
          top: 300,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B6F47).withValues(alpha: 0.1),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 6.seconds, begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
        ),

        // 3. Scrollable Content
        Positioned.fill(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 3a. Header: Top Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1. The Drawer Button placed first (RTL will map to physical RIGHT)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_rounded, color: Colors.white70),
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

              // 3b. Top Stats Row (Precise layout from image)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Item: Glowing Moon
                      _buildIconStatItem(
                        iconPath: 'assets/images/moon.png', // Fallback to icon for now, but glow it
                        isCrescent: true,
                        title: 'الأوراد المنجزة',
                        value: '15/30 أوراد',
                      ),
                      // Center Item: Book
                      _buildIconStatItem(
                        iconData: Icons.menu_book_rounded,
                        title: 'الآيات المحفوظة',
                        value: '1205 آية',
                      ),
                      // Right Item: Calendar
                      _buildIconStatItem(
                        iconData: Icons.calendar_month_rounded,
                        title: 'الالتزام اليومي',
                        value: '25 يوم',
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 3x. Goal Selection Injection (New Feature requested)
              SliverToBoxAdapter(
                child: _buildGoalSelector(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

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
                                const Icon(Icons.trending_up_rounded, color: Colors.white, size: 24),
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

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // 3d. Review Today Header Section
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
                                  color: const Color(0xFF839E65),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'مراجعة اليوم',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          'المستويات التي حان وقت تثبيتها',
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

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 3e. Sakeena Challenge Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1C3226).withValues(alpha: 0.9),
                          const Color(0xFF152535).withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3E4F37),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'ابدأ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'تحدي السكينة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'لقد أتممت مراجعة اليوم بنجاح!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.nights_stay_rounded,
                          color: Colors.white30,
                          size: 40,
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
              SliverToBoxAdapter(
                child: _buildPrecisePathMap(gameState),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),

        /* Bottom Nav removed as requested to avoid collision with main navigation */
      ],
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
                ? const Icon(Icons.nights_stay_rounded, color: Color(0xFFFFF59D), size: 34)
                : Icon(iconData, color: Colors.white70, size: 32),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.white60),
        ),
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

  // Redesigned map mapping strictly into visual coordinates of reference
  Widget _buildPrecisePathMap(GameState gameState) {
    final double width = MediaQuery.of(context).size.width;
    final double centerX = width / 2;

    // Define strict pixel placement offsets mapping to visual image structure
    // Index 0: Level 1 (Left-ish)
    // Chest: Center mid-way
    // Index 1: Level 1-2 (Right-ish)
    // Index 2: Level 2 (Active, Center-down)
    // Index 3: Locked with key (Far Left)
    // Index 4: Locked padlock (Far Right)
    
    final offsets = [
      Offset(centerX - 90, 120),       // Node 0 (Stretched Top Left)
      Offset(centerX + 90, 450),      // Node 1 (Heavily Spaced Right)
      Offset(centerX, 850),           // Node 2 (Deep Center Active)
      Offset(centerX - 90, 1250),     // Node 3 (Way down Left)
      Offset(centerX + 90, 1650),     // Node 4 (Bottom Right)
    ];

    return SizedBox(
      height: 1800, // Heavily extended track
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Painting Layer (Path lines + diagonal deco stripes)
          Positioned.fill(
            child: CustomPaint(
              painter: _RefinedPathPainter(offsets: offsets, activeIndex: 2),
            ),
          ),

          // Intermediate Chest placed nicely between Node 0 and 1 visually
          Positioned(
            left: centerX - 35,
            top: 285, // Placed mid-segment vertically
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: 5,
                  child: Container(
                    width: 40,
                    height: 10,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Image.asset('assets/images/chest.png', width: 70, height: 70)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
              ],
            ),
          ),

          // Rendering each Node widget with exact positioning
          for (int i = 0; i < offsets.length; i++)
            Positioned(
              left: offsets[i].dx - 75,
              top: offsets[i].dy - 75,
              width: 150,
              child: _buildRefinedNode(i),
            ),
        ],
      ),
    );
  }

  // Helper to generate hardcoded nodes mapping to specific indices in mockup for realism
  Widget _buildRefinedNode(int nodeIndex) {
    String assetPath = 'assets/images/quran_completed.png';
    bool isCompleted = false;
    bool isActive = false;
    bool isLocked = false;
    String title = '';
    String subTitle = '';
    bool showStars = false;

    switch (nodeIndex) {
      case 0:
        assetPath = 'assets/images/quran_completed.png';
        isCompleted = true;
        showStars = true;
        title = 'مستوى ١:';
        subTitle = 'سورة الفاتحة ١-٧';
        break;
      case 1:
        assetPath = 'assets/images/quran_completed.png';
        isCompleted = true;
        showStars = true;
        title = 'مستوى ١:';
        subTitle = 'سورة البقرة ١-٦';
        break;
      case 2:
        assetPath = 'assets/images/gate_active.png';
        isActive = true;
        title = 'مستوى ٢:';
        subTitle = 'سورة البقرة ١-١٠';
        break;
      case 3:
        assetPath = 'assets/images/gate_unlocked.png'; // Has key in my generation
        isLocked = true;
        break;
      case 4:
        assetPath = 'assets/images/gate_locked.png';
        isLocked = true;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars Above Completed Nodes
        if (showStars)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (x) => Icon(Icons.star_rounded, color: const Color(0xFFE0B566).withValues(alpha: 0.8), size: 16)),
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
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 1.5.seconds, begin: const Offset(0.8,0.8), end: const Offset(1.1,1.1)),
            
            Image.asset(
              assetPath,
              width: isActive ? 105 : isLocked ? 95 : 85,
              height: isActive ? 105 : isLocked ? 95 : 85,
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
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
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: const Color(0xFF4E7440).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
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
}

class _RefinedPathPainter extends CustomPainter {
  final List<Offset> offsets;
  final int activeIndex;

  _RefinedPathPainter({required this.offsets, this.activeIndex = 0});

  @override
  void paint(Canvas canvas, Size size) {
    if (offsets.length < 2) return;

    // 2. Define Shared Curve Geometries
    // 0 -> 1
    final ctrl1X = (offsets[0].dx + offsets[1].dx) / 2;
    final ctrl1Y = (offsets[0].dy + offsets[1].dy) / 2 + 20;

    // 1 -> 2
    final ctrl2X = offsets[1].dx + 40;
    final ctrl2Y = (offsets[1].dy + offsets[2].dy) / 2;

    // 2 -> 3
    final ctrl3X = offsets[2].dx - 50;
    final ctrl3Y = (offsets[2].dy + offsets[3].dy) / 2;

    // 3 -> 4
    final ctrl4X = (offsets[3].dx + offsets[4].dx) / 2;
    final ctrl4Y = (offsets[3].dy + offsets[4].dy) / 2 + 20;

    // 3. Create FULL Track Path
    final fullPath = Path();
    fullPath.moveTo(offsets[0].dx, offsets[0].dy);
    fullPath.quadraticBezierTo(ctrl1X, ctrl1Y, offsets[1].dx, offsets[1].dy);
    fullPath.quadraticBezierTo(ctrl2X, ctrl2Y, offsets[2].dx, offsets[2].dy);
    fullPath.quadraticBezierTo(ctrl3X, ctrl3Y, offsets[3].dx, offsets[3].dy);
    fullPath.quadraticBezierTo(ctrl4X, ctrl4Y, offsets[4].dx, offsets[4].dy);

    // 4. Create ACTIVE Filled Track Path up to current node
    final fillPath = Path();
    fillPath.moveTo(offsets[0].dx, offsets[0].dy);
    
    if (activeIndex >= 1) {
      fillPath.quadraticBezierTo(ctrl1X, ctrl1Y, offsets[1].dx, offsets[1].dy);
    }
    if (activeIndex >= 2) {
      fillPath.quadraticBezierTo(ctrl2X, ctrl2Y, offsets[2].dx, offsets[2].dy);
    }
    if (activeIndex >= 3) {
      fillPath.quadraticBezierTo(ctrl3X, ctrl3Y, offsets[3].dx, offsets[3].dy);
    }
    if (activeIndex >= 4) {
      fillPath.quadraticBezierTo(ctrl4X, ctrl4Y, offsets[4].dx, offsets[4].dy);
    }

    // 5. Drawing Logic
    
    // a. Draw the Empty Base Path (The unlit track)
    final basePaint = Paint()
      ..color = const Color(0xFF2E3F33).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(fullPath, basePaint);

    // b. Draw GLOw under the active fill path (The neon engine)
    final glowPaint = Paint()
      ..color = const Color(0xFFB4D455).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(fillPath, glowPaint);

    // c. Draw Top highlight of fill path (The vibrant green wire)
    final vibrantPaint = Paint()
      ..color = const Color(0xFFBDE156) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(fillPath, vibrantPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

