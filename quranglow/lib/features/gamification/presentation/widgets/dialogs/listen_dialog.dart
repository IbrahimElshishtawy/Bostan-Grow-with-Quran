import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class InteractiveListenDialog extends StatefulWidget {
  const InteractiveListenDialog({
    required this.level,
    required this.onComplete,
    super.key,
  });

  final GameLevel level;
  final VoidCallback onComplete;

  @override
  State<InteractiveListenDialog> createState() => _InteractiveListenDialogState();
}

class _InteractiveListenDialogState extends State<InteractiveListenDialog> {
  bool _isPlaying = false;
  double _progress = 0.0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.headphones_rounded, size: 56, color: GameificationColors.primaryGreen),
          const SizedBox(height: 12),
          Text(
            'محطة الاستماع • ${widget.level.surahName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'استمع بخشوع لتسجيل ورتل الآيات معه بتدبر.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 24),

          if (_isPlaying)
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  8,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 4,
                    height: 10.0 + (math.Random().nextDouble() * 30.0),
                    decoration: BoxDecoration(
                      color: GameificationColors.primaryGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(duration: 400.ms),
            ),
          const SizedBox(height: 16),

          LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(GameificationColors.primaryGreen),
          ),
          const SizedBox(height: 24),

          if (!_completed)
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isPlaying = true);
                Future.doWhile(() async {
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (!mounted) return false;
                  setState(() {
                    _progress += 0.04;
                    if (_progress >= 1.0) {
                      _progress = 1.0;
                      _completed = true;
                      _isPlaying = false;
                      widget.onComplete();
                    }
                  });
                  return _progress < 1.0;
                });
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('بدء الاستماع للترتيل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GameificationColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            )
          else
            Column(
              children: [
                const Text(
                  'أحسنت الاستماع والخشوع! 🪙',
                  style: TextStyle(fontWeight: FontWeight.bold, color: GameificationColors.primaryGreen),
                ),
                const SizedBox(height: 8),
                const Text(
                  'قال النبي ﷺ: "الذي يقرأ القرآن وهو ماهر به مع السفرة الكرام البررة."',
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
                  child: const Text('إغلاق والمتابعة'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
