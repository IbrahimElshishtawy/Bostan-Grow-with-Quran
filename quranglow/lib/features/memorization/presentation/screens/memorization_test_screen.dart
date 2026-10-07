import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/quran_typography.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../domain/entities/memorization_plan.dart';
import '../../domain/services/revision_engine.dart';
import '../providers/memorization_providers.dart';

class MemorizationTestScreen extends ConsumerStatefulWidget {
  final MemorizationPlan plan;
  const MemorizationTestScreen({super.key, required this.plan});

  @override
  ConsumerState<MemorizationTestScreen> createState() => _MemorizationTestScreenState();
}

class _MemorizationTestScreenState extends ConsumerState<MemorizationTestScreen> {
  late RevisionQuestion _currentQuestion;
  String? _selectedOption;
  bool? _isCorrect;
  int _score = 0;
  int _questionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNextQuestion();
  }

  void _loadNextQuestion() {
    setState(() {
      _currentQuestion = RevisionEngine.generateNextAyahQuestion(
        surahNumber: widget.plan.surahNumber,
        startAyah: widget.plan.startAyah,
        endAyah: widget.plan.endAyah,
      );
      _selectedOption = null;
      _isCorrect = null;
    });
  }

  void _submitAnswer(String option) {
    if (_isCorrect != null) return;

    final correct = option == _currentQuestion.correctNextAyahText;
    setState(() {
      _selectedOption = option;
      _isCorrect = correct;
      _questionCount++;
      if (correct) _score++;
    });

    ref.read(memorizationNotifierProvider.notifier).recordRevisionResult(
          planId: widget.plan.id,
          isSuccess: correct,
          testedAyah: _currentQuestion.correctNextAyahNumber,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اختبار التثبيت والمراجعة',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldLight : AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score Tracker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سورة ${widget.plan.surahName}',
                  style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'الدرجة: ${_score.toArabic()} من ${_questionCount.toArabic()}',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question Card: "ما هي الآية التالية؟"
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.darkEmeraldGradient : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'الآية الكريمة رقم ${_currentQuestion.givenAyahNumber.toArabic()}:',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentQuestion.givenAyahText,
                    textAlign: TextAlign.center,
                    style: QuranTypography.ayahText(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Text(
                    'ما هي الآية التالية مباشرة؟',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Options List
            ..._currentQuestion.options.map((option) {
              final isChosen = _selectedOption == option;
              final isTarget = option == _currentQuestion.correctNextAyahText;

              Color? borderColor;
              Color? bgColor;

              if (_isCorrect != null) {
                if (isTarget) {
                  borderColor = Colors.green;
                  bgColor = Colors.green.withOpacity(0.15);
                } else if (isChosen) {
                  borderColor = Colors.red;
                  bgColor = Colors.red.withOpacity(0.15);
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _submitAnswer(option),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor ?? (isDark ? const Color(0xFF1E2320) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor ?? (isDark ? Colors.white12 : Colors.black12),
                        width: isChosen || isTarget ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      style: QuranTypography.ayahText(
                        fontSize: 17,
                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Next Question Button
            if (_isCorrect != null)
              ElevatedButton.icon(
                onPressed: _loadNextQuestion,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('السؤال التالي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
