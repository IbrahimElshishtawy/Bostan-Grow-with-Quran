import 'package:quran/quran.dart' as quran;
import '../../../../core/storage/local_database.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/quran_page.dart';
import '../../domain/entities/surah.dart';

abstract class QuranLocalDataSource {
  List<Surah> getSurahs();
  QuranPage getPage(int pageNumber);
  Future<void> saveReadingPosition({
    required int pageNumber,
    required int surahNumber,
    required int ayahNumber,
  });
  Map<String, dynamic>? getLastReadingPosition();
  Future<bool> toggleBookmark(Ayah ayah);
  bool isAyahBookmarked(int surahNumber, int ayahNumber);
}

class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  final LocalDatabase _localDatabase;

  QuranLocalDataSourceImpl(this._localDatabase);

  @override
  List<Surah> getSurahs() {
    final list = <Surah>[];
    for (int i = 1; i <= quran.totalSurahCount; i++) {
      final pages = quran.getSurahPages(i);
      list.add(
        Surah(
          number: i,
          nameArabic: quran.getSurahNameArabic(i),
          nameEnglish: quran.getSurahName(i),
          verseCount: quran.getVerseCount(i),
          revelationType: quran.getPlaceOfRevelation(i),
          startPage: pages.isNotEmpty ? pages.first : 1,
          endPage: pages.isNotEmpty ? pages.last : 1,
        ),
      );
    }
    return list;
  }

  @override
  QuranPage getPage(int pageNumber) {
    final pageData = quran.getPageData(pageNumber);
    final ayahs = <Ayah>[];
    String primarySurahName = '';
    int juzNumber = 1;

    for (final segment in pageData) {
      final surahNum = segment['surah'] as int;
      final startAyah = segment['start'] as int;
      final endAyah = segment['end'] as int;

      if (primarySurahName.isEmpty) {
        primarySurahName = quran.getSurahNameArabic(surahNum);
      }

      for (int a = startAyah; a <= endAyah; a++) {
        final text = quran.getVerse(surahNum, a, verseEndSymbol: true);
        juzNumber = quran.getJuzNumber(surahNum, a);
        final bookmarked = _localDatabase.isAyahBookmarked(surahNum, a);

        ayahs.add(
          Ayah(
            surahNumber: surahNum,
            ayahNumber: a,
            textArabic: text,
            pageNumber: pageNumber,
            juzNumber: juzNumber,
            isBookmarked: bookmarked,
          ),
        );
      }
    }

    return QuranPage(
      pageNumber: pageNumber,
      juzNumber: juzNumber,
      primarySurahName: primarySurahName,
      ayahs: ayahs,
    );
  }

  @override
  Future<void> saveReadingPosition({
    required int pageNumber,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    await _localDatabase.saveReadingProgress(
      pageNumber: pageNumber,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
  }

  @override
  Map<String, dynamic>? getLastReadingPosition() {
    return _localDatabase.getReadingProgress();
  }

  @override
  Future<bool> toggleBookmark(Ayah ayah) async {
    final currentlyBookmarked = _localDatabase.isAyahBookmarked(ayah.surahNumber, ayah.ayahNumber);
    final id = 'bookmark_${ayah.surahNumber}_${ayah.ayahNumber}';

    if (currentlyBookmarked) {
      await _localDatabase.deleteBookmark(id);
      return false;
    } else {
      await _localDatabase.saveBookmark({
        'id': id,
        'surahNumber': ayah.surahNumber,
        'ayahNumber': ayah.ayahNumber,
        'pageNumber': ayah.pageNumber,
        'surahName': quran.getSurahNameArabic(ayah.surahNumber),
        'text': ayah.textArabic,
        'createdAt': DateTime.now().toIso8601String(),
        'isSynced': false,
      });
      return true;
    }
  }

  @override
  bool isAyahBookmarked(int surahNumber, int ayahNumber) {
    return _localDatabase.isAyahBookmarked(surahNumber, ayahNumber);
  }
}
