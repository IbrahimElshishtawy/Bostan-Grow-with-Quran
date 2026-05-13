// ignore_for_file: dangling_library_doc_comments
/// User settings and preferences controller
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ThemeMode {
  light,
  dark,
  system,
}

enum TextSize {
  small,
  medium,
  large,
  extraLarge,
}

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textSize = TextSize.medium,
    this.brightness = 1.0,
    this.arabicFontSize = 24.0,
    this.translationFontSize = 16.0,
    this.enableTajweed = true,
    this.enableTranslation = true,
    this.enableTransliteration = false,
    this.audioQuality = 'high',
    this.autoPlayAudio = false,
    this.repeatMode = 'off',
    this.language = 'en',
    this.notificationsEnabled = true,
    this.offlineMode = false,
    this.preferredReciterId = 'ar.alafasy',
  });

  final ThemeMode themeMode;
  final TextSize textSize;
  final double brightness;
  final double arabicFontSize;
  final double translationFontSize;
  final bool enableTajweed;
  final bool enableTranslation;
  final bool enableTransliteration;
  final String audioQuality;
  final bool autoPlayAudio;
  final String repeatMode;
  final String language;
  final bool notificationsEnabled;
  final bool offlineMode;
  final String preferredReciterId;

  AppSettings copyWith({
    ThemeMode? themeMode,
    TextSize? textSize,
    double? brightness,
    double? arabicFontSize,
    double? translationFontSize,
    bool? enableTajweed,
    bool? enableTranslation,
    bool? enableTransliteration,
    String? audioQuality,
    bool? autoPlayAudio,
    String? repeatMode,
    String? language,
    bool? notificationsEnabled,
    bool? offlineMode,
    String? preferredReciterId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      textSize: textSize ?? this.textSize,
      brightness: brightness ?? this.brightness,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      enableTajweed: enableTajweed ?? this.enableTajweed,
      enableTranslation: enableTranslation ?? this.enableTranslation,
      enableTransliteration: enableTransliteration ?? this.enableTransliteration,
      audioQuality: audioQuality ?? this.audioQuality,
      autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
      repeatMode: repeatMode ?? this.repeatMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      offlineMode: offlineMode ?? this.offlineMode,
      preferredReciterId: preferredReciterId ?? this.preferredReciterId,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'textSize': textSize.name,
    'brightness': brightness,
    'arabicFontSize': arabicFontSize,
    'translationFontSize': translationFontSize,
    'enableTajweed': enableTajweed,
    'enableTranslation': enableTranslation,
    'enableTransliteration': enableTransliteration,
    'audioQuality': audioQuality,
    'autoPlayAudio': autoPlayAudio,
    'repeatMode': repeatMode,
    'language': language,
    'notificationsEnabled': notificationsEnabled,
    'offlineMode': offlineMode,
    'preferredReciterId': preferredReciterId,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (t) => t.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      textSize: TextSize.values.firstWhere(
        (t) => t.name == json['textSize'],
        orElse: () => TextSize.medium,
      ),
      brightness: json['brightness'] as double? ?? 1.0,
      arabicFontSize: json['arabicFontSize'] as double? ?? 24.0,
      translationFontSize: json['translationFontSize'] as double? ?? 16.0,
      enableTajweed: json['enableTajweed'] as bool? ?? true,
      enableTranslation: json['enableTranslation'] as bool? ?? true,
      enableTransliteration: json['enableTransliteration'] as bool? ?? false,
      audioQuality: json['audioQuality'] as String? ?? 'high',
      autoPlayAudio: json['autoPlayAudio'] as bool? ?? false,
      repeatMode: json['repeatMode'] as String? ?? 'off',
      language: json['language'] as String? ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      offlineMode: json['offlineMode'] as bool? ?? false,
      preferredReciterId: json['preferredReciterId'] as String? ?? 'ar.alafasy',
    );
  }
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings());

  /// Update theme mode
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  /// Update text size
  void setTextSize(TextSize size) {
    state = state.copyWith(textSize: size);
  }

  /// Update brightness
  void setBrightness(double brightness) {
    state = state.copyWith(brightness: brightness);
  }

  /// Update Arabic font size
  void setArabicFontSize(double size) {
    state = state.copyWith(arabicFontSize: size);
  }

  /// Update translation font size
  void setTranslationFontSize(double size) {
    state = state.copyWith(translationFontSize: size);
  }

  /// Toggle Tajweed
  void toggleTajweed() {
    state = state.copyWith(enableTajweed: !state.enableTajweed);
  }

  /// Toggle Translation
  void toggleTranslation() {
    state = state.copyWith(enableTranslation: !state.enableTranslation);
  }

  /// Toggle Transliteration
  void toggleTransliteration() {
    state = state.copyWith(enableTransliteration: !state.enableTransliteration);
  }

  /// Set audio quality
  void setAudioQuality(String quality) {
    state = state.copyWith(audioQuality: quality);
  }

  /// Toggle auto-play audio
  void toggleAutoPlayAudio() {
    state = state.copyWith(autoPlayAudio: !state.autoPlayAudio);
  }

  /// Set repeat mode
  void setRepeatMode(String mode) {
    state = state.copyWith(repeatMode: mode);
  }

  /// Set language
  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  /// Toggle notifications
  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  /// Toggle offline mode
  void toggleOfflineMode() {
    state = state.copyWith(offlineMode: !state.offlineMode);
  }

  /// Update preferred reciter
  void setPreferredReciterId(String reciterId) {
    state = state.copyWith(preferredReciterId: reciterId);
  }

  /// Reset to defaults
  void resetToDefaults() {
    state = const AppSettings();
  }
}
