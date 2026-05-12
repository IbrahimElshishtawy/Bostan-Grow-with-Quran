import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/models/quran_models.dart';
import 'package:quranglow/core/providers/app_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class InteractiveMemorizeDialog extends ConsumerStatefulWidget {
  const InteractiveMemorizeDialog({
    required this.level,
    required this.onComplete,
    super.key,
  });

  final GameLevel level;
  final VoidCallback onComplete;

  @override
  ConsumerState<InteractiveMemorizeDialog> createState() => _InteractiveMemorizeDialogState();
}

class _InteractiveMemorizeDialogState extends ConsumerState<InteractiveMemorizeDialog> {
  late Future<List<Ayah>> _fetchFuture;
  int _currentIndex = 0;
  bool _isRevealed = false;
  List<Ayah> _ayahs = [];

  @override
  void initState() {
    super.initState();
    _fetchFuture = ref.read(quranApiServiceProvider).getAyahRange(
      widget.level.surahId,
      widget.level.ayahStart,
      widget.level.ayahEnd,
    ).then((list) {
      setState(() => _ayahs = list);
      return list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(20),
      content: FutureBuilder<List<Ayah>>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: cs.primary)),
            );
          }
          if (snapshot.hasError || _ayahs.isEmpty) {
            return const SizedBox(height: 200, child: Center(child: Text('خطأ في تحميل البيانات')));
          }

          final isDone = _currentIndex >= _ayahs.length;
          if (isDone) return _buildFinalSuccess(cs);

          final currentAyah = _ayahs[_currentIndex];
          final splitted = currentAyah.text.split(' ');
          final hiddenWord = splitted.last;
          final startPhrase = splitted.sublist(0, splitted.length - 1).join(' ');

          return SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.psychology_rounded, size: 50, color: Colors.purple),
                const SizedBox(height: 8),
                Text(
                  'تثبيت الحفظ (${_currentIndex + 1}/${_ayahs.length})',
                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'حاول استذكار آخر كلمة في هذه الآية المظللة:',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        startPhrase,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Kitab', height: 1.6, color: cs.onSurface),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          if (!_isRevealed) setState(() => _isRevealed = true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isRevealed ? cs.primary.withValues(alpha: 0.15) : cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isRevealed ? hiddenWord : 'اضغط للكشف ❓',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Kitab',
                              fontWeight: FontWeight.bold,
                              color: _isRevealed ? cs.primary : cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRevealed ? _goToNext : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameificationColors.primaryGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _currentIndex < _ayahs.length - 1 ? 'الآية التالية ⬅️' : 'إنهاء التحقق 🏁',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _goToNext() {
    if (_currentIndex < _ayahs.length - 1) {
      setState(() {
        _currentIndex++;
        _isRevealed = false;
      });
    } else {
      setState(() {
        _currentIndex++; // triggers completion view
      });
      widget.onComplete();
    }
  }

  Widget _buildFinalSuccess(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.stars_rounded, size: 64, color: Colors.orange),
        const SizedBox(height: 16),
        const Text(
          'حفظ ممتاز ومبارك! ✨',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: GameificationColors.primaryGreen),
        ),
        const SizedBox(height: 8),
        Text(
          'قال ابن مسعود: "حفظ القرآن الكريم وتثبيته في الصدور نجاة ورفعة في الدارين."',
          textAlign: TextAlign.center,
          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameificationColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('متابعة الرحلة'),
          ),
        ),
      ],
    );
  }
}

