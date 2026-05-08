import 'package:flutter/material.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class InteractiveMemorizeDialog extends StatefulWidget {
  const InteractiveMemorizeDialog({
    required this.level,
    required this.onComplete,
    super.key,
  });

  final GameLevel level;
  final VoidCallback onComplete;

  @override
  State<InteractiveMemorizeDialog> createState() => _InteractiveMemorizeDialogState();
}

class _InteractiveMemorizeDialogState extends State<InteractiveMemorizeDialog> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.psychology_rounded, size: 56, color: Colors.purple),
          const SizedBox(height: 12),
          const Text(
            'محطة الحفظ والتمكين',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'اقرأ الآية وحاول استذكار الكلمة المخفية في المربع المظلل:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                const Text(
                  'الْحَمْدُ لِلَّهِ رَبِّ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _revealed ? Colors.transparent : Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _revealed ? 'الْعَالَمِينَ' : '???',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _revealed ? GameificationColors.primaryGreen : Colors.purple[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!_revealed)
            ElevatedButton(
              onPressed: () {
                setState(() => _revealed = true);
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('كشف والتحقق من الحفظ'),
            )
          else
            Column(
              children: [
                const Text(
                  'حفظ ممتاز ومبارك! 💖',
                  style: TextStyle(fontWeight: FontWeight.bold, color: GameificationColors.primaryGreen),
                ),
                const SizedBox(height: 8),
                const Text(
                  'قال ابن مسعود: "حفظ القرآن الكريم وتثبيته في الصدور نجاة ورفعة في الدارين."',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameificationColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('المتابعة'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
