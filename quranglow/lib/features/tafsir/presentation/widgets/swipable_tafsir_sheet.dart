import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quranglow/core/model/aya/aya.dart';
import 'package:quranglow/core/di/tafsir_providers.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/ayah_card.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/error_card.dart';

class SwipableTafsirSheet extends ConsumerStatefulWidget {
  const SwipableTafsirSheet({
    super.key,
    required this.surahName,
    required this.chapter,
    required this.initialAyahNumber,
    required this.ayat,
    required this.onAyahChanged,
    this.editionId = 'ar.jalalayn',
  });

  final String surahName;
  final int chapter;
  final int initialAyahNumber;
  final List<Aya> ayat;
  final void Function(int ayahNumber) onAyahChanged;
  final String editionId;

  @override
  ConsumerState<SwipableTafsirSheet> createState() => _SwipableTafsirSheetState();
}

class _SwipableTafsirSheetState extends ConsumerState<SwipableTafsirSheet> {
  late PageController _pageController;
  double _tafsirFontSize = 17.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialAyahNumber - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _cycleFontSize() {
    setState(() {
      if (_tafsirFontSize >= 25.0) {
        _tafsirFontSize = 14.0;
      } else {
        _tafsirFontSize += 2.0;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('حجم خط التفسير: ${_tafsirFontSize.toInt()}'),
        duration: const Duration(milliseconds: 600),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);

    // Styling Palette matching premium theme
    final Color sheetBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFCFBF7);
    final Color accentColor = const Color(0xFF8B6914); // Quran Gold
    final Color pillColor = isDark ? const Color(0xFF1E2F26) : const Color(0xFFF1ECE1);
    final Color textDarkColor = isDark ? Colors.white : const Color(0xFF2E2212);
    final Color itemBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFFBF9F4);
    final Color tafsirBoxBg = isDark ? const Color(0xFF182235) : const Color(0xFFF6F3EB);

    return Container(
      height: mq.size.height * 0.75,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Top elegant curved drag handle
          Container(
            width: 45,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // 🛠️ Header row matching the user requested design
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Circular back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: textDarkColor,
                    ),
                  ),
                ),

                // Center Title Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFFD4AF37) : accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'التفسير',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : accentColor,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),

                // Circular text size zoom button
                GestureDetector(
                  onTap: _cycleFontSize,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.format_size_rounded,
                      size: 18,
                      color: textDarkColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 🏷️ "التفسير الميسر" checkmark pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27352B) : const Color(0xFFE8F1EC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: Color(0xFF4CAF50),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'التفسير الميسر',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 📖 Swipeable PageView for Ayat & Tafsir content
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.ayat.length,
                onPageChanged: (index) {
                  widget.onAyahChanged(index + 1);
                },
                itemBuilder: (context, pageIndex) {
                  final ayahNum = pageIndex + 1;
                  final currentAyah = widget.ayat[pageIndex];
                  
                  return Consumer(
                    builder: (context, ref, child) {
                      final tafsirAsync = ref.watch(
                        tafsirForAyahProvider((widget.chapter, ayahNum, widget.editionId)),
                      );

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          // 1. Classic Premium Ayah Card
                          AyahCard(
                            surahName: widget.surahName,
                            ayah: ayahNum,
                            ayahText: currentAyah.text,
                          ),
                          const SizedBox(height: 16),

                          // 2. Action Share/Copy Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(
                                    color: accentColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                onPressed: () {
                                  tafsirAsync.whenData((text) {
                                    Share.share(
                                      'التفسير لآية $ayahNum من سورة ${widget.surahName}:\n\n"${currentAyah.text}"\n\nالتفسير:\n$text\n\n(عبر تطبيق QuranGlow)',
                                    );
                                  });
                                },
                                icon: Icon(
                                  Icons.ios_share_rounded,
                                  size: 16,
                                  color: isDark ? const Color(0xFFD4AF37) : accentColor,
                                ),
                                label: Text(
                                  'مشاركة التفسير',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFD4AF37) : accentColor,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                                onPressed: () {
                                  tafsirAsync.whenData((text) async {
                                    await Clipboard.setData(ClipboardData(text: text));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('تم نسخ نص التفسير'),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  });
                                },
                                icon: Icon(
                                  Icons.copy_all_rounded,
                                  size: 16,
                                  color: textDarkColor.withValues(alpha: 0.7),
                                ),
                                label: Text(
                                  'نسخ التفسير',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textDarkColor.withValues(alpha: 0.7),
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. Tafsir Text Container Card
                          tafsirAsync.when(
                            loading: () => Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: itemBgColor,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: accentColor.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    minHeight: 2.5,
                                    color: isDark ? const Color(0xFFD4AF37) : accentColor,
                                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'جارٍ جلب التفسير...',
                                    style: TextStyle(
                                      color: textDarkColor.withValues(alpha: 0.6),
                                      fontSize: 12,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            error: (e, _) => ErrorCard(msg: 'خطأ في جلب التفسير: $e'),
                            data: (text) => Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: tafsirBoxBg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                text.isEmpty ? 'لا يوجد نص تفسير متاح لهذه الآية.' : text,
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  height: 1.8,
                                  fontSize: _tafsirFontSize,
                                  color: textDarkColor.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
