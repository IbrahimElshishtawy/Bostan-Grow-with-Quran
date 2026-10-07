import '../../../../core/result/result.dart';
import '../entities/ayah.dart';
import '../entities/quran_page.dart';
import '../entities/surah.dart';

abstract class QuranRepository {
  Future<Result<List<Surah>>> getSurahs();
  Future<Result<QuranPage>> getPage(int pageNumber);
  Future<Result<void>> saveReadingPosition({
    required int pageNumber,
    required int surahNumber,
    required int ayahNumber,
  });
  Map<String, dynamic>? getLastReadingPosition();
  Future<Result<bool>> toggleBookmark(Ayah ayah);
  bool isAyahBookmarked(int surahNumber, int ayahNumber);
}
