import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/quran_typography.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../quran/presentation/screens/mushaf_screen.dart';

final bookmarksListProvider = StateNotifierProvider<BookmarksNotifier, List<Map<String, dynamic>>>((ref) {
  final localDb = ref.watch(localDatabaseProvider);
  return BookmarksNotifier(localDb);
});

class BookmarksNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final dynamic _localDb;

  BookmarksNotifier(this._localDb) : super([]) {
    loadBookmarks();
  }

  void loadBookmarks() {
    state = _localDb.getAllBookmarks();
  }

  Future<void> removeBookmark(String id) async {
    await _localDb.deleteBookmark(id);
    loadBookmarks();
  }
}

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'العلامات والإشارات المرجعية',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldLight : AppColors.primary,
          ),
        ),
      ),
      body: bookmarks.isEmpty
          ? const AppEmpty(
              title: 'لا توجد آيات محفوظة بعد',
              subtitle: 'يمكنك حفظ أي آية بالضغط عليها أثناء القراءة في المصحف واختيار حفظ',
              icon: Icons.bookmark_border_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookmarks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bm = bookmarks[index];
                final id = bm['id'] as String? ?? '';
                final surahName = bm['surahName'] as String? ?? '';
                final ayahNumber = bm['ayahNumber'] as int? ?? 1;
                final pageNumber = bm['pageNumber'] as int? ?? 1;
                final text = bm['text'] as String? ?? '';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2320) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bookmark_rounded, color: AppColors.gold, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'سورة $surahName — الآية ${ayahNumber.toArabic()}',
                                style: GoogleFonts.amiri(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.goldLight : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'صفحة ${pageNumber.toArabic()}',
                            style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: QuranTypography.ayahText(
                          fontSize: 16,
                          height: 1.8,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            onPressed: () {
                              ref.read(bookmarksListProvider.notifier).removeBookmark(id);
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.menu_book_rounded, size: 16),
                            label: Text('فتح في المصحف', style: GoogleFonts.tajawal(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MushafScreen(initialPage: pageNumber),
                                ),
                              );
                            },
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
}
