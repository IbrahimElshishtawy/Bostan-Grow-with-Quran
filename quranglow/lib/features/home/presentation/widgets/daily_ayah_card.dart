import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/daily_ayah_provider.dart';
import 'package:quranglow/features/home/presentation/widgets/home_surface_card.dart';
import 'package:quranglow/features/home/presentation/widgets/section_title.dart';
import 'package:quranglow/features/mushaf/presentation/pages/mushaf_page.dart';

class DailyAyahCard extends ConsumerWidget {
  const DailyAyahCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ayat = ref.watch(dailyAyatLocalProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'آيات اليوم',
          actionText: 'تحديث',
          onAction: () => refreshDailyAyah(ref),
        ),
        const SizedBox(height: 8),
        ayat.when(
          loading: () => const HomeSurfaceCard(
            emphasis: true,
            child: SizedBox(
              height: 88,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => HomeSurfaceCard(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text('تعذر تحميل آيات اليوم: $e')),
                  TextButton(
                    onPressed: () => refreshDailyAyah(ref),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
          data: (list) => HomeSurfaceCard(
            emphasis: true,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => Divider(
                color: cs.outlineVariant.withValues(alpha: .6),
                height: 22,
              ),
              itemBuilder: (_, i) {
                final a = list[i];

                void openAyah() {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MushafPage(
                        chapter: a.surah,
                        editionId: 'quran-uthmani',
                        initialAyah: a.ayah,
                      ),
                    ),
                  );
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: openAyah,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.text,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 20,
                                  height: 1.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Opacity(
                                opacity: .82,
                                child: Text(
                                  a.ref,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'اذهب إلى الآية',
                          visualDensity: VisualDensity.compact,
                          style: ButtonStyle(
                            side: WidgetStatePropertyAll(
                              BorderSide(
                                color: cs.outlineVariant.withValues(alpha: .65),
                              ),
                            ),
                            overlayColor: WidgetStatePropertyAll(
                              cs.primary.withValues(alpha: .08),
                            ),
                          ),
                          onPressed: openAyah,
                          icon: const Icon(Icons.menu_book_outlined, size: 20),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
