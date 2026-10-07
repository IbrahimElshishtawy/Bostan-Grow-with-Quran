import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/quran_typography.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../audio/presentation/providers/audio_player_notifier.dart';
import '../../../tafsir/presentation/screens/tafsir_screen.dart';
import '../providers/quran_providers.dart';
import '../widgets/ayah_action_bottom_sheet.dart';
import 'surah_index_screen.dart';

class MushafScreen extends ConsumerStatefulWidget {
  final int initialPage;
  const MushafScreen({super.key, this.initialPage = 1});

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final startPage = widget.initialPage > 0 ? widget.initialPage : 1;
    _pageController = PageController(initialPage: startPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showJumpToPageDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('الانتقال إلى صفحة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'أدخل رقم الصفحة (1 - 604)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.tajawal()),
            ),
            ElevatedButton(
              onPressed: () {
                final page = int.tryParse(controller.text);
                if (page != null && page >= 1 && page <= 604) {
                  Navigator.pop(context);
                  _pageController.jumpToPage(page - 1);
                  ref.read(mushafControllerProvider.notifier).goToPage(page);
                }
              },
              child: Text('انتقال', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showFontSizeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final mushafState = ref.watch(mushafControllerProvider);
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حجم خط القرآن الكريم',
                    style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('أ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Slider(
                          value: mushafState.fontSize,
                          min: 18.0,
                          max: 36.0,
                          divisions: 9,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            ref.read(mushafControllerProvider.notifier).setFontSize(val);
                          },
                        ),
                      ),
                      const Text('أ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mushafState = ref.watch(mushafControllerProvider);
    final isNight = mushafState.isNightMode;

    final bgColor = isNight ? const Color(0xFF141715) : const Color(0xFFFBF9F4);
    final textColor = isNight ? const Color(0xFFE8E5DD) : const Color(0xFF1F2220);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isNight ? const Color(0xFF1E2320) : Colors.white,
        title: Text(
          'المصحف الشريف',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isNight ? AppColors.goldLight : AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: 'فهرس السور',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SurahIndexScreen(
                    onSelectSurah: (startPage) {
                      Navigator.pop(context);
                      _pageController.jumpToPage(startPage - 1);
                      ref.read(mushafControllerProvider.notifier).goToPage(startPage);
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'حجم الخط',
            onPressed: () => _showFontSizeBottomSheet(context),
          ),
          IconButton(
            icon: Icon(isNight ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: 'الوضع الليلي',
            onPressed: () {
              ref.read(mushafControllerProvider.notifier).toggleNightMode();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            tooltip: 'الانتقال لصفحة',
            onPressed: () => _showJumpToPageDialog(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: 604,
        // Madani Mushaf standard: Read Right to Left
        reverse: true,
        onPageChanged: (pageIndex) {
          final pageNum = pageIndex + 1;
          ref.read(mushafControllerProvider.notifier).goToPage(pageNum);
        },
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          final pageAsync = ref.watch(mushafPageProvider(pageNum));

          return pageAsync.when(
            loading: () => const AppLoading(message: 'جاري تحميل الصفحة الكريمة...'),
            error: (err, _) => AppError(
              message: 'تعذر تحميل الصفحة $pageNum',
              onRetry: () => ref.refresh(mushafPageProvider(pageNum)),
            ),
            data: (page) {
              return Column(
                children: [
                  // Page Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isNight ? Colors.white12 : Colors.black12,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سورة ${page.primarySurahName}',
                          style: GoogleFonts.amiri(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'الجزء ${page.juzNumber.toArabic()}',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            color: isNight ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page Content (Ayahs Flow)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          _buildAyahsFlow(context, page, isNight, textColor),
                        ],
                      ),
                    ),
                  ),

                  // Page Footer
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isNight ? Colors.white12 : Colors.black12,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '— ${pageNum.toArabic()} —',
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isNight ? AppColors.goldLight : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAyahsFlow(
    BuildContext context,
    dynamic page,
    bool isNight,
    Color textColor,
  ) {
    final mushafState = ref.watch(mushafControllerProvider);
    final selectedAyah = mushafState.selectedAyah;

    // Check if new surah starts on this page
    final widgets = <Widget>[];
    int? currentSurahHeader;

    for (final ayah in page.ayahs) {
      if (ayah.ayahNumber == 1 && currentSurahHeader != ayah.surahNumber) {
        currentSurahHeader = ayah.surahNumber;
        final surahName = quran.getSurahNameArabic(ayah.surahNumber);

        // Surah Frame Header
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              gradient: isNight ? AppColors.darkEmeraldGradient : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: Center(
              child: Text(
                'سُورَةُ $surahName',
                style: QuranTypography.surahTitle(
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );

        // Basmalah (unless Surah At-Tawbah, surah #9)
        if (ayah.surahNumber != 9 && ayah.surahNumber != 1) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                quran.basmala,
                textAlign: TextAlign.center,
                style: QuranTypography.basmalah(
                  fontSize: mushafState.fontSize - 2,
                  color: isNight ? AppColors.goldLight : AppColors.primaryDark,
                ),
              ),
            ),
          );
        }
      }
    }

    // Text Span Rich Flow for Ayahs
    final textSpans = <InlineSpan>[];
    for (final ayah in page.ayahs) {
      final isSelected = selectedAyah != null &&
          selectedAyah.surahNumber == ayah.surahNumber &&
          selectedAyah.ayahNumber == ayah.ayahNumber;

      textSpans.add(
        WidgetSpan(
          child: GestureDetector(
            onTap: () {
              ref.read(mushafControllerProvider.notifier).selectAyah(ayah);
              showModalBottomSheet(
                context: context,
                builder: (context) => AyahActionBottomSheet(
                  ayah: ayah,
                  isBookmarked: ayah.isBookmarked,
                  onToggleBookmark: () {
                    ref.read(mushafControllerProvider.notifier).toggleBookmark(ayah);
                  },
                  onPlayAudio: () {
                    ref.read(quranAudioNotifierProvider.notifier).playAyah(
                          ayah.surahNumber,
                          ayah.ayahNumber,
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('بدء التلاوة المباركة للآية ${ayah.ayahNumber.toArabic()}',
                            style: GoogleFonts.tajawal()),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onShowTafsir: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TafsirScreen(
                          surahNumber: ayah.surahNumber,
                          ayahNumber: ayah.ayahNumber,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? (isNight
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.goldLight.withOpacity(0.4))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ' ${ayah.textArabic} ',
                textDirection: TextDirection.rtl,
                style: QuranTypography.ayahText(
                  fontSize: mushafState.fontSize,
                  color: isSelected
                      ? (isNight ? AppColors.goldLight : AppColors.primaryDark)
                      : textColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    widgets.add(
      Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(children: textSpans),
        ),
      ),
    );

    return Column(children: widgets);
  }
}
