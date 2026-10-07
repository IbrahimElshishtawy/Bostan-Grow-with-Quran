import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../providers/quran_providers.dart';

class SurahIndexScreen extends ConsumerStatefulWidget {
  final void Function(int startPage)? onSelectSurah;

  const SurahIndexScreen({super.key, this.onSelectSurah});

  @override
  ConsumerState<SurahIndexScreen> createState() => _SurahIndexScreenState();
}

class _SurahIndexScreenState extends ConsumerState<SurahIndexScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'فهرس السور الكريمة',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldLight : AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم السورة...',
                hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2320) : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Surah list
          Expanded(
            child: surahsAsync.when(
              loading: () => const AppLoading(message: 'جاري تحميل فهرس السور...'),
              error: (err, _) => AppError(
                message: 'تعذر تحميل الفهرس',
                onRetry: () => ref.refresh(surahsListProvider),
              ),
              data: (surahs) {
                final filtered = surahs.where((s) {
                  if (_searchQuery.isEmpty) return true;
                  return s.nameArabic.contains(_searchQuery) ||
                      s.nameEnglish.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      s.number.toString() == _searchQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد سور مطابقة للبحث',
                      style: GoogleFonts.tajawal(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                  ),
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withOpacity(0.2)
                              : AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            surah.number.toArabic(),
                            style: GoogleFonts.amiri(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.goldLight : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            surah.nameArabic,
                            style: GoogleFonts.amiri(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: surah.isMakkiyah
                                  ? Colors.orange.withOpacity(0.12)
                                  : Colors.teal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              surah.isMakkiyah ? 'مكية' : 'مدنية',
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: surah.isMakkiyah ? Colors.orange.shade800 : Colors.teal.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${surah.verseCount.toArabic()} آية • صفحة ${surah.startPage.toArabic()}',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        if (widget.onSelectSurah != null) {
                          widget.onSelectSurah!(surah.startPage);
                        } else {
                          Navigator.pop(context, surah.startPage);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
