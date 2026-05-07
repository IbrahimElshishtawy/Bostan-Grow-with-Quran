/// Quran API service for fetching Quran data
/// Integrates with api.alquran.cloud and Quran.com APIs

library quran_api_service;

import 'package:dio/dio.dart';
import 'package:quranglow/core/models/quran_models.dart';

class QuranApiService {
  QuranApiService({required this.dio});

  final Dio dio;

  static const String _alquranCloudBase = 'https://api.alquran.cloud/v1';
  static const String _quranComBase = 'https://api.quran.com/api/v4';

  /// Fetch all Surahs from Quran API
  Future<List<Surah>> getAllSurahs() async {
    try {
      final response = await dio.get('$_alquranCloudBase/surah');
      final data = response.data as Map<String, dynamic>;
      final surahs = (data['data'] as List<dynamic>)
          .map((s) => Surah.fromJson(s as Map<String, dynamic>))
          .toList();
      return surahs;
    } catch (e) {
      throw Exception('Failed to fetch Surahs: $e');
    }
  }

  /// Fetch specific Surah data
  Future<Surah> getSurah(int surahNumber) async {
    try {
      final response = await dio.get('$_alquranCloudBase/surah/$surahNumber');
      final data = response.data as Map<String, dynamic>;
      return Surah.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch Surah $surahNumber: $e');
    }
  }

  /// Fetch Ayahs for a specific Surah with translation
  Future<List<Ayah>> getAyahsForSurah(
    int surahNumber, {
    String translation = 'en.sahih',
  }) async {
    try {
      final response = await dio.get(
        '$_alquranCloudBase/surah/$surahNumber',
        queryParameters: {'offset': 0, 'limit': 300},
      );
      final data = response.data as Map<String, dynamic>;
      final surahData = data['data'] as Map<String, dynamic>;
      final ayahs = (surahData['ayahs'] as List<dynamic>)
          .map((a) => Ayah.fromJson(a as Map<String, dynamic>))
          .toList();
      return ayahs;
    } catch (e) {
      throw Exception('Failed to fetch Ayahs for Surah $surahNumber: $e');
    }
  }

  /// Fetch specific Ayah range
  Future<List<Ayah>> getAyahRange(
    int surahNumber,
    int startAyah,
    int endAyah,
  ) async {
    try {
      final allAyahs = await getAyahsForSurah(surahNumber);
      return allAyahs
          .where((a) => a.ayahNumber >= startAyah && a.ayahNumber <= endAyah)
          .toList();
    } catch (e) {
      throw Exception(
        'Failed to fetch Ayah range $startAyah-$endAyah from Surah $surahNumber: $e',
      );
    }
  }

  /// Fetch Tafsir for specific Ayah
  Future<String> getTafsir(int surahNumber, int ayahNumber) async {
    try {
      final response = await dio.get(
        '$_alquranCloudBase/ayah/$surahNumber:$ayahNumber/ar.muyassar',
      );
      final data = response.data as Map<String, dynamic>;
      final tafsirData = data['data'] as Map<String, dynamic>;
      return tafsirData['text'] as String? ?? '';
    } catch (e) {
      throw Exception(
        'Failed to fetch Tafsir for $surahNumber:$ayahNumber: $e',
      );
    }
  }

  /// Fetch translation for specific Ayah
  Future<String> getTranslation(
    int surahNumber,
    int ayahNumber, {
    String translationCode = 'en.sahih',
  }) async {
    try {
      final response = await dio.get(
        '$_alquranCloudBase/ayah/$surahNumber:$ayahNumber/$translationCode',
      );
      final data = response.data as Map<String, dynamic>;
      final ayahData = data['data'] as Map<String, dynamic>;
      return ayahData['text'] as String? ?? '';
    } catch (e) {
      throw Exception(
        'Failed to fetch translation for $surahNumber:$ayahNumber: $e',
      );
    }
  }

  /// Fetch Juz data
  Future<List<QuranJuz>> getAllJuz() async {
    try {
      final response = await dio.get('$_quranComBase/juzs');
      final data = response.data as Map<String, dynamic>;
      final juzs = (data['juzs'] as List<dynamic>)
          .map((j) => QuranJuz.fromJson(j as Map<String, dynamic>))
          .toList();
      return juzs;
    } catch (e) {
      throw Exception('Failed to fetch Juz data: $e');
    }
  }

  /// Search for Ayahs by keyword
  Future<List<Ayah>> searchAyahs(String keyword) async {
    try {
      final response = await dio.get(
        '$_alquranCloudBase/search/$keyword/all',
      );
      final data = response.data as Map<String, dynamic>;
      final results = (data['data']['matches'] as List<dynamic>)
          .map((m) => Ayah.fromJson(m as Map<String, dynamic>))
          .toList();
      return results;
    } catch (e) {
      throw Exception('Failed to search Ayahs: $e');
    }
  }
}
