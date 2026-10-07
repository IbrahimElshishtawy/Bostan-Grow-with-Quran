import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/quran_page.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalDataSource _localDataSource;

  QuranRepositoryImpl(this._localDataSource);

  @override
  Future<Result<List<Surah>>> getSurahs() async {
    try {
      final surahs = _localDataSource.getSurahs();
      return Result.success(surahs);
    } catch (e) {
      return Result.failure(CacheFailure('تعذر تحميل فهرس السور: $e'));
    }
  }

  @override
  Future<Result<QuranPage>> getPage(int pageNumber) async {
    try {
      if (pageNumber < 1 || pageNumber > 604) {
        return Result.failure(const FormatFailure('رقم الصفحة خارج النطاق (1-604)'));
      }
      final page = _localDataSource.getPage(pageNumber);
      return Result.success(page);
    } catch (e) {
      return Result.failure(CacheFailure('تعذر تحميل بيانات الصفحة: $e'));
    }
  }

  @override
  Future<Result<void>> saveReadingPosition({
    required int pageNumber,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    try {
      await _localDataSource.saveReadingPosition(
        pageNumber: pageNumber,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure('تعذر حفظ موضع القراءة: $e'));
    }
  }


  @override
  Map<String, dynamic>? getLastReadingPosition() {
    return _localDataSource.getLastReadingPosition();
  }

  @override
  Future<Result<bool>> toggleBookmark(Ayah ayah) async {
    try {
      final status = await _localDataSource.toggleBookmark(ayah);
      return Result.success(status);
    } catch (e) {
      return Result.failure(CacheFailure('تعذر تحديث الإشارة المرجعية: $e'));
    }
  }

  @override
  bool isAyahBookmarked(int surahNumber, int ayahNumber) {
    return _localDataSource.isAyahBookmarked(surahNumber, ayahNumber);
  }
}
