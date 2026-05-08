/// Riverpod providers for state management
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/api/api_cache_manager.dart';
import 'package:quranglow/core/api/api_interceptor.dart';
import 'package:quranglow/core/api/quran_api_service.dart';
import 'package:quranglow/core/api/recitation_api_service.dart';
import 'package:quranglow/core/api/tafsir_api_service.dart';
import 'package:quranglow/core/models/audio_models.dart';
import 'package:quranglow/core/models/bookmark_models.dart';
import 'package:quranglow/core/models/quran_models.dart';
import 'package:quranglow/core/models/tafsir_models.dart';
import 'package:quranglow/features/audio/application/audio_player_controller.dart';
import 'package:quranglow/features/bookmarks/application/bookmark_controller.dart';
import 'package:quranglow/features/quran/application/quran_controller.dart';
import 'package:quranglow/features/settings/application/settings_controller.dart';

/// Dio HTTP client with interceptors
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  // Add interceptors
  final cacheManager = ApiCacheManager(boxName: 'api_cache');
  dio.interceptors.add(
    ApiInterceptor(cacheManager: cacheManager),
  );

  return dio;
});

/// API Services
final quranApiServiceProvider = Provider<QuranApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return QuranApiService(dio: dio);
});

final recitationApiServiceProvider = Provider<RecitationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return RecitationApiService(dio: dio);
});

final tafsirApiServiceProvider = Provider<TafsirApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return TafsirApiService(dio: dio);
});

/// State Controllers
final quranControllerProvider =
    StateNotifierProvider<QuranController, QuranState>((ref) {
  final quranApiService = ref.watch(quranApiServiceProvider);
  return QuranController(quranApiService: quranApiService);
});

final audioPlayerControllerProvider =
    StateNotifierProvider<AudioPlayerController, PlaybackSession>((ref) {
  return AudioPlayerController();
});

final bookmarkControllerProvider =
    StateNotifierProvider<BookmarkController, BookmarkState>((ref) {
  return BookmarkController();
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController();
});

/// Computed Providers
final currentSurahProvider = Provider<Surah?>((ref) {
  final quranState = ref.watch(quranControllerProvider);
  return quranState.currentSurah;
});

final allSurahsProvider = Provider<List<Surah>>((ref) {
  final quranState = ref.watch(quranControllerProvider);
  return quranState.allSurahs;
});

final currentAyahProvider = Provider<Ayah?>((ref) {
  final quranState = ref.watch(quranControllerProvider);
  return quranState.currentAyah;
});

final currentPlaybackTrackProvider = Provider<AudioTrack?>((ref) {
  final playbackSession = ref.watch(audioPlayerControllerProvider);
  return playbackSession.currentTrack?.track;
});

final bookmarkStatsProvider = Provider<BookmarkStats>((ref) {
  final bookmarkState = ref.watch(bookmarkControllerProvider);
  return bookmarkState.getStats();
});

final favoriteBookmarksProvider = Provider<List<Bookmark>>((ref) {
  final bookmarkController = ref.read(bookmarkControllerProvider.notifier);
  return bookmarkController.getFavorites();
});

/// Async Providers for API calls
final surahsAsyncProvider = FutureProvider<List<Surah>>((ref) async {
  final quranApiService = ref.watch(quranApiServiceProvider);
  return quranApiService.getAllSurahs();
});

final recitationsAsyncProvider = FutureProvider<List<Reciter>>((ref) async {
  final recitationApiService = ref.watch(recitationApiServiceProvider);
  return recitationApiService.getAvailableReciters();
});

final tafsirSourcesAsyncProvider =
    FutureProvider<List<TafsirSource>>((ref) async {
  final tafsirApiService = ref.watch(tafsirApiServiceProvider);
  return tafsirApiService.getAvailableSources();
});
