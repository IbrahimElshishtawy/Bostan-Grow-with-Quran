import 'package:quran/quran.dart' as quran;

class SearchAyahResult {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final int pageNumber;
  final String textArabic;

  const SearchAyahResult({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.pageNumber,
    required this.textArabic,
  });
}

class QuranSearchEngine {
  QuranSearchEngine._();

  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]');

  /// Normalizes Arabic text by removing diacritics and normalizing alef/yaa
  static String normalizeArabic(String input) {
    var text = input.replaceAll(_tashkeelRegex, '');
    text = text.replaceAll(RegExp(r'[إأآا]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ى', 'ي');
    return text.trim().toLowerCase();
  }

  /// Searches the entire Quran for matching query
  static List<SearchAyahResult> search(String query, {int? surahFilter, int limit = 50}) {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = normalizeArabic(query);
    if (normalizedQuery.isEmpty) return [];

    final results = <SearchAyahResult>[];

    final startSurah = surahFilter ?? 1;
    final endSurah = surahFilter ?? 114;

    for (int s = startSurah; s <= endSurah; s++) {
      final totalVerses = quran.getVerseCount(s);
      final surahName = quran.getSurahNameArabic(s);

      for (int a = 1; a <= totalVerses; a++) {
        final rawVerse = quran.getVerse(s, a);
        final normalizedVerse = normalizeArabic(rawVerse);

        if (normalizedVerse.contains(normalizedQuery)) {
          final pageNum = quran.getPageNumber(s, a);
          results.add(
            SearchAyahResult(
              surahNumber: s,
              surahName: surahName,
              ayahNumber: a,
              pageNumber: pageNum,
              textArabic: rawVerse,
            ),
          );

          if (results.length >= limit) {
            return results;
          }
        }
      }
    }

    return results;
  }
}
