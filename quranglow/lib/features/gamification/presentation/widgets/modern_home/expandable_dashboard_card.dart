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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic Theme Palettes
    final Color cardColor = isDark
        ? (_isStatsExpanded ? const Color(0xFF1A3022).withValues(alpha: 0.92) : Colors.black.withValues(alpha: 0.2))
        : (_isStatsExpanded ? Colors.white.withValues(alpha: 0.98) : Colors.white.withValues(alpha: 0.88));

    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: _isStatsExpanded ? 0.15 : 0.08)
        : const Color(0xFF1B5E20).withValues(alpha: _isStatsExpanded ? 0.15 : 0.10);

    final Color shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : const Color(0xFF1A3022).withValues(alpha: 0.15);

    final Color primaryText = isDark ? Colors.white : const Color(0xFF1A3022);
    final Color secondaryText = isDark ? Colors.white70 : const Color(0xFF1A3022).withValues(alpha: 0.65);
    final Color iconColor = isDark ? Colors.white70 : const Color(0xFF1B5E20).withValues(alpha: 0.8);

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
            color: cardColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 22,
                offset: const Offset(0, 8),
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
                    isDark: isDark,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    iconColor: iconColor,
                  ),
                  _buildIconStatItem(
                    iconData: Icons.menu_book_rounded,
                    title: 'الآيات المحفوظة',
                    value: '${widget.memorizedAyahs}/${widget.totalAyahs} آية',
                    isDark: isDark,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    iconColor: iconColor,
                  ),
                  _buildIconStatItem(
                    iconData: Icons.calendar_month_rounded,
                    title: 'الالتزام اليومي',
                    value: '${widget.streak} يوم',
                    isDark: isDark,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    iconColor: iconColor,
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
                          color: secondaryText.withValues(alpha: 0.5),
                          size: 22,
                        )
                      : Column(
                          key: const ValueKey('expanded_dashboard'),
                          children: [
                            Divider(
                              color: isDark ? Colors.white10 : const Color(0xFF1B5E20).withValues(alpha: 0.08), 
                              height: 24, 
                              thickness: 1.2
                            ),
                            
                            // Custom Styled Top Row for Expanded
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.trending_up_rounded, color: Color(0xFF689F38), size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'معدل الإنجاز الكلي',
                                          style: TextStyle(color: secondaryText, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(widget.overallProgress * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        color: primaryText,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF689F38).withValues(alpha: 0.12), 
                                    borderRadius: BorderRadius.circular(15)
                                  ),
                                  child: const Text(
                                    'مستوى التميز',
                                    style: TextStyle(color: Color(0xFF33691E), fontWeight: FontWeight.w900, fontSize: 10),
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
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black26 : const Color(0xFF1B5E20).withValues(alpha: 0.05), 
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: widget.overallProgress.clamp(0.02, 1.0),
                                  child: Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF689F38), Color(0xFF8BC34A), Color(0xFFDCEDC8)]),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF8BC34A).withValues(alpha: 0.3), blurRadius: 6),
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
                                    accentColor: const Color(0xFF00796B),
                                    isDark: isDark,
                                    secondaryText: secondaryText,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildMiniProgressItem(
                                    title: 'التقدم الكتابي',
                                    icon: Icons.edit_note_rounded,
                                    progress: widget.readProgress,
                                    accentColor: const Color(0xFFE65100),
                                    isDark: isDark,
                                    secondaryText: secondaryText,
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
                                color: const Color(0xFF689F38).withValues(alpha: isDark ? 0.12 : 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF689F38).withValues(alpha: 0.18)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF689F38), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      getMotivationalPrompt(widget.overallProgress),
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFFDCEDC8) : const Color(0xFF33691E), 
                                        fontSize: 12, 
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: secondaryText.withValues(alpha: 0.5),
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
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
    required Color iconColor,
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
                      color: const Color(0xFFFFD54F).withValues(alpha: isDark ? 0.3 : 0.15),
                      blurRadius: 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            isCrescent
                ? const Icon(
                    Icons.nights_stay_rounded,
                    color: Color(0xFFFFC107),
                    size: 34,
                  )
                : Icon(iconData, color: iconColor, size: 32),
          ],
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 11, color: secondaryText, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: primaryText,
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
    required bool isDark,
    required Color secondaryText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: secondaryText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 11, color: secondaryText, fontWeight: FontWeight.w500),
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
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF1B5E20).withValues(alpha: 0.06),
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
                      color: accentColor.withValues(alpha: 0.2),
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
