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
        backgroundColor: const Color(0xFFF8F3E6), // Soft sandy beige
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
        // 1. Background Layer (Gradient + Pattern)
        Positioned.fill(child: _buildBackground()),

        // 2. Main Content Scroll
        Positioned.fill(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Safe Area Spacer
              const SliverToBoxAdapter(child: SizedBox(height: 44)),

              // Header (Title & Stats)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildHeaderSection(gameState),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Today's Review Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildReviewSection(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // The Progression Path (Map)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildPathTitle(gameState),
                ),
              ),

              SliverToBoxAdapter(
                child: _buildProgressionMap(gameState),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1B3224), // Deep Dark Olive
            Color(0xFF274532), // Dark Green
            Color(0xFFE8DDC9), // Lighter Blend
            Color(0xFFF8F3E6), // Sandy Beige
          ],
          stops: [0.0, 0.25, 0.5, 0.7],
        ),
      ),
      child: Stack(
        children: [
          // Transparent tiled pattern watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/islamic_pattern.png',
                repeat: ImageRepeat.repeat,
                color: Colors.white,
                blendMode: BlendMode.dstATop,
              ),
            ),
          ),
          // Bottom large decorative watermarks for visuals like screenshot
          Positioned(
            bottom: -50,
            right: -50,
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/islamic_pattern.png',
                width: 250,
                height: 250,
                color: Colors.black,
              ),
            ),
          ),
          Positioned(
            top: 250,
            left: -80,
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/islamic_pattern.png',
                width: 250,
                height: 250,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(GameState gameState) {
    final user = gameState.userProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Bar with Menu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مسار الحفظ',
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'درب التميز',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              icon: Icons.nights_stay,
              title: 'الأوراد المنجزة',
              value: '15/30 أوراد',
              glowColor: Colors.amber,
            ),
            _buildStatItem(
              icon: Icons.auto_stories_rounded,
              title: 'الآيات المحفوظة',
              value: '${user.totalXp ~/ 10} آية', // Simulating based on XP
              glowColor: Colors.lightBlueAccent,
            ),
            _buildStatItem(
              icon: Icons.calendar_today_rounded,
              title: 'الالتزام اليومي',
              value: '${user.currentStreak} يوم',
              glowColor: Colors.greenAccent,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Progress Bar Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '%',
                    style: GoogleFonts.cairo(
                      color: Colors.white60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'نسبة التقدم',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.insights_rounded, color: Colors.white70, size: 20),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.75, // Hardcoded matching example image
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.yellow.shade700,
                              Colors.greenAccent.shade400,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color glowColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'مراجعة اليوم',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          'المستويات التي حان وقت تثبيتها',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 12),
        
        // Glassmorphic Challenge Card
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B22).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تحدي السكينة',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'لقد أتممت مراجعة اليوم بنجاح!',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.nights_stay, color: Colors.white30, size: 40),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A4031),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'ابدأ',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPathTitle(GameState gameState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF2E4A3A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'مسار الحفظ',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A2B22),
              ),
            ),
          ],
        ),
        Text(
          '${gameState.completedLevels} من ${gameState.levels.length} مستوى',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressionMap(GameState gameState) {
    final double width = MediaQuery.of(context).size.width;
    final int total = gameState.levels.length;

    return SizedBox(
      height: total * _rowHeight + 100,
      child: Stack(
        children: [
          // Curved Path Line
          Positioned.fill(
            child: CustomPaint(
              painter: _PathPainter(
                count: total,
                rowHeight: _rowHeight,
                completedCount: gameState.completedLevels,
              ),
            ),
          ),

          // Nodes Layout
          ...List.generate(total, (index) {
            final level = gameState.levels[index];
            final isActive = level.id == gameState.currentLevel?.id;

            // Position Math matched with CustomPainter
            final double dx = width / 2 + math.sin(index * 1.1) * 80;
            final double dy = index * _rowHeight + 40;

            return Positioned(
              left: dx - 80,
              top: dy,
              width: 160,
              child: _buildNodeWidget(level, isActive),
            );
          }),
          
          // Add intermediate treasure chest example at index 0.5
          if (total > 1)
            Positioned(
              left: width / 2 - 40,
              top: _rowHeight * 0.6,
              child: Image.asset(
                'assets/images/chest.png',
                width: 70,
                height: 70,
              ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
            ),
        ],
      ),
    );
  }

  Widget _buildNodeWidget(GameLevel level, bool isActive) {
    final bool isCompleted = level.isCompleted;
    final bool isLocked = !level.isUnlocked;

    String assetPath;
    if (isCompleted) {
      assetPath = 'assets/images/quran_completed.png';
    } else if (isActive) {
      assetPath = 'assets/images/gate_active.png';
    } else if (isLocked) {
      assetPath = 'assets/images/gate_locked.png';
    } else {
      assetPath = 'assets/images/gate_unlocked.png';
    }

    return GestureDetector(
      onTap: isLocked ? null : () => _openLevel(level),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star Rating Above for completed ones
          if (isCompleted)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => const Icon(Icons.star_rounded, color: Colors.amber, size: 16)),
            )
          else
            const SizedBox(height: 16),

          // The 3D Visual Node
          Stack(
            alignment: Alignment.center,
            children: [
              // Active Glow Effect
              if (isActive)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.8, 0.8), duration: 1.5.seconds),

              // The Main Asset Image
              Image.asset(
                assetPath,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey.shade300.withValues(alpha: 0.5) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'مستوى ${level.sequence}:',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isLocked ? Colors.grey.shade700 : const Color(0xFF1A2B22),
                  ),
                ),
                Text(
                  '${level.surahName} ${level.ayahStart}-${level.ayahEnd}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: isLocked ? Colors.grey.shade600 : const Color(0xFF3A4B42),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openLevel(GameLevel level) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StationTasksSheet(level: level),
    );
  }
}

// Helper CustomPainter for the path connector
class _PathPainter extends CustomPainter {
  final int count;
  final double rowHeight;
  final int completedCount;

  _PathPainter({
    required this.count,
    required this.rowHeight,
    required this.completedCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;

    final double width = size.width;

    final path = Path();
    Offset last = _getOffset(0, width);
    path.moveTo(last.dx, last.dy);

    for (int i = 1; i < count; i++) {
      final current = _getOffset(i, width);
      
      // Build organic quadratic curve logic
      final ctrlX = (last.dx + current.dx) / 2 + math.cos(i * 0.8) * 40;
      final ctrlY = (last.dy + current.dy) / 2;

      path.quadraticBezierTo(ctrlX, ctrlY, current.dx, current.dy);
      last = current;
    }

    // Main Line paint
    final paint = Paint()
      ..color = const Color(0xFF556C5B).withValues(alpha: 0.5) // Soft darker line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  Offset _getOffset(int index, double totalWidth) {
    final double dx = totalWidth / 2 + math.sin(index * 1.1) * 80;
    // Shift downward to match the Node images exact center anchor
    final double dy = index * rowHeight + 40 + 60; 
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
