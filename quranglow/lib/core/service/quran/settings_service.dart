import 'package:flutter/material.dart';
import 'package:quranglow/core/model/setting/reader_settings.dart';
import 'package:quranglow/core/service/setting/daily_reminder_kind.dart';
import 'package:quranglow/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kThemeMode = 'settings.themeMode';
  static const _kLegacyDark = 'settings.dark';
  static const _kScale = 'settings.fontScale';
  static const _kReader = 'settings.readerEditionId';
  static const _kFontFamily = 'settings.fontFamily';
  static const _kColorScheme = 'settings.colorScheme';
  static const _kAudioDownloadMode = 'settings.audioDownloadMode';
  static const _kTasbihTarget = 'settings.tasbihTarget';
  static const _kTasbihVibrate = 'settings.tasbihVibrate';
  static const _kTasbihSound = 'settings.tasbihSound';
  static const _kAdhanSoundId = 'settings.adhanSoundId';
  static const _kDailyReminderEnabled = 'settings.dailyReminderEnabled';
  static const _kDailyReminderHour = 'settings.dailyReminderHour';
  static const _kDailyReminderMinute = 'settings.dailyReminderMinute';
  static const _kDailyReminderKind = 'settings.dailyReminderKind';
  static const _kSalawatEnabled = 'settings.salawatEnabled';
  static const _kSalawatIntervalMinutes = 'settings.salawatIntervalMinutes';
  static const _kPrayerNotificationsEnabled =
      'settings.prayerNotificationsEnabled';
  static const _kAzkarMorningEnabled = 'settings.azkarMorningEnabled';
  static const _kAzkarEveningEnabled = 'settings.azkarEveningEnabled';
  static const _kAzkarAfterPrayerEnabled = 'settings.azkarAfterPrayerEnabled';

  static const _kAdhanSoundEnabled = 'settings.adhanSoundEnabled';
  static const _kDailyReminderSoundEnabled = 'settings.dailyReminderSoundEnabled';
  static const _kSalawatSoundEnabled = 'settings.salawatSoundEnabled';
  static const _kSmartLearningEnabled = 'settings.smartLearningEnabled';
  static const _kSmartLearningStrictness = 'settings.smartLearningStrictness';

  Future<AppSettings> load() async {
    final sp = await SharedPreferences.getInstance();
    final legacyDark = sp.getBool(_kLegacyDark) ?? false;
    final modeStr = sp.getString(_kThemeMode);
    final themeMode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => legacyDark ? ThemeMode.dark : ThemeMode.system,
    };
    final scale = sp.getDouble(_kScale) ?? 1.0;
    final reader = sp.getString(_kReader) ?? 'ar.alafasy';
    final fontFamily = sp.getString(_kFontFamily) ?? 'System';
    final colorSchemeStr = sp.getString(_kColorScheme) ?? 'green';
    final audioDownloadModeStr =
        sp.getString(_kAudioDownloadMode) ?? AudioDownloadMode.fullSurah.name;
    final tasbihTarget = sp.getInt(_kTasbihTarget) ?? 33;
    final tasbihVibrate = sp.getBool(_kTasbihVibrate) ?? true;
    final tasbihSound = sp.getBool(_kTasbihSound) ?? true;
    final adhanSoundId = sp.getString(_kAdhanSoundId) ?? 'makkah';
    final adhanSoundEnabled = sp.getBool(_kAdhanSoundEnabled) ?? true;
    final dailyReminderEnabled = sp.getBool(_kDailyReminderEnabled) ?? false;
    final dailyReminderSoundEnabled =
        sp.getBool(_kDailyReminderSoundEnabled) ?? true;
    final dailyReminderHour = sp.getInt(_kDailyReminderHour) ?? 7;
    final dailyReminderMinute = sp.getInt(_kDailyReminderMinute) ?? 30;
    final dailyReminderKindStr =
        sp.getString(_kDailyReminderKind) ?? DailyReminderKind.quran.name;
    final salawatEnabled = sp.getBool(_kSalawatEnabled) ?? false;
    final salawatSoundEnabled = sp.getBool(_kSalawatSoundEnabled) ?? true;
    final salawatIntervalMinutes = sp.getInt(_kSalawatIntervalMinutes) ?? 5;
    final prayerNotificationsEnabled =
        sp.getBool(_kPrayerNotificationsEnabled) ?? false;
    final smartLearningEnabled = sp.getBool(_kSmartLearningEnabled) ?? false;
    final smartLearningStrictness = sp.getInt(_kSmartLearningStrictness) ?? 1;
    final azkarMorningEnabled = sp.getBool(_kAzkarMorningEnabled) ?? false;
    final azkarEveningEnabled = sp.getBool(_kAzkarEveningEnabled) ?? false;
    final azkarAfterPrayerEnabled = sp.getBool(_kAzkarAfterPrayerEnabled) ?? false;

    final colorScheme = AppColorScheme.values.firstWhere(
      (e) => e.name == colorSchemeStr,
      orElse: () => AppColorScheme.green,
    );
    final audioDownloadMode = AudioDownloadMode.values.firstWhere(
      (e) => e.name == audioDownloadModeStr,
      orElse: () => AudioDownloadMode.fullSurah,
    );
    final dailyReminderKind = DailyReminderKind.values.firstWhere(
      (e) => e.name == dailyReminderKindStr,
      orElse: () => DailyReminderKind.quran,
    );

    return AppSettings(
      themeMode: themeMode,
      fontScale: scale,
      readerEditionId: reader,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      audioDownloadMode: audioDownloadMode,
      tasbihTarget: tasbihTarget,
      tasbihVibrate: tasbihVibrate,
      tasbihSound: tasbihSound,
      adhanSoundId: adhanSoundId,
      adhanSoundEnabled: adhanSoundEnabled,
      dailyReminderEnabled: dailyReminderEnabled,
      dailyReminderSoundEnabled: dailyReminderSoundEnabled,
      dailyReminderHour: dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute,
      dailyReminderKind: dailyReminderKind,
      salawatEnabled: salawatEnabled,
      salawatSoundEnabled: salawatSoundEnabled,
      salawatIntervalMinutes: salawatIntervalMinutes,
      prayerNotificationsEnabled: prayerNotificationsEnabled,
      smartLearningEnabled: smartLearningEnabled,
      smartLearningStrictness: smartLearningStrictness,
      azkarMorningEnabled: azkarMorningEnabled,
      azkarEveningEnabled: azkarEveningEnabled,
      azkarAfterPrayerEnabled: azkarAfterPrayerEnabled,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final sp = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await sp.setString(_kThemeMode, value);
    await sp.setBool(_kLegacyDark, mode == ThemeMode.dark);
  }

  Future<void> setDark(bool v) async {
    await setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setFontScale(double v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_kScale, v);
  }

  Future<void> setReader(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kReader, v);
  }

  Future<void> setFontFamily(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kFontFamily, v);
  }

  Future<void> setColorScheme(AppColorScheme v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kColorScheme, v.name);
  }

  Future<void> setAudioDownloadMode(AudioDownloadMode v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAudioDownloadMode, v.name);
  }

  Future<void> setTasbihTarget(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kTasbihTarget, v);
  }

  Future<void> setTasbihVibrate(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kTasbihVibrate, v);
  }

  Future<void> setTasbihSound(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kTasbihSound, v);
  }

  Future<void> setAdhanSoundId(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAdhanSoundId, v);
  }

  Future<void> setAdhanSoundEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAdhanSoundEnabled, v);
  }

  Future<void> setDailyReminderEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kDailyReminderEnabled, v);
  }

  Future<void> setDailyReminderSoundEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kDailyReminderSoundEnabled, v);
  }

  Future<void> setDailyReminderTime(TimeOfDay v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kDailyReminderHour, v.hour);
    await sp.setInt(_kDailyReminderMinute, v.minute);
  }

  Future<void> setDailyReminderKind(DailyReminderKind v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kDailyReminderKind, v.name);
  }

  Future<void> setSalawatEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kSalawatEnabled, v);
  }

  Future<void> setSalawatSoundEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kSalawatSoundEnabled, v);
  }

  Future<void> setSalawatIntervalMinutes(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kSalawatIntervalMinutes, v);
  }

  Future<void> setPrayerNotificationsEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kPrayerNotificationsEnabled, v);
  }

  Future<void> setSmartLearningEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kSmartLearningEnabled, v);
  }

  Future<void> setSmartLearningStrictness(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kSmartLearningStrictness, v);
  }

  Future<void> setAzkarMorningEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAzkarMorningEnabled, v);
  }

  Future<void> setAzkarEveningEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAzkarEveningEnabled, v);
  }

  Future<void> setAzkarAfterPrayerEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAzkarAfterPrayerEnabled, v);
  }
}
