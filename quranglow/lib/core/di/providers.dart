// lib/core/di/providers.dart
// ignore_for_file: unused_local_variable, experimental_member_use, implementation_imports, unnecessary_this

import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quranglow/core/api/api_cache_manager.dart';
import 'package:quranglow/core/api/api_interceptor.dart';
import 'package:quranglow/core/api/alquran_cloud_source.dart';
import 'package:quranglow/core/api/fawaz_cdn_source.dart';
import 'package:quranglow/core/data/surah_names_ar.dart';
import 'package:quranglow/core/model/book/Play_list_State.dart';
import 'package:quranglow/core/model/book/bookmark.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/core/model/setting/reader_settings.dart';
import 'package:quranglow/core/model/setting/goal.dart';
import 'package:quranglow/core/service/audio/audio_locator.dart';
import 'package:quranglow/core/service/audio/audio_service.dart';
import 'package:quranglow/core/service/audio/my_audio_handler.dart';
import 'package:quranglow/core/service/quran/quran_service.dart';
import 'package:quranglow/core/service/quran/settings_service.dart';
import 'package:quranglow/core/service/quran/stats_service.dart';
import 'package:quranglow/core/service/quran/stats_service_impl.dart';
import 'package:quranglow/core/service/setting/daily_reminder_kind.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';
import 'package:quranglow/core/service/setting/download_service.dart';
import 'package:quranglow/core/service/setting/goals_service.dart';
import 'package:quranglow/core/model/prayer/prayer_times_data.dart';
import 'package:quranglow/core/service/setting/location_service.dart';
import 'package:quranglow/core/service/setting/prayer_times_service.dart';
import 'package:quranglow/core/service/sync/firebase_sync_service.dart';
import 'package:quranglow/core/service/sync/reminders_service.dart';
import 'package:quranglow/core/service/tracking_service.dart';
import 'package:quranglow/core/storage/hive_storage_impl.dart';
import 'package:quranglow/core/storage/local_storage.dart';
import 'package:quranglow/core/theme/theme_controller.dart';
import 'package:quranglow/features/bookmarks/presentation/providers/bookmarks_controller.dart';
import 'package:quranglow/features/bookmarks/presentation/providers/bookmarks_usecase.dart';
import 'package:quranglow/features/downloads/presentation/providers/download_controller.dart';
import 'package:quranglow/features/player/presentation/widgets/CombinedPositionData.dart';

final httpClientProvider = Provider<http.Client>((ref) => http.Client());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json', 'User-Agent': 'QuranGlow/1.0'},
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  // Add the universal caching interceptor for instant speed!
  final cacheManager = ApiCacheManager(boxName: 'api_cache');
  dio.interceptors.add(ApiInterceptor(cacheManager: cacheManager));

  return dio;
});

final storageProvider = Provider<LocalStorage>((ref) => HiveStorageImpl());

final fawazProvider = Provider<FawazCdnSource>((ref) {
  final client = ref.watch(httpClientProvider);
  final dio = ref.watch(dioProvider);
  return FawazCdnSource(client, dio);
});

final alQuranProvider = Provider<AlQuranCloudSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AlQuranCloudSource(dio: dio);
});

final goalsServiceProvider = Provider<GoalsService>((ref) {
  final svc = GoalsService(storage: ref.watch(storageProvider));
  ref.onDispose(svc.dispose);
  return svc;
});

final audioHandlerProvider = Provider<MyAudioHandler>((ref) {
  return audioHandler;
});

final audioServiceProvider = Provider<MyAudioService>((ref) {
  return MyAudioService(ref.watch(audioHandlerProvider));
});

final quranServiceProvider = Provider<QuranService>((ref) {
  return QuranService(
    fawaz: ref.watch(fawazProvider),
    cloud: ref.watch(alQuranProvider),
    audio: ref.watch(alQuranProvider),
  );
});

final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  return FirebaseSyncService();
});

final remindersServiceProvider = Provider<RemindersService>((ref) {
  return RemindersService();
});

final trackingServiceProvider = Provider<TrackingService>(
  (ref) => TrackingService(
    ref.watch(storageProvider),
    ref.watch(firebaseSyncServiceProvider),
  ),
);

final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(),
);

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(service.dispose);
  return service;
});

final prayerTimesServiceProvider = Provider<PrayerTimesService>((ref) {
  return PrayerTimesService(
    client: ref.watch(httpClientProvider),
    locationService: ref.watch(locationServiceProvider),
    storage: ref.watch(storageProvider),
  );
});

