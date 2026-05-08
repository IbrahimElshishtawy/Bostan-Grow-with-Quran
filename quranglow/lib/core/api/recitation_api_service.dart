// ignore_for_file: unused_field

/// Recitation API service for audio streaming with quality options
import 'package:dio/dio.dart';
import 'package:quranglow/core/models/audio_models.dart';
import 'package:quranglow/core/models/quran_models.dart';

class RecitationApiService {
  RecitationApiService({required this.dio});

  final Dio dio;

  static const String _quranComBase = 'https://api.quran.com/api/v4';
  static const String _everyayahBase = 'https://everyayah.com/data';

  /// Get audio URL for specific Ayah with quality option
  Future<String> getAyahAudio(
    int surahNumber,
    int ayahNumber,
    Reciter reciter, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    try {
      final reciterId = _getReciterId(reciter);
      final audioUrl = _constructAudioUrl(
        surahNumber,
        ayahNumber,
        reciterId,
        quality,
      );

      final response = await dio.head(audioUrl);
      if (response.statusCode == 200) {
        return audioUrl;
      }

      throw Exception('Audio URL not accessible');
    } catch (e) {
      throw Exception('Failed to get Ayah audio: $e');
    }
  }

  /// Get audio URL for entire Surah
  Future<String> getSurahAudio(
    int surahNumber,
    Reciter reciter, {
    AudioQuality quality = AudioQuality.high,
  }) async {
    try {
      final reciterId = _getReciterId(reciter);
      final audioUrl = _constructSurahAudioUrl(surahNumber, reciterId, quality);

      final response = await dio.head(audioUrl);
      if (response.statusCode == 200) {
        return audioUrl;
      }

      throw Exception('Surah audio URL not accessible');
    } catch (e) {
      throw Exception('Failed to get Surah audio: $e');
    }
  }

  /// Get all available reciters
  Future<List<Reciter>> getAvailableReciters() async {
    try {
      return Reciter.defaultReciters;
    } catch (e) {
      throw Exception('Failed to get reciters: $e');
    }
  }

  /// Get recitation metadata (duration, bitrate, etc.)
  Future<Map<String, dynamic>> getRecitationMetadata(
    int surahNumber,
    int ayahNumber,
    Reciter reciter,
  ) async {
    try {
      return {
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'reciter': reciter.displayName,
        'duration': 30,
        'bitrate': 128,
        'format': 'mp3',
      };
    } catch (e) {
      throw Exception('Failed to get recitation metadata: $e');
    }
  }

  /// Download audio file for offline use
  Future<String> downloadAudio(
    String audioUrl,
    String savePath, {
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      await dio.download(
        audioUrl,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
      return savePath;
    } catch (e) {
      throw Exception('Failed to download audio: $e');
    }
  }

  String _getReciterId(Reciter reciter) {
    switch (reciter.name) {
      case ReciterName.misharyrashid:
        return 'Alafasy';
      case ReciterName.alhusary:
        return 'Alhusary';
      case ReciterName.abdulbasit:
        return 'AbdulBaset_Murattal';
    }
  }

  String _constructAudioUrl(
    int surahNumber,
    int ayahNumber,
    String reciterId,
    AudioQuality quality,
  ) {
    final formattedSurah = surahNumber.toString().padLeft(3, '0');
    final formattedAyah = ayahNumber.toString().padLeft(3, '0');

    return '$_everyayahBase/$reciterId/${formattedSurah}${formattedAyah}.mp3';
  }

  String _constructSurahAudioUrl(
    int surahNumber,
    String reciterId,
    AudioQuality quality,
  ) {
    final formattedSurah = surahNumber.toString().padLeft(3, '0');
    return '$_everyayahBase/$reciterId/Surah_$formattedSurah.mp3';
  }
}
