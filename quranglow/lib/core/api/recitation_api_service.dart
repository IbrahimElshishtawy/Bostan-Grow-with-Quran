/// Recitation API service for audio playback
/// Supports multiple reciters: Mishary Rashid, Al-Husary, Abdul Basit

import 'package:dio/dio.dart';
import 'package:quranglow/core/models/quran_models.dart';

class RecitationApiService {
  RecitationApiService({required this.dio});

  final Dio dio;

  static const String _everyayahBase = 'https://everyayah.com/data';
  static const String _quranCloudBase = 'https://api.alquran.cloud/v1';

  /// Get audio URL for specific Ayah and reciter
  Future<String> getAyahAudio(
    int surahNumber,
    int ayahNumber, {
    ReciterName reciter = ReciterName.misharyrashid,
  }) async {
    try {
      final reciterIdentifier = _getReciterIdentifier(reciter);
      final response = await dio.get(
        '$_quranCloudBase/ayah/$surahNumber:$ayahNumber/$reciterIdentifier',
      );
      final data = response.data as Map<String, dynamic>;
      final ayahData = data['data'] as Map<String, dynamic>;
      return ayahData['audio'] as String? ?? '';
    } catch (e) {
      throw Exception(
        'Failed to fetch audio for $surahNumber:$ayahNumber: $e',
      );
    }
  }

  /// Get audio URL for entire Surah
  Future<String> getSurahAudio(
    int surahNumber, {
    ReciterName reciter = ReciterName.misharyrashid,
  }) async {
    try {
      final reciterIdentifier = _getReciterIdentifier(reciter);
      final response = await dio.get(
        '$_quranCloudBase/surah/$surahNumber/$reciterIdentifier',
      );
      final data = response.data as Map<String, dynamic>;
      final surahData = data['data'] as Map<String, dynamic>;
      return surahData['audio'] as String? ?? '';
    } catch (e) {
      throw Exception('Failed to fetch Surah audio for $surahNumber: $e');
    }
  }

  /// Get audio URLs for Ayah range
  Future<List<String>> getAyahRangeAudio(
    int surahNumber,
    int startAyah,
    int endAyah, {
    ReciterName reciter = ReciterName.misharyrashid,
  }) async {
    try {
      final urls = <String>[];
      for (int i = startAyah; i <= endAyah; i++) {
        final url = await getAyahAudio(surahNumber, i, reciter: reciter);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception(
        'Failed to fetch audio range $startAyah-$endAyah: $e',
      );
    }
  }

  /// Get list of available reciters
  Future<List<Reciter>> getAvailableReciters() async {
    return Reciter.defaultReciters;
  }

  /// Get recitation metadata
  Future<RecitationAudio> getRecitationMetadata(
    int surahNumber,
    int ayahNumber, {
    ReciterName reciter = ReciterName.misharyrashid,
  }) async {
    try {
      final audioUrl = await getAyahAudio(
        surahNumber,
        ayahNumber,
        reciter: reciter,
      );
      final reciterData = Reciter.defaultReciters.firstWhere(
        (r) => r.name == reciter,
        orElse: () => Reciter.defaultReciters.first,
      );

      return RecitationAudio(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        reciter: reciterData,
        audioUrl: audioUrl,
        duration: const Duration(seconds: 0),
      );
    } catch (e) {
      throw Exception(
        'Failed to fetch recitation metadata: $e',
      );
    }
  }

  /// Stream audio for continuous playback
  Future<List<RecitationAudio>> getStreamAudio(
    int surahNumber, {
    ReciterName reciter = ReciterName.misharyrashid,
  }) async {
    try {
      final reciterData = Reciter.defaultReciters.firstWhere(
        (r) => r.name == reciter,
        orElse: () => Reciter.defaultReciters.first,
      );

      final response = await dio.get(
        '$_quranCloudBase/surah/$surahNumber/${reciterData.identifier}',
      );
      final data = response.data as Map<String, dynamic>;
      final surahData = data['data'] as Map<String, dynamic>;
      final ayahs = surahData['ayahs'] as List<dynamic>? ?? [];

      return ayahs
          .map((ayah) {
            final ayahData = ayah as Map<String, dynamic>;
            return RecitationAudio(
              surahNumber: surahNumber,
              ayahNumber: ayahData['numberInSurah'] as int? ?? 0,
              reciter: reciterData,
              audioUrl: ayahData['audio'] as String? ?? '',
              duration: const Duration(seconds: 0),
            );
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stream audio: $e');
    }
  }

  String _getReciterIdentifier(ReciterName reciter) {
    switch (reciter) {
      case ReciterName.misharyrashid:
        return 'ar.alafasy';
      case ReciterName.alhusary:
        return 'ar.alhusary';
      case ReciterName.abdulbasit:
        return 'ar.abdulbasit';
    }
  }
}