final todayPrayersProvider = FutureProvider.autoDispose<PrayerTimesData>((ref) {
  final svc = ref.watch(prayerTimesServiceProvider);
  return svc.fetchForToday();
});

final goalsStreamProvider = StreamProvider.autoDispose<List<Goal>>((ref) {
  return ref.watch(goalsServiceProvider).watchGoalsWithInitial();
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(dio: ref.watch(dioProvider));
});

final quranAllProvider = FutureProvider.autoDispose.family<List<Surah>, String>(
  (ref, editionId) {
    final service = ref.read(quranServiceProvider);
    return service.getQuranAllText(editionId);
  },
);

final quranMetadataProvider = Provider<List<({int number, String name, int ayatCount})>>((ref) {
  return List.generate(114, (i) {
    final s = i + 1;
    return (
      number: s,
      name: kSurahNamesAr[i],
      ayatCount: quran.getVerseCount(s),
    );
  });
});

final settingsProvider =
    StateNotifierProvider<SettingsController, AsyncValue<AppSettings>>(
      (ref) => SettingsController(ref),
    );

class SettingsController extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsController(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref ref;

  Future<void> _init() async {
    final svc = ref.read(settingsServiceProvider);
    final s = await svc.load();
    state = AsyncValue.data(s);
  }

  Future<void> setDark(bool v) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(
      cur.copyWith(themeMode: v ? ThemeMode.dark : ThemeMode.light),
    );
    await ref.read(settingsServiceProvider).setDark(v);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(themeMode: mode));
    await ref.read(settingsServiceProvider).setThemeMode(mode);
  }

  Future<void> setFontScale(double v) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(fontScale: v));
    await ref.read(settingsServiceProvider).setFontScale(v);
  }

  Future<void> setReader(String id) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(readerEditionId: id));
    await ref.read(settingsServiceProvider).setReader(id);
  }

  Future<void> setFontFamily(String family) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(fontFamily: family));
    await ref.read(settingsServiceProvider).setFontFamily(family);
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(colorScheme: scheme));
    await ref.read(settingsServiceProvider).setColorScheme(scheme);
  }

  Future<void> setAudioDownloadMode(AudioDownloadMode mode) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(audioDownloadMode: mode));
    await ref.read(settingsServiceProvider).setAudioDownloadMode(mode);
  }

  Future<void> setTasbihTarget(int target) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(tasbihTarget: target));
    await ref.read(settingsServiceProvider).setTasbihTarget(target);
  }

  Future<void> setTasbihVibrate(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(tasbihVibrate: enabled));
    await ref.read(settingsServiceProvider).setTasbihVibrate(enabled);
  }

  Future<void> setTasbihSound(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(tasbihSound: enabled));
    await ref.read(settingsServiceProvider).setTasbihSound(enabled);
  }

  Future<void> setAdhanSoundId(String adhanSoundId) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(adhanSoundId: adhanSoundId));
    await ref.read(settingsServiceProvider).setAdhanSoundId(adhanSoundId);
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(dailyReminderEnabled: enabled));
    await ref.read(settingsServiceProvider).setDailyReminderEnabled(enabled);
  }

  Future<void> setDailyReminderTime(TimeOfDay time) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(
      cur.copyWith(
        dailyReminderHour: time.hour,
        dailyReminderMinute: time.minute,
      ),
    );
    await ref.read(settingsServiceProvider).setDailyReminderTime(time);
  }

  Future<void> setDailyReminderKind(DailyReminderKind kind) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(dailyReminderKind: kind));
    await ref.read(settingsServiceProvider).setDailyReminderKind(kind);
  }

  Future<void> setSalawatEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(salawatEnabled: enabled));
    await ref.read(settingsServiceProvider).setSalawatEnabled(enabled);
    
    // Refresh notifications
    await NotificationService.instance.scheduleSalawat(
      enabled: enabled,
      intervalMinutes: cur.salawatIntervalMinutes,
    );
  }

  Future<void> setSalawatIntervalMinutes(int minutes) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(salawatIntervalMinutes: minutes));
    await ref.read(settingsServiceProvider).setSalawatIntervalMinutes(minutes);

    // Refresh notifications
    if (cur.salawatEnabled) {
      await NotificationService.instance.scheduleSalawat(
        enabled: true,
        intervalMinutes: minutes,
      );
    }
  }

  Future<void> setPrayerNotificationsEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(prayerNotificationsEnabled: enabled));
    await ref
        .read(settingsServiceProvider)
        .setPrayerNotificationsEnabled(enabled);
  }

  Future<void> setAdhanSoundEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(adhanSoundEnabled: enabled));
    await ref.read(settingsServiceProvider).setAdhanSoundEnabled(enabled);
  }

  Future<void> setDailyReminderSoundEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(dailyReminderSoundEnabled: enabled));
    await ref
        .read(settingsServiceProvider)
        .setDailyReminderSoundEnabled(enabled);
  }

  Future<void> setSalawatSoundEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(salawatSoundEnabled: enabled));
    await ref.read(settingsServiceProvider).setSalawatSoundEnabled(enabled);

    // Refresh notifications to apply channel sound changes
    if (cur.salawatEnabled) {
      await NotificationService.instance.scheduleSalawat(
        enabled: true,
        intervalMinutes: cur.salawatIntervalMinutes,
      );
    }
  }

  Future<void> setSmartLearningEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(smartLearningEnabled: enabled));
    await ref.read(settingsServiceProvider).setSmartLearningEnabled(enabled);
    
    // Update notifications
    await NotificationService.instance.scheduleSmartLearningReminders(
      enabled: enabled,
      strictness: cur.smartLearningStrictness,
    );
  }

  Future<void> setSmartLearningStrictness(int strictness) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(smartLearningStrictness: strictness));
    await ref
        .read(settingsServiceProvider)
        .setSmartLearningStrictness(strictness);

    // Update notifications
    if (cur.smartLearningEnabled) {
      await NotificationService.instance.scheduleSmartLearningReminders(
        enabled: true,
        strictness: strictness,
      );
    }
  }

  Future<void> setAzkarMorningEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(azkarMorningEnabled: enabled));
    await ref.read(settingsServiceProvider).setAzkarMorningEnabled(enabled);
    await NotificationService.instance.scheduleMorningAzkarReminder(enabled: enabled);
  }

  Future<void> setAzkarEveningEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(azkarEveningEnabled: enabled));
    await ref.read(settingsServiceProvider).setAzkarEveningEnabled(enabled);
    await NotificationService.instance.scheduleEveningAzkarReminder(enabled: enabled);
  }

  Future<void> setAzkarAfterPrayerEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(azkarAfterPrayerEnabled: enabled));
    await ref.read(settingsServiceProvider).setAzkarAfterPrayerEnabled(enabled);
    
    if (enabled) {
      final prayerTimes = await ref.read(prayerTimesServiceProvider).fetchForToday();
      await NotificationService.instance.scheduleAfterPrayerAzkarReminders(
        enabled: true,
        data: prayerTimes,
      );
    } else {
      await NotificationService.instance.cancelAfterPrayerAzkarReminders();
    }
  }
}

final audioEditionsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(quranServiceProvider).listAudioEditions();
});

final editionIdProvider = StateProvider<String>((ref) => 'ar.alafasy');
final chapterProvider = StateProvider<int>((ref) => 1);

class PlayerUiState extends PlaylistState {
  final Duration? totalDurationOverride;
  final bool? isPlaying;
  final String? currentUrl;
  final String? surahName;
  final String? reciterName;
  final int? currentAyah;

  const PlayerUiState({
    required super.editionId,
    required super.chapter,
    required super.total,
    required super.timelineStream,
    required super.durationStream,
    required super.positionStream,
    required super.bufferedStream,
    required super.indexStream,
    required super.playingStream,
    required super.loopModeStream,
    required super.volumeStream,
    required super.processingStateStream,

    this.totalDurationOverride,
    this.isPlaying,
    this.currentUrl,
    this.surahName,
    this.reciterName,
    this.currentAyah,
  });
}

final playerControllerProvider =
    StateNotifierProvider<PlayerController, AsyncValue<PlayerUiState>>(
      (ref) => PlayerController(ref),
    );

class PlayerController extends StateNotifier<AsyncValue<PlayerUiState>> {
  PlayerController(this.ref) : super(const AsyncValue.loading()) {
    final handler = ref.read(audioHandlerProvider);
    _player = handler.player;
    // 3. Initialize streams
    _timelineStream = combinedPositionStream(_player).asBroadcastStream();
    
    // Auto-skip failed ayahs to prevent playback reset
    _player.playbackEventStream.listen(
      (_) {},
      onError: (error) {
        debugPrint('Playback error detected: $error. Skipping to next...');
        _player.seekToNext();
      },
    );

    _init();
  }

