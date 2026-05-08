/// Tafsir API service for Quranic interpretation
import 'package:dio/dio.dart';
import 'package:quranglow/core/models/tafsir_models.dart';

class TafsirApiService {
  TafsirApiService({required this.dio});

  final Dio dio;

  static const String _alquranCloudBase = 'https://api.alquran.cloud/v1';

  /// Get tafsir for specific Ayah
  Future<TafsirText> getTafsir(
    int surahNumber,
    int ayahNumber, {
    TafsirSource source = TafsirSource.muyassar,
  }) async {
    try {
      final response = await dio.get(
        '$_alquranCloudBase/ayah/$surahNumber:$ayahNumber/${source.identifier}',
      );
      final data = response.data as Map<String, dynamic>;
      final ayahData = data['data'] as Map<String, dynamic>;

      return TafsirText(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        source: source,
        text: ayahData['text'] as String? ?? '',
        author: _getAuthorForSource(source),
        language: _getLanguageForSource(source),
      );
    } catch (e) {
      throw Exception(
        'Failed to fetch tafsir for $surahNumber:$ayahNumber: $e',
      );
    }
  }

  /// Get tafsir collection for Ayah from multiple sources
  Future<TafsirCollection> getTafsirCollection(
    int surahNumber,
    int ayahNumber, {
    List<TafsirSource> sources = const [
      TafsirSource.muyassar,
      TafsirSource.ibnKathir,
    ],
  }) async {
    try {
      final tafsirs = <TafsirText>[];

      for (final source in sources) {
        try {
          final tafsir = await getTafsir(
            surahNumber,
            ayahNumber,
            source: source,
          );
          tafsirs.add(tafsir);
        } catch (e) {
          // Continue if one source fails
          continue;
        }
      }

      return TafsirCollection(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        tafsirs: tafsirs,
      );
    } catch (e) {
      throw Exception(
        'Failed to fetch tafsir collection: $e',
      );
    }
  }

  /// Get tafsir for Ayah range
  Future<List<TafsirCollection>> getTafsirRange(
    int surahNumber,
    int startAyah,
    int endAyah, {
    TafsirSource source = TafsirSource.muyassar,
  }) async {
    try {
      final tafsirs = <TafsirCollection>[];

      for (int i = startAyah; i <= endAyah; i++) {
        final tafsir = await getTafsirCollection(
          surahNumber,
          i,
          sources: [source],
        );
        tafsirs.add(tafsir);
      }

      return tafsirs;
    } catch (e) {
      throw Exception(
        'Failed to fetch tafsir range: $e',
      );
    }
  }

  /// Get available tafsir sources
  Future<List<TafsirSource>> getAvailableSources() async {
    try {
      return TafsirSource.values;
    } catch (e) {
      throw Exception('Failed to get available tafsir sources: $e');
    }
  }

  String _getAuthorForSource(TafsirSource source) {
    switch (source) {
      case TafsirSource.ibnKathir:
        return 'Ibn Kathir';
      case TafsirSource.alSaadi:
        return 'Abd al-Rahman al-Saadi';
      case TafsirSource.muyassar:
        return 'Al-Muyassar';
      case TafsirSource.english:
        return 'English Tafsir';
    }
  }

  String _getLanguageForSource(TafsirSource source) {
    switch (source) {
      case TafsirSource.english:
        return 'en';
      default:
        return 'ar';
    }
  }
}
