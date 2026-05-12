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
  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  int? _selectedIndex;
  bool _isEvaluated = false;

  late final List<_QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  void _generateQuestions() {
    // Simulated dynamic high quality content relevant to standard Quran contexts
    _questions = [
      _QuizQuestion(
        title: 'ما هي أفضل الأوقات لتلاوة وتدبر القرآن الكريم؟',
        options: ['وقت الفجر والليل', 'أثناء العمل', 'وقت النوم'],
        correctIndex: 0,
      ),
      _QuizQuestion(
        title: 'ما جزاء الحرف الواحد من كتاب الله؟',
        options: ['حسنة واحدة', 'عشر حسنات', 'خمس حسنات'],
        correctIndex: 1,
      ),
      _QuizQuestion(
        title: 'قوله تعالى "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ" يدل على طلب؟',
        options: ['الرزق', 'المال', 'الهداية'],
        correctIndex: 2,
      ),
      _QuizQuestion(
        title: 'من أسباب الخشوع في الصلاة تدبر الآيات؟',
        options: ['صحيح', 'خاطئ'],
        correctIndex: 0,
      ),
      _QuizQuestion(
        title: 'النية الصالحة شرط أساسي لقبول القراءة؟',
        options: ['نعم بالتأكيد', 'لا ليس شرطاً'],
        correctIndex: 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFinished = _currentQuestionIndex >= _questions.length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isFinished ? _buildSummary(cs) : _buildQuestionView(cs),
      ),
    );
  }

  Widget _buildQuestionView(ColorScheme cs) {
    final q = _questions[_currentQuestionIndex];

    return SizedBox(
      key: ValueKey(_currentQuestionIndex),
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('سؤال ${_currentQuestionIndex + 1}/5', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
              const Icon(Icons.workspace_premium_rounded, size: 30, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.5, color: cs.onSurface),
          ),
          const SizedBox(height: 20),
          ...List.generate(q.options.length, (idx) {
            final isSelected = _selectedIndex == idx;
            final isCorrect = idx == q.correctIndex;

            Color bgColor = cs.surfaceContainerHighest.withValues(alpha: 0.5);
            Color textColor = cs.onSurface;

            if (_isEvaluated) {
              if (isCorrect) {
                bgColor = Colors.green.withValues(alpha: 0.25);
                textColor = Colors.green[800]!;
              } else if (isSelected) {
                bgColor = Colors.red.withValues(alpha: 0.25);
                textColor = Colors.red[800]!;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isEvaluated
                      ? null
                      : () {
                          setState(() {
                            _selectedIndex = idx;
                            _isEvaluated = true;
                            if (idx == q.correctIndex) _correctCount++;
                          });
                          Future.delayed(const Duration(seconds: 1), () {
                            if (mounted) {
                              setState(() {
                                _currentQuestionIndex++;
                                _selectedIndex = null;
                                _isEvaluated = false;
                              });
                            }
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: textColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _isEvaluated && (isCorrect || isSelected) ? textColor : cs.outlineVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                  child: Text(
                    q.options[idx],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummary(ColorScheme cs) {
    final hasPassed = _correctCount >= 2; // User logic requirement: Pass with 2

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
          size: 70,
          color: hasPassed ? Colors.amber : Colors.redAccent,
        ).animate().scale(curve: Curves.elasticOut),
        const SizedBox(height: 16),
        Text(
          hasPassed ? 'تهانينا! لقد نجحت 🏆' : 'للأسف لم تنجح 💔',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: hasPassed ? GameificationColors.primaryGreen : Colors.redAccent),
        ),
        const SizedBox(height: 8),
        Text(
          'النتيجة: $_correctCount إجابات صحيحة من 5',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 20),
        if (hasPassed)
          Text(
            'أحسنت! تم فتح المستوى التالي بنجاح.',
            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 12),
          )
        else
          Text(
            'تحتاج لـ 2 إجابات صحيحة على الأقل للفوز.',
            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 12),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (hasPassed) {
                widget.onComplete(_correctCount); // Finish task in global state
                Navigator.pop(context);
              } else {
                // Reset quiz
                setState(() {
                  _currentQuestionIndex = 0;
                  _correctCount = 0;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPassed ? GameificationColors.primaryGreen : Colors.blueGrey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(hasPassed ? 'إكمال وفتح المستوى' : 'حاول مرة أخرى'),
          ),
        ),
      ],
    );
  }
}

class _QuizQuestion {
  final String title;
  final List<String> options;
  final int correctIndex;

  _QuizQuestion({required this.title, required this.options, required this.correctIndex});
}

