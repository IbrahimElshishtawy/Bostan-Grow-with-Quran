import 'dart:developer' as dev;
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  FirebaseAnalytics get instance => _analytics;

  /// Log general product events safely, sanitizing PII
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      // Sanitize parameters to avoid leaking sensitive user content (Section 28)
      final safeParams = <String, Object>{};
      if (parameters != null) {
        for (final entry in parameters.entries) {
          final key = entry.key;
          if (key == 'note' ||
              key == 'content' ||
              key == 'email' ||
              key == 'token' ||
              key == 'password') {
            continue; // Skip sensitive fields
          }
          safeParams[key] = entry.value;
        }
      }

      await _analytics.logEvent(name: name, parameters: safeParams.isEmpty ? null : safeParams);
    } catch (e) {
      dev.log('Error logging analytics event: $e', name: 'AnalyticsService');
    }
  }

  // Predefined events
  Future<void> logQuranOpened() => logEvent(name: 'quran_opened');
  Future<void> logReadingStarted({required int surah, required int page}) =>
      logEvent(name: 'reading_started', parameters: {'surah': surah, 'page': page});
  Future<void> logReadingCompleted({required int pagesRead, required int durationMinutes}) =>
      logEvent(name: 'reading_completed', parameters: {
        'pages_read': pagesRead,
        'duration_minutes': durationMinutes,
      });
  Future<void> logAudioStarted({required int surahId, required String reciterId}) =>
      logEvent(name: 'audio_started', parameters: {'surah_id': surahId, 'reciter_id': reciterId});
  Future<void> logAudioCompleted({required int surahId, required String reciterId}) =>
      logEvent(name: 'audio_completed', parameters: {'surah_id': surahId, 'reciter_id': reciterId});
  Future<void> logBookmarkCreated({required int surahId, required int ayahId}) =>
      logEvent(name: 'bookmark_created', parameters: {'surah_id': surahId, 'ayah_id': ayahId});
  Future<void> logGoalCompleted() => logEvent(name: 'goal_completed');
  Future<void> logNotificationOpened({required String type}) =>
      logEvent(name: 'notification_opened', parameters: {'type': type});
}
