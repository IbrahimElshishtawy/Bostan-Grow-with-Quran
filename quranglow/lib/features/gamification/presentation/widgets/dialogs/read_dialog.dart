import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quranglow/core/models/quran_models.dart';
import 'package:quranglow/core/providers/app_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class InteractiveReadDialog extends ConsumerStatefulWidget {
  const InteractiveReadDialog({
    required this.level,
    required this.onComplete,
    super.key,
  });

  final GameLevel level;
  final VoidCallback onComplete;

  @override
  ConsumerState<InteractiveReadDialog> createState() => _InteractiveReadDialogState();
}

class _InteractiveReadDialogState extends ConsumerState<InteractiveReadDialog> {
  bool _finished = false;
  late Future<List<Ayah>> _fetchFuture;
  List<Ayah> _ayahs = [];
  int _currentAyahIndex = 0;

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _finished ? _buildSuccessState(cs) : _buildReadingState(cs),
      ),
    );
  }

  Widget _buildReadingState(ColorScheme cs) {
    return SizedBox(
      width: double.maxFinite,
      child: FutureBuilder<List<Ayah>>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator(color: GameificationColors.primaryGreen)),
            );
          }
          if (snapshot.hasError || _ayahs.isEmpty) {
            return SizedBox(
              height: 250,
              child: Center(child: Text('تعذر تحميل الآيات: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12))),
            );
          }

          final currentAyah = _ayahs[_currentAyahIndex];
          final isLast = _currentAyahIndex == _ayahs.length - 1;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.menu_book_rounded, size: 32, color: GameificationColors.goldAccent),
                  Text(
                    'الآية ${_currentAyahIndex + 1} من ${_ayahs.length}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.level.surahName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cs.onSurface),
              ),
              const SizedBox(height: 16),
              
              // Ayah Display Container
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_currentAyahIndex),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
                    ],
                  ),
                  child: Text(
                    currentAyah.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.9,
                      color: Theme.of(context).brightness == Brightness.dark ? cs.onSurface : GameificationColors.primaryGreenDark,
                      fontFamily: 'Kitab',
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Navigation controls
              Row(
                children: [
                  if (_currentAyahIndex > 0)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _currentAyahIndex--),
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                        label: const Text('السابق', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (_currentAyahIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLast) {
                          setState(() => _finished = true);
                          widget.onComplete();
                        } else {
                          setState(() => _currentAyahIndex++);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? GameificationColors.goldAccent : GameificationColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        isLast ? 'أكملت القراءة والتدبر ✅' : 'الآية التالية',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuccessState(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green)
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        const Text(
          'تم إنجاز القراءة بنجاح! ✨',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: GameificationColors.primaryGreen),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'بارك الله فيك وتقبل منك! عن ابن مسعود رضي الله عنه قال ﷺ: "من قرأ حرفاً من كتاب الله فله به حسنة والحسنة بعشر أمثالها."',
          textAlign: TextAlign.center,
          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: cs.onSurfaceVariant, height: 1.5),
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
            child: const Text('استمرار'),
          ),
        ),
      ],
    );
  }
}

