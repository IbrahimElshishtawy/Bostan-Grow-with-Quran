import 'package:flutter/material.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class InteractiveWriteDialog extends StatefulWidget {
  const InteractiveWriteDialog({
    required this.level,
    required this.onComplete,
    super.key,
  });

  final GameLevel level;
  final VoidCallback onComplete;

  @override
  State<InteractiveWriteDialog> createState() => _InteractiveWriteDialogState();
}

class _InteractiveWriteDialogState extends State<InteractiveWriteDialog> {
  final List<String> _shuffledWords = ['الرَّحْمَٰنِ', 'بِسْمِ', 'الرَّحِيمِ', 'اللَّهِ'];
  final List<String> _selectedWords = [];
  final List<String> _correctAnswer = ['بِسْمِ', 'اللَّهِ', 'الرَّحْمَٰنِ', 'الرَّحِيمِ'];
  bool _correct = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_note_rounded, size: 56, color: Colors.blue),
          const SizedBox(height: 12),
          const Text(
            'محطة بناء الآية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'رتب الكلمات التالية لبناء البسملة بشكل صحيح:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _selectedWords.map((word) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Chip(
                    label: Text(word, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onDeleted: () {
                      setState(() {
                        _selectedWords.remove(word);
                        _shuffledWords.add(word);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (!_correct)
            Wrap(
              spacing: 8,
              children: _shuffledWords.map((word) {
                return ActionChip(
                  label: Text(word, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() {
                      _shuffledWords.remove(word);
                      _selectedWords.add(word);

                      if (_selectedWords.length == _correctAnswer.length) {
                        bool matched = true;
                        for (int i = 0; i < _correctAnswer.length; i++) {
                          if (_selectedWords[i] != _correctAnswer[i]) matched = false;
                        }
                        if (matched) {
                          _correct = true;
                          widget.onComplete();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('الترتيب غير صحيح، حاول مجدداً! ❌')),
                          );
                          _shuffledWords.addAll(_selectedWords);
                          _selectedWords.clear();
                        }
                      }
                    });
                  },
                );
              }).toList(),
            )
          else
            Column(
              children: [
                const Text(
                  'أحسنت الترتيب والبناء! 🎉',
                  style: TextStyle(fontWeight: FontWeight.bold, color: GameificationColors.primaryGreen),
                ),
                const SizedBox(height: 8),
                const Text(
                  'كتابة آيات القرآن الكريم وتثبيتها ترسخ معانيها في وجدانك وعقلك.',
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
