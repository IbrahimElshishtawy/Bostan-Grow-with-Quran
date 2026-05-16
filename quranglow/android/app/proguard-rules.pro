# just_audio rules
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.just_audio_windows.** { *; }

# audio_service rules
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.audioservice.AudioService { *; }
-keep class com.ryanheise.audioservice.AudioServiceConfig { *; }

# audio_session rules
-keep class com.ryanheise.audio_session.** { *; }

# Flutter local notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Preserve vital application classes
-keep class com.example.quranglow.MainActivity { *; }
-keep class com.example.quranglow.LearningWidgetProvider { *; }

# Preserve data models used in JSON serialization (Gson/others)
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# General Flutter rules for platform channels
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-keep class io.flutter.plugins.** { *; }

# Specific for haptics/sound
-keep class android.view.HapticFeedbackConstants { *; }
-keep class android.view.SoundEffectConstants { *; }
