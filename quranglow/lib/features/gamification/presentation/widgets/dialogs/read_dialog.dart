import 'package:flutter/material.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class InteractiveReadDialog extends StatefulWidget {
  const InteractiveReadDialog({
    required this.level,
    required this.onComplete,
    super.key,
  });

  final GameLevel level;
  final VoidCallback onComplete;

  @override
  State<InteractiveReadDialog> createState() => _InteractiveReadDialogState();
}

class _InteractiveReadDialogState extends State<InteractiveReadDialog> {
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_rounded, size: 56, color: GameificationColors.goldAccent),
          const SizedBox(height: 12),
          Text(
            'محطة القراءة والتحسين • ${widget.level.surahName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ الرَّحْمَٰنِ الرَّحِيمِ مَالِكِ يَوْمِ الدِّينِ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.8,
                color: GameificationColors.primaryGreenDark,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (!_finished)
            ElevatedButton(
              onPressed: () {
                setState(() => _finished = true);
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GameificationColors.goldAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('أكملت القراءة والتدبر'),
            )
          else
            Column(
              children: [
                const Text(
                  'بارك الله فيك وتقبل منك! 🌟',
                  style: TextStyle(fontWeight: FontWeight.bold, color: GameificationColors.primaryGreen),
                ),
                const SizedBox(height: 8),
                const Text(
                  'عن ابن مسعود رضي الله عنه قال ﷺ: "من قرأ حرفاً من كتاب الله فله به حسنة والحسنة بعشر أمثالها."',
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
