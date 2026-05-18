import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quranglow/core/data/surah_names_ar.dart';
import 'package:quranglow/core/di/service_providers.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/core/model/setting/reader_settings.dart';
import 'package:quranglow/core/model/setting/goal.dart';
import 'package:quranglow/core/model/prayer/prayer_times_data.dart';
import 'package:quranglow/core/theme/theme_controller.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';
import 'package:quranglow/core/service/setting/daily_reminder_kind.dart';

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

  Future<void> setPrayerNotificationsEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(prayerNotificationsEnabled: enabled));
    await ref.read(settingsServiceProvider).setPrayerNotificationsEnabled(enabled);
  }

  Future<void> setAdhanSoundEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(adhanSoundEnabled: enabled));
    await ref.read(settingsServiceProvider).setAdhanSoundEnabled(enabled);
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(dailyReminderEnabled: enabled));
    await ref.read(settingsServiceProvider).setDailyReminderEnabled(enabled);
  }

  Future<void> setDailyReminderSoundEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(dailyReminderSoundEnabled: enabled));
    await ref.read(settingsServiceProvider).setDailyReminderSoundEnabled(enabled);
  }

  Future<void> setSalawatEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(salawatEnabled: enabled));
    await ref.read(settingsServiceProvider).setSalawatEnabled(enabled);
  }

  Future<void> setSalawatSoundEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(salawatSoundEnabled: enabled));
    await ref.read(settingsServiceProvider).setSalawatSoundEnabled(enabled);
  }

  Future<void> setAzkarMorningEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(azkarMorningEnabled: enabled));
    await ref.read(settingsServiceProvider).setAzkarMorningEnabled(enabled);
    await NotificationService.instance.scheduleMorningAzkarReminder(
      enabled: enabled,
    );
  }

  Future<void> setAzkarEveningEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(azkarEveningEnabled: enabled));
    await ref.read(settingsServiceProvider).setAzkarEveningEnabled(enabled);
    await NotificationService.instance.scheduleEveningAzkarReminder(
      enabled: enabled,
    );
  }

  Future<void> setAzkarAfterPrayerEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(azkarAfterPrayerEnabled: enabled));
    await ref.read(settingsServiceProvider).setAzkarAfterPrayerEnabled(enabled);

    if (enabled) {
      final prayerTimes = await ref
          .read(prayerTimesServiceProvider)
          .fetchForToday();
      await NotificationService.instance.scheduleAfterPrayerAzkarReminders(
        enabled: true,
        data: prayerTimes,
      );
    } else {
      await NotificationService.instance.cancelAfterPrayerAzkarReminders();
    }
  }

  Future<void> setSmartLearningEnabled(bool enabled) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(smartLearningEnabled: enabled));
    await ref.read(settingsServiceProvider).setSmartLearningEnabled(enabled);
  }

  Future<void> setAdhanSoundId(String soundId) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(adhanSoundId: soundId));
    await ref.read(settingsServiceProvider).setAdhanSoundId(soundId);
  }

  Future<void> setDailyReminderTime(TimeOfDay time) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(
      dailyReminderHour: time.hour,
      dailyReminderMinute: time.minute,
    ));
    await ref.read(settingsServiceProvider).setDailyReminderTime(time);
  }

  Future<void> setDailyReminderKind(DailyReminderKind kind) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(dailyReminderKind: kind));
    await ref.read(settingsServiceProvider).setDailyReminderKind(kind);
  }

  Future<void> setSalawatIntervalMinutes(int mins) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(salawatIntervalMinutes: mins));
    await ref.read(settingsServiceProvider).setSalawatIntervalMinutes(mins);
  }

  Future<void> setSmartLearningStrictness(int strictness) async {
    final cur = state.maybeWhen(data: (s) => s, orElse: () => null);
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(smartLearningStrictness: strictness));
    await ref.read(settingsServiceProvider).setSmartLearningStrictness(strictness);
  }
}

final goalsStreamProvider = StreamProvider.autoDispose<List<Goal>>((ref) {
  return ref.watch(goalsServiceProvider).watchGoalsWithInitial();
});

final todayPrayersProvider = FutureProvider.autoDispose<PrayerTimesData>((ref) {
  final svc = ref.watch(prayerTimesServiceProvider);
  return svc.fetchForToday();
});

final quranMetadataProvider =
    Provider<List<({int number, String name, int ayatCount})>>((ref) {
      return List.generate(114, (i) {
        final s = i + 1;
        return (
          number: s,
          name: kSurahNamesAr[i],
          ayatCount: quran.getVerseCount(s),
        );
      });
    });

final quranAllProvider = FutureProvider.autoDispose.family<List<Surah>, String>(
  (ref, editionId) {
    final service = ref.read(quranServiceProvider);
    return service.getQuranAllText(editionId);
  },
);
