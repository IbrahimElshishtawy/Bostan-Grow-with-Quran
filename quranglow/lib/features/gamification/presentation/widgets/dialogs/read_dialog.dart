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

  @override
  void initState() {
    super.initState();
    _fetchFuture = ref.read(quranApiServiceProvider).getAyahRange(
      widget.level.surahId,
      widget.level.ayahStart,
      widget.level.ayahEnd,
    );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_rounded, size: 56, color: GameificationColors.goldAccent),
          const SizedBox(height: 12),
          Text(
            'محطة القراءة والتحسين • ${widget.level.surahName}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text('اقرأ الآيات الآتية بتمعن وتدبر:', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 16),
          
          // Real Dynamic Content Fetching
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 350),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: FutureBuilder<List<Ayah>>(
                future: _fetchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: GameificationColors.primaryGreen));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('تعذر تحميل الآيات: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
                  }
                  final ayahs = snapshot.data ?? [];
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount: ayahs.length,
                    separatorBuilder: (ctx, idx) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final ayah = ayahs[index];
                      return Text(
                        '${ayah.text} ﴿${ayah.ayahNumber}﴾',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.8,
                          color: GameificationColors.primaryGreenDark,
                          fontFamily: 'Kitab',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _finished = true);
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GameificationColors.goldAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('أكملت القراءة والتدبر ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
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

