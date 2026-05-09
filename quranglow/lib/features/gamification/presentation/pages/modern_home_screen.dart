import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

        // 2. Global Decorative Mandalas background
        Positioned(
          right: -80,
          bottom: 80,
          child: Opacity(
            opacity: 0.08,
            child: Image.asset(
              'assets/images/islamic_pattern.png',
              width: 300,
              height: 300,
              color: Colors.black,
            ),
          ),
        ),
        Positioned(
          left: -100,
          bottom: 250,
          child: Opacity(
            opacity: 0.08,
            child: Image.asset(
              'assets/images/islamic_pattern.png',
              width: 300,
              height: 300,
              color: Colors.black,
            ),
          ),
        ),

        // 3. Scrollable Content
        Positioned.fill(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 48)),

              // 3a. Header: Top Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48), // placeholder for symmetry
                      Column(
                        children: [
                          Text(
                            'مسار الحفظ',
                            style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            'درب التميز',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_rounded, color: Colors.white70),
                      ),
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
                              style: GoogleFonts.cairo(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'نسبة التقدم',
                                  style: GoogleFonts.cairo(
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
                                style: GoogleFonts.cairo(
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
                          style: GoogleFonts.cairo(
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
                            style: GoogleFonts.cairo(
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
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'لقد أتممت مراجعة اليوم بنجاح!',
                              style: GoogleFonts.cairo(
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
                                style: GoogleFonts.cairo(
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
                          style: GoogleFonts.cairo(
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

        // 4. Custom Bottom Navigation matching image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomNav(),
        ),
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
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.white60),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
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
      Offset(centerX - 80, 80),       // Node 0 (Top Left)
      Offset(centerX + 80, 120),      // Node 1 (Top Right)
      Offset(centerX, 340),           // Node 2 (Active Center)
      Offset(centerX - 90, 550),      // Node 3 (Bottom Left)
      Offset(centerX + 90, 650),      // Node 4 (Bottom Right)
    ];

    return SizedBox(
      height: 800,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Painting Layer (Path lines + diagonal deco stripes)
          Positioned.fill(
            child: CustomPaint(
              painter: _RefinedPathPainter(offsets: offsets),
            ),
          ),

          // Intermediate Chest placed between Node 0 and 1 visually
          Positioned(
            left: centerX - 35,
            top: 100,
            child: Image.asset('assets/images/chest.png', width: 70, height: 70)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
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
              width: isActive ? 140 : isLocked ? 130 : 110,
              height: isActive ? 140 : isLocked ? 130 : 110,
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
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                subTitle,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: Color(0xFF25331D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.person_outline_rounded, 'الملف الشخصي', false),
          _buildNavItem(Icons.bubble_chart_outlined, 'الأذكار', false),
          _buildNavItem(Icons.volunteer_activism_outlined, 'التبرعات', false),
          _buildNavItem(Icons.menu_book_rounded, 'المصحف', false),
          _buildNavItem(Icons.bar_chart_rounded, 'الإحصاءات', false),
          _buildNavItem(Icons.map_rounded, 'الرئيسية', true),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isActive ? 8 : 0),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF425236) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFFB5CCAA) : Colors.white54,
            size: 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: isActive ? const Color(0xFFB5CCAA) : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _RefinedPathPainter extends CustomPainter {
  final List<Offset> offsets;

  _RefinedPathPainter({required this.offsets});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background Decorative Diagonal Stripes just like in screenshot!
    final stripePaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.square;

    // Drawing distinct diagonal background lines seen in visual
    canvas.drawLine(const Offset(0, 500), const Offset(250, 750), stripePaint);
    canvas.drawLine(const Offset(0, 540), const Offset(220, 760), stripePaint);
    
    if (offsets.length < 2) return;

    // 2. Draw The Curvy Progression Path
    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    // Manual precise quadratic paths following exactly screenshot visual curve shape
    
    // Segment 0 -> 1 (Soft curve across top)
    final ctrl1X = (offsets[0].dx + offsets[1].dx) / 2;
    final ctrl1Y = (offsets[0].dy + offsets[1].dy) / 2 + 20;
    path.quadraticBezierTo(ctrl1X, ctrl1Y, offsets[1].dx, offsets[1].dy);

    // Segment 1 -> 2 (Deep curve flowing right then center down)
    // Point 1 is right, Point 2 is center down. Control point is far right down.
    final ctrl2X = offsets[1].dx + 40;
    final ctrl2Y = (offsets[1].dy + offsets[2].dy) / 2;
    path.quadraticBezierTo(ctrl2X, ctrl2Y, offsets[2].dx, offsets[2].dy);

    // Segment 2 -> 3 (Curve flow from center down to left)
    final ctrl3X = offsets[2].dx - 50;
    final ctrl3Y = (offsets[2].dy + offsets[3].dy) / 2;
    path.quadraticBezierTo(ctrl3X, ctrl3Y, offsets[3].dx, offsets[3].dy);
    
    // Segment 3 -> 4
    final ctrl4X = (offsets[3].dx + offsets[4].dx) / 2;
    final ctrl4Y = (offsets[3].dy + offsets[4].dy) / 2 + 20;
    path.quadraticBezierTo(ctrl4X, ctrl4Y, offsets[4].dx, offsets[4].dy);

    // Main thick path line
    final pathPaint = Paint()
      ..color = const Color(0xFF34493A).withValues(alpha: 0.4) // Visual match
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
