import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/core_providers.dart';
import 'package:quranglow/core/service/quran/quran_service.dart';
import 'package:quranglow/core/service/sync/firebase_sync_service.dart';
import 'package:quranglow/core/service/sync/reminders_service.dart';
import 'package:quranglow/core/service/tracking_service.dart';
import 'package:quranglow/core/service/quran/settings_service.dart';
import 'package:quranglow/core/service/setting/location_service.dart';
import 'package:quranglow/core/service/setting/prayer_times_service.dart';
import 'package:quranglow/core/service/setting/download_service.dart';
import 'package:quranglow/core/service/quran/stats_service.dart';
import 'package:quranglow/core/service/quran/stats_service_impl.dart';
import 'package:quranglow/core/service/setting/goals_service.dart';
export 'package:quranglow/core/service/update_service.dart';

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

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(dio: ref.watch(dioProvider));
});

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsServiceImpl(ref.watch(trackingServiceProvider));
});

final goalsServiceProvider = Provider<GoalsService>((ref) {
  final svc = GoalsService(storage: ref.watch(storageProvider));
  ref.onDispose(svc.dispose);
  return svc;
});
