import 'package:flutter/material.dart';

class ExpandableDashboardCard extends StatefulWidget {
  final int completedCount;
  final int totalLevelsCount;
  final int memorizedAyahs;
  final int totalAyahs;
  final int streak;
  final double overallProgress;
  final double listenProgress;
  final double readProgress;

  const ExpandableDashboardCard({
    super.key,
    required this.completedCount,
    required this.totalLevelsCount,
    required this.memorizedAyahs,
    required this.totalAyahs,
    required this.streak,
    required this.overallProgress,
    required this.listenProgress,
    required this.readProgress,
  });

  @override
  State<ExpandableDashboardCard> createState() => _ExpandableDashboardCardState();
}

class _ExpandableDashboardCardState extends State<ExpandableDashboardCard> {
  bool _isStatsExpanded = false;

  String getMotivationalPrompt(double p) {
    if (p < 0.05) return "عزم المؤمن خيرٌ من عمله.. ابدأ رحلتك اليوم واملأ قلبك بالنور.";
    if (p < 0.35) return "'أحبُّ الأعمالِ إلى الله أدومُها وإنْ قلَّ'.. استمر يا حامل النور.";
    if (p < 0.70) return "بُوركت خُطاك، هِمّة تُناطح السحاب.. أنت تقترب من الهدف العظيم!";
    return "ما شاء الله! 'وفي ذلك فليتنافس المتنافسون'.. ثباتٌ ونورٌ واقتراب.";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    value: '${widget.completedCount}/${widget.totalLevelsCount} أوراد',
                  ),
                  _buildIconStatItem(
                    iconData: Icons.menu_book_rounded,
                    title: 'الآيات المحفوظة',
                    value: '${widget.memorizedAyahs}/${widget.totalAyahs} آية',
                  ),
                  _buildIconStatItem(
                    iconData: Icons.calendar_month_rounded,
                    title: 'الالتزام اليومي',
                    value: '${widget.streak} يوم',
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
                                      '${(widget.overallProgress * 100).toStringAsFixed(1)}%',
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
                                  widthFactor: widget.overallProgress.clamp(0.02, 1.0),
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
                                    progress: widget.listenProgress,
                                    accentColor: const Color(0xFF4DB6AC),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildMiniProgressItem(
                                    title: 'التقدم الكتابي',
                                    icon: Icons.edit_note_rounded,
                                    progress: widget.readProgress,
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
                                      getMotivationalPrompt(widget.overallProgress),
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
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.white60)),
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
}