  final Ref ref;
  late final AudioPlayer _player;
  late final Stream<CombinedPositionData> _timelineStream;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _posSub;
  String _reciterName = '';
  List<String> _urls = [];
  List<Duration> _ayahOffsets = [];
  bool _disposed = false;

  // Local cache for common reciter names to avoid network calls
  static const _kReciterNames = {
    'ar.alafasy': 'مشاري العفاسي',
    'ar.abdurrahmaansudais': 'عبد الرحمن السديس',
    'ar.saoodshuraym': 'سعود الشريم',
    'ar.minshawi': 'محمد صديق المنشاوي',
    'ar.abdulbasitmurattal': 'عبد الباسط عبد الصمد',
    'ar.husary': 'محمود خليل الحصري',
    'ar.hudhaify': 'علي الحذيفي',
    'ar.ghamadi': 'سعد الغامدي',
    'ar.mahermuaiqly': 'ماهر المعيقلي',
  };

  Future<void> _init() async {
    if (_disposed || !mounted) return;
    final editionId = ref.read(editionIdProvider);
    final chapter = ref.read(chapterProvider).clamp(1, 114);
    await _loadSurah(editionId: editionId, chapter: chapter, autoPlay: false);
  }

  Future<void> _loadSurah({
    required String editionId,
    required int chapter,
    required bool autoPlay,
  }) async {
    if (_disposed || !mounted) return;
    state = const AsyncValue.loading();
    try {
      final service = ref.read(quranServiceProvider);

      // 1. Get URLs (Checks local files first)
      final urls = await service.getSurahAudioUrls(editionId, chapter);
      if (_disposed || !mounted) return;
      if (urls.isEmpty) {
        throw Exception('لا توجد روابط صوتية متاحة');
      }

      _urls = urls;

      // 2. Resolve Reciter Name (Use cache if possible)
      _reciterName =
          _kReciterNames[editionId] ?? await _resolveReciterName(editionId);

      final surahName = (chapter >= 1 && chapter <= kSurahNamesAr.length)
          ? kSurahNamesAr[chapter - 1]
          : 'سورة $chapter';

      if (_disposed || !mounted) return;

      // Update AudioHandler metadata
      final handler = ref.read(audioHandlerProvider);
      handler.mediaItem.add(
        MediaItem(
          id: 'surah_$chapter',
          title: surahName,
          artist: _reciterName,
          album: 'القرآن الكريم',
        ),
      );

      final Map<int, String> audioMap;
      try {
        audioMap = await service.getSurahAudioUrlMap(editionId, chapter);
        final surahData = await service.getSurahText('quran-uthmani', chapter);
        final allAyat = surahData.ayat;

        // Fetch explicit durations for perfect timer reporting and gapless preloading
        final verseDurations = await service.getVerseDurations(
          editionId,
          chapter,
        );

        // Calculate total surah duration upfront for UI override
        _totalDuration = verseDurations.values.fold(
          Duration.zero,
          (a, b) => a + b,
        );
        _emitState();

        // SEAMLESS PLAYBACK: Use a single full surah file for 100% gapless experience
        final fullSurahUrl = service.getSurahFullAudioUrl(editionId, chapter);
        _urls = [fullSurahUrl]; // Only one item in the playlist

        _ayahOffsets = [];
        Duration cumulative = Duration.zero;
        for (final a in allAyat) {
          _ayahOffsets.add(cumulative);
          cumulative +=
              verseDurations[a.numberInSurah] ?? const Duration(seconds: 5);
        }
        _totalDuration = cumulative;

        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(fullSurahUrl),
            tag: MediaItem(
              id: 'surah_$chapter',
              title: 'سورة $surahName',
              album: _reciterName,
              artist: _reciterName,
              duration: cumulative,
            ),
          ),
          initialPosition: Duration.zero,
          preload: true,
        );
      } catch (e) {
        final err = e.toString().toLowerCase();
        if (err.contains('abort') ||
            err.contains('interrupted') ||
            err.contains('10000000')) {
          debugPrint('Audio loading was interrupted (handled): $e');
          return;
        }
        debugPrint('Error loading audio playlist: $e');
        rethrow;
      }

      if (_disposed || !mounted) return;

      if (autoPlay) {
        await _player.setLoopMode(
          LoopMode.off,
        ); // Ensure sequential, non-repeating playback
        await _player.play();
      }

