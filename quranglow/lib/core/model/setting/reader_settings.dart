import 'package:flutter/material.dart';
import 'package:quranglow/core/model/setting/adhan_sound.dart';
import 'package:quranglow/core/service/setting/daily_reminder_kind.dart';
import 'package:quranglow/core/theme/theme_controller.dart';

enum AudioDownloadMode { fullSurah, selectedAyat }

class AppSettings {
  final ThemeMode? _themeMode;
  final double fontScale;
  final String readerEditionId;
  final String fontFamily;
  final AppColorScheme colorScheme;
  final AudioDownloadMode audioDownloadMode;
  final int tasbihTarget;
  final bool tasbihVibrate;
  final bool tasbihSound;
  final String adhanSoundId;
  final bool adhanSoundEnabled;
  final bool dailyReminderEnabled;
  final bool dailyReminderSoundEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final DailyReminderKind dailyReminderKind;
  final bool salawatEnabled;
  final bool salawatSoundEnabled;
  final int salawatIntervalMinutes;
  final bool prayerNotificationsEnabled;
  final bool smartLearningEnabled;
  final int smartLearningStrictness;

  const AppSettings({
    ThemeMode? themeMode,
    required this.fontScale,
    required this.readerEditionId,
    this.fontFamily = 'System',
    this.colorScheme = AppColorScheme.green,
    this.audioDownloadMode = AudioDownloadMode.fullSurah,
    this.tasbihTarget = 33,
    this.tasbihVibrate = true,
    this.tasbihSound = true,
    this.adhanSoundId = 'makkah',
    this.adhanSoundEnabled = true,
    this.dailyReminderEnabled = false,
    this.dailyReminderSoundEnabled = true,
    this.dailyReminderHour = 7,
    this.dailyReminderMinute = 30,
    this.dailyReminderKind = DailyReminderKind.quran,
    this.salawatEnabled = false,
    this.salawatSoundEnabled = true,
    this.salawatIntervalMinutes = 5,
    this.prayerNotificationsEnabled = false,
    this.smartLearningEnabled = false,
    this.smartLearningStrictness = 1,
  }) : _themeMode = themeMode;

  ThemeMode get themeMode => _themeMode ?? ThemeMode.system;

  bool get darkMode => themeMode == ThemeMode.dark;
  AdhanSoundOption get adhanSound => AdhanSounds.byId(adhanSoundId);
  TimeOfDay get dailyReminderTime =>
      TimeOfDay(hour: dailyReminderHour, minute: dailyReminderMinute);

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? fontScale,
    String? readerEditionId,
    String? fontFamily,
    AppColorScheme? colorScheme,
    AudioDownloadMode? audioDownloadMode,
    int? tasbihTarget,
    bool? tasbihVibrate,
    bool? tasbihSound,
    String? adhanSoundId,
    bool? adhanSoundEnabled,
    bool? dailyReminderEnabled,
    bool? dailyReminderSoundEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    DailyReminderKind? dailyReminderKind,
    bool? salawatEnabled,
    bool? salawatSoundEnabled,
    int? salawatIntervalMinutes,
    bool? prayerNotificationsEnabled,
    bool? smartLearningEnabled,
    int? smartLearningStrictness,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    fontScale: fontScale ?? this.fontScale,
    readerEditionId: readerEditionId ?? this.readerEditionId,
    fontFamily: fontFamily ?? this.fontFamily,
    colorScheme: colorScheme ?? this.colorScheme,
    audioDownloadMode: audioDownloadMode ?? this.audioDownloadMode,
    tasbihTarget: tasbihTarget ?? this.tasbihTarget,
    tasbihVibrate: tasbihVibrate ?? this.tasbihVibrate,
    tasbihSound: tasbihSound ?? this.tasbihSound,
    adhanSoundId: adhanSoundId ?? this.adhanSoundId,
    adhanSoundEnabled: adhanSoundEnabled ?? this.adhanSoundEnabled,
    dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
    dailyReminderSoundEnabled:
        dailyReminderSoundEnabled ?? this.dailyReminderSoundEnabled,
    dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
    dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
    dailyReminderKind: dailyReminderKind ?? this.dailyReminderKind,
    salawatEnabled: salawatEnabled ?? this.salawatEnabled,
    salawatSoundEnabled: salawatSoundEnabled ?? this.salawatSoundEnabled,
    salawatIntervalMinutes:
        salawatIntervalMinutes ?? this.salawatIntervalMinutes,
    prayerNotificationsEnabled:
        prayerNotificationsEnabled ?? this.prayerNotificationsEnabled,
    smartLearningEnabled: smartLearningEnabled ?? this.smartLearningEnabled,
    smartLearningStrictness:
        smartLearningStrictness ?? this.smartLearningStrictness,
  );
}
