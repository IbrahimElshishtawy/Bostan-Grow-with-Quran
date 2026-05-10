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
            const SizedBox(height: 24),
            
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
                  widget.onSave(_dailyGoal);
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
                  onTap: () {
                    setState(() {
                      _dailyGoal = goal;
                    });
                  },
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
}