      _emitState();
    } catch (e, st) {
      if (_disposed || !mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> _resolveReciterName(String editionId) async {
    if (_kReciterNames.containsKey(editionId)) {
      return _kReciterNames[editionId]!;
    }

    try {
      final editions = await ref.read(quranServiceProvider).listAudioEditions();
      for (final item in editions) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['identifier'] ?? map['id'] ?? '').toString();
        if (id == editionId) {
          return (map['name'] ?? map['englishName'] ?? editionId).toString();
        }
      }
    } catch (_) {
      // Offline fallback
    }
    return editionId;
  }

  void _emitState() {
    if (_disposed || !mounted) return;
    if (_ayahOffsets.isEmpty) return;

    final editionId = ref.read(editionIdProvider);
    final chapter = ref.read(chapterProvider).clamp(1, 114);

    // Manually calculate the current ayah index based on playback position
    int ayahIndex = 0;
    final pos = _player.position;
    for (int i = _ayahOffsets.length - 1; i >= 0; i--) {
      if (pos >= _ayahOffsets[i]) {
        ayahIndex = i;
        break;
      }
    }

    final surahName = (chapter >= 1 && chapter <= kSurahNamesAr.length)
        ? kSurahNamesAr[chapter - 1]
        : 'سورة $chapter';

    state = AsyncValue.data(
      PlayerUiState(
        editionId: editionId,
        chapter: chapter,
        total: _ayahOffsets.length,
        timelineStream: _timelineStream,
        durationStream: _player.durationStream,
        positionStream: _player.positionStream,
        bufferedStream: _player.bufferedPositionStream,
        indexStream: _player.currentIndexStream.map((idx) => idx).asBroadcastStream(),
        playingStream: _player.playingStream,
        loopModeStream: _player.loopModeStream,
        volumeStream: _player.volumeStream,
        processingStateStream: _player.processingStateStream,
        totalDurationOverride: _totalDuration,
        isPlaying: _player.playing,
        currentUrl: _urls.isNotEmpty ? _urls.first : '',
        surahName: surahName,
        reciterName: _reciterName,
        currentAyah: ayahIndex,
      ),
    );
  }

  Future<void> play() async {
    await _player.play();
    if (_disposed || !mounted) return;
    _emitState();
  }

  Future<void> pause() async {
    await _player.pause();
    if (_disposed || !mounted) return;
    _emitState();
  }

  Future<void> next() async {
    final curPos = _player.position;
    int nextIdx = 0;
    for (int i = 0; i < _ayahOffsets.length; i++) {
      if (_ayahOffsets[i] > curPos + const Duration(milliseconds: 200)) {
        nextIdx = i;
        break;
      }
    }
    await _player.seek(_ayahOffsets[nextIdx]);
    if (_disposed || !mounted) return;
    _emitState();
  }

  Future<void> previous() async {
    final curPos = _player.position;
    int prevIdx = 0;
    for (int i = _ayahOffsets.length - 1; i >= 0; i--) {
      if (_ayahOffsets[i] < curPos - const Duration(seconds: 2)) {
        prevIdx = i;
        break;
      }
    }
    await _player.seek(_ayahOffsets[prevIdx]);
    if (_disposed || !mounted) return;
    _emitState();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekToIndex(int index) async {
    if (index >= 0 && index < _ayahOffsets.length) {
      await _player.seek(_ayahOffsets[index]);
    }
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    if (_disposed || !mounted) return;
    _emitState();
  }

  Future<void> toggleLoop() async {
    final nextMode = _player.loopMode == LoopMode.off
        ? LoopMode.all
        : LoopMode.off;
    await _player.setLoopMode(nextMode);
    if (_disposed || !mounted) return;
    _emitState();
  }

  Future<void> toggleMute() async {
    final nextVolume = _player.volume > 0 ? 0.0 : 1.0;
    await _player.setVolume(nextVolume);
    if (_disposed || !mounted) return;
    _emitState();
  }

  Future<void> changeEdition(String editionId) async {
    ref.read(editionIdProvider.notifier).state = editionId;
    final chapter = ref.read(chapterProvider).clamp(1, 114);
    await _loadSurah(editionId: editionId, chapter: chapter, autoPlay: false);
  }

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  Future<void> playSurah(int chapter, {int? startAyah}) async {
    final safeChapter = chapter.clamp(1, 114);
    ref.read(chapterProvider.notifier).state = safeChapter;
    final editionId = ref.read(editionIdProvider);
    await _loadSurah(
      editionId: editionId,
      chapter: safeChapter,
      autoPlay: true,
    );
  }

  Future<void> changeChapter(int chapter) async {
    final safeChapter = chapter.clamp(1, 114);
    ref.read(chapterProvider.notifier).state = safeChapter;
    final editionId = ref.read(editionIdProvider);
    await _loadSurah(
      editionId: editionId,
      chapter: safeChapter,
      autoPlay: false,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _playingSub?.cancel();
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final dailyAyahProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final s =
      ref.read(settingsProvider).whenOrNull(data: (v) => v) ??
      await ref.read(settingsServiceProvider).load();

  final editionId = s.readerEditionId.isNotEmpty
      ? s.readerEditionId
      : 'ar.alafasy';

  final dio = ref.read(dioProvider);
  final res = await dio.get(
    'https://api.alquran.cloud/v1/ayah/random/$editionId',
  );

  if (res.statusCode != 200 || res.data == null) {
    throw Exception('تعذر جلب آية اليوم');
  }

  final data = res.data['data'] ?? {};
  final text = (data['text'] ?? data['ayahText'] ?? '').toString();

  final surah = data['surah'] ?? {};
  final surahName = (surah['name'] ?? surah['englishName'] ?? 'سورة غير معروفة')
      .toString();
  final nInSurah = data['numberInSurah']?.toString() ?? '';

  return {'text': text, 'ref': '$surahName • $nInSurah'};
});

final tafsirEditionsProvider = FutureProvider<List<Map<String, String>>>((ref) {
  return ref.read(quranServiceProvider).listTafsirEditions();
});

final tafsirForAyahProvider = FutureProvider.family<String, (int, int, String)>(
  (ref, t) {
    final (surah, ayah, editionId) = t;
    return ref.read(quranServiceProvider).getAyahTafsir(surah, ayah, editionId);
  },
);

final quranSurahProvider = FutureProvider.autoDispose
    .family<Surah, (int, String)>((ref, t) {
      final (surah, editionId) = t;
      return ref.read(quranServiceProvider).getSurahText(editionId, surah);
    });

final tafsirFutureProvider = FutureProvider.autoDispose
    .family<String?, ({int surah, int ayah, String editionId})>((ref, p) async {
      final svc = ref.read(quranServiceProvider);
      try {
        final t = await svc.getAyahTafsir(p.surah, p.ayah, p.editionId);
        return (t.trim().isEmpty) ? null : t;
      } catch (_) {
        return null;
      }
    });

final surahAudioUrlsProvider = FutureProvider.autoDispose
    .family<List<String>, ({int surah, String reciterId})>((ref, p) async {
      final svc = ref.read(quranServiceProvider);
      return svc.getSurahAudioUrls(p.reciterId, p.surah);
    });

final downloadControllerProvider =
    StateNotifierProvider<DownloadController, DownloadState>((ref) {
      return DownloadController(ref);
    });


final bookmarksProvider =
    StateNotifierProvider<BookmarksController, List<Bookmark>>(
      (ref) => BookmarksController(),
    );

final bookmarksUseCaseProvider = Provider<BookmarksUseCase>(
  (ref) => BookmarksUseCase(ref),
);

final surahNameProvider = FutureProvider.family<String, int>((ref, n) {
  final uc = ref.read(bookmarksUseCaseProvider);
  return uc.getSurahName(n);
});

final surahAyatCountProvider = FutureProvider.family<int, int>((ref, n) {
  final uc = ref.read(bookmarksUseCaseProvider);
  return uc.getAyatCount(n);
});

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsServiceImpl(ref.watch(trackingServiceProvider));
});

final dailyQuranProvider = Provider<({String date, String time, List<({String text, int surah, int ayah, String surahName})> verses})>((ref) {
  final now = DateTime.now();
  // Stable random seed for the day
  final random = Random(now.year * 1000 + now.month * 100 + now.day);
  
  final List<({String text, int surah, int ayah, String surahName})> verses = [];
  
  for (int i = 0; i < 3; i++) {
    final s = random.nextInt(114) + 1;
    final totalAyah = quran.getVerseCount(s);
    final a = random.nextInt(totalAyah) + 1;
    
    verses.add((
      text: quran.getVerse(s, a, verseEndSymbol: true),
      surah: s,
      ayah: a,
      surahName: kSurahNamesAr[s - 1],
    ));
  }
  
  // Basic Arabic Date Formatting
  final monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  final dateStr = "${now.day} ${monthsAr[now.month - 1]} ${now.year}";
  
  // Time formatting (HH:mm)
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final timeStr = "$hour:$minute";
  
  return (
    date: dateStr,
    time: timeStr,
    verses: verses,
  );
});
