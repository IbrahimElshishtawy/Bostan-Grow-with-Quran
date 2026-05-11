// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:quranglow/core/service/audio/audio_locator.dart';
import 'package:quranglow/core/service/quran/settings_service.dart';
import 'package:quranglow/core/service/setting/location_service.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';
import 'package:quranglow/core/service/setting/prayer_times_service.dart';
import 'package:quranglow/core/service/sync/firebase_sync_service.dart';
import 'package:quranglow/core/storage/hive_storage_impl.dart';
import 'package:quranglow/firebase_options.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    GoogleFonts.config.allowRuntimeFetching = false;

    final firebaseReady = DefaultFirebaseOptions.isConfigured
        ? await _safeInit(
            'firebase',
            () => Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            ),
            timeout: const Duration(seconds: 20),
          )
        : false;

    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        '[BOOT] firebase skipped: firebase_options.dart uses placeholders',
      );
    }

    if (firebaseReady) {
      if (!kDebugMode) {
        unawaited(
          _safeInit(
            'firebase-anon-signin',
            () => FirebaseSyncService().signInAnonymously(),
            timeout: const Duration(seconds: 20),
          ),
        );
      } else {
        debugPrint('[BOOT] firebase-anon-signin skipped on debug build');
      }

      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    await _safeInit(
      'hive',
      () => Hive.initFlutter(),
      timeout: const Duration(seconds: 20),
    );

    await _safeInit(
      'audio-handler',
      () => initAudioHandler(),
      timeout: const Duration(seconds: 25),
    );

    await _safeInit(
      'notifications',
      () => NotificationService.instance.init(),
      timeout: const Duration(seconds: 20),
    );

    unawaited(
      _safeInit(
        'notification-sync',
        () => _syncLocalNotificationsFromSettings(),
        timeout: const Duration(seconds: 20),
      ),
    );
  }

  static Future<bool> _safeInit(
    String name,
    Future<void> Function() task, {
    required Duration timeout,
  }) async {
    try {
      await task().timeout(timeout);
      return true;
    } catch (e, st) {
      debugPrint('[BOOT] $name failed/skipped: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  static Future<void> _syncLocalNotificationsFromSettings() async {
    final settings = await SettingsService().load();

    await NotificationService.instance.scheduleDailyReminder(
      enabled: settings.dailyReminderEnabled,
      time: settings.dailyReminderTime,
      kind: settings.dailyReminderKind,
    );

    await NotificationService.instance.scheduleSalawat(
      enabled: settings.salawatEnabled,
      intervalMinutes: settings.salawatIntervalMinutes,
    );

    if (!settings.prayerNotificationsEnabled) {
      await NotificationService.instance.cancelPrayerNotifications();
      return;
    }

    final locationService = LocationService();
    final client = http.Client();
    try {
      final prayerService = PrayerTimesService(
        client: client,
        locationService: locationService,
        storage: HiveStorageImpl(),
      );
      final days = await prayerService.fetchUpcomingDays(
        preferCache: true,
        allowNetwork: false,
      );
      await NotificationService.instance.schedulePrayerNotifications(
        days: days,
        enabled: true,
      );
    } finally {
      client.close();
      locationService.dispose();
    }
  }
}

class SplashBootstrap {
  static WidgetsBinding initBinding() {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: binding);
    return binding;
  }

  static void removeSplash() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }
}
