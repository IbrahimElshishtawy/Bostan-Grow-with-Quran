import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class InteractiveQuizDialog extends StatefulWidget {
  const InteractiveQuizDialog({
    required this.level,
    required this.onComplete,
    super.key,
  });

  final GameLevel level;
  final Function(int combo) onComplete;

  @override
  State<InteractiveQuizDialog> createState() => _InteractiveQuizDialogState();
}

class _InteractiveQuizDialogState extends State<InteractiveQuizDialog> {
  int? _selectedIndex;
  final List<String> _options = ['الرحمة والمغفرة', 'الهداية إلى الطريق المستقيم', 'العزة والملكوت'];
  final int _correctIndex = 1;
  int _combo = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 56, color: Colors.orange),
          const SizedBox(height: 12),
          const Text(
            'مسابقة التدبر والتفسير',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'ما هو المعنى الرئيسي لقوله تعالى: "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ"؟',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ...List.generate(_options.length, (index) {
            final isSelected = _selectedIndex == index;
            final isCorrectAnswer = index == _correctIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: _selectedIndex != null
                    ? null
                    : () {
                        setState(() {
                          _selectedIndex = index;
                          if (index == _correctIndex) {
                            _combo = 3;
                            widget.onComplete(_combo);
                          } else {
                            _combo = 1;
                          }
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedIndex != null
                      ? isCorrectAnswer
                          ? Colors.green
                          : isSelected
                              ? Colors.red
                              : Colors.white
                      : Colors.white,
                  foregroundColor: _selectedIndex != null && (isCorrectAnswer || isSelected)
                      ? Colors.white
                      : Colors.black87,
                  side: BorderSide(color: Colors.grey[200]!),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  _options[index],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            );
          }),

          if (_selectedIndex != null) ...[
            const SizedBox(height: 16),
            if (_selectedIndex == _correctIndex) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Combo Multiplier x$_combo activated! +15 XP Bonus! ⚡',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ],
                ),
              ).animate().scale(curve: Curves.elasticOut),
              const SizedBox(height: 8),
            ],
            Text(
              _selectedIndex == _correctIndex
                  ? 'أحسنت! الإجابة صحيحة ومباركة 🎉'
                  : 'إجابة خاطئة، حاول مجدداً لاحقاً! ❌',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _selectedIndex == _correctIndex ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: GameificationColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('المتابعة والدرب'),
            ),
          ],
        ],
      ),
    );
  }
}
