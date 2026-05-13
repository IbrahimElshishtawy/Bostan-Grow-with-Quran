import 'package:flutter/material.dart';

class GoalSelectorSheet extends StatefulWidget {
  final int initialGoal;
  final Function(int) onSave;

  const GoalSelectorSheet({
    super.key,
    required this.initialGoal,
    required this.onSave,
  });

  static void show(BuildContext context, {required int initialGoal, required Function(int) onSave}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false, // Force choice on first time setup
      builder: (context) => GoalSelectorSheet(initialGoal: initialGoal, onSave: onSave),
    );
  }

  @override
  State<GoalSelectorSheet> createState() => _GoalSelectorSheetState();
}

class _GoalSelectorSheetState extends State<GoalSelectorSheet> {
  late int _dailyGoal;

  @override
  void initState() {
    super.initState();
    _dailyGoal = widget.initialGoal;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic color assignments based on system brightness
    final sheetBgColor = isDark ? const Color(0xFF15251B) : const Color(0xFFF9FBF8);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1A3022);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF1A3022).withValues(alpha: 0.6);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF1B5E20).withValues(alpha: 0.08);
    final handleColor = isDark ? Colors.white24 : const Color(0xFF1B5E20).withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
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
                color: handleColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'اختر وردك القرآني المفضل',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'حدد هدف المراجعة اليومية للبدء في رحلة الحفظ الممتعة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor, 
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            
            // The dynamic interactive selector
            _buildGoalSelector(
              isDark: isDark, 
              primaryTextColor: primaryTextColor,
            ),
            
            const SizedBox(height: 24),
            
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey<int>(_dailyGoal),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF689F38).withValues(alpha: isDark ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF689F38).withValues(alpha: 0.15)),
                ),
                child: Text(
                  _getMotivationalMessage(_dailyGoal),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFDCEDC8) : const Color(0xFF33691E),
                    fontStyle: FontStyle.italic,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
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
                  backgroundColor: const Color(0xFF689F38),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSave(_dailyGoal);
                },
                child: const Text(
                  'حفظ والانطلاق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSelector({
    required bool isDark,
    required Color primaryTextColor,
  }) {
    final Color inactiveBg = isDark 
        ? Colors.black.withValues(alpha: 0.25) 
        : const Color(0xFF1A3022).withValues(alpha: 0.04);
        
    final Color activeBg = const Color(0xFF689F38);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'حدد هدفك اليومي للمراجعة:',
              style: TextStyle(
                color: primaryTextColor.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [10, 20, 30].map((goal) {
              final isActive = _dailyGoal == goal;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _dailyGoal = goal;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutQuad,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isActive ? activeBg : inactiveBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.25)
                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
                        width: 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: activeBg.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$goal',
                          style: TextStyle(
                            fontSize: 22,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            color: isActive 
                                ? Colors.white 
                                : primaryTextColor.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'آية / يوم',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive 
                                ? Colors.white.withValues(alpha: 0.8) 
                                : primaryTextColor.withValues(alpha: 0.5),
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
