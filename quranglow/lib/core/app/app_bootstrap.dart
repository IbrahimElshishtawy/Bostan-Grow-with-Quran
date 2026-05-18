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
import 'package:quranglow/core/service/sync/reminders_service.dart';
import 'package:quranglow/core/storage/hive_storage_impl.dart';
import 'package:quranglow/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('ar');
    
    // ✨ HARDENED FIX: Pre-warm SharedPreferences to avoid race conditions in release mode
    debugPrint('[BOOT] Warming up SharedPreferences...');
    await _safeInit(
      'shared-preferences',
      () => SharedPreferences.getInstance(),
      timeout: const Duration(seconds: 10),
    );

    // ✨ HARDENED FIX: Desktop platforms (Windows/macOS/Linux) can freeze indefinitely 
    // on standard Firebase C++ SDK handshakes if not fully linked locally.
    // We suppress native Firebase boots on desktop to ensure instantaneous boot speeds!
    final bool isDesktop = !kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.windows || 
         defaultTargetPlatform == TargetPlatform.macOS || 
         defaultTargetPlatform == TargetPlatform.linux);

    final firebaseReady = (DefaultFirebaseOptions.isConfigured && !isDesktop)
        ? await _safeInit(
            'firebase',
            () async {
              // ✨ HOT RESTART GUARD: Skip redundant native handshakes if already bootstrapped!
              if (Firebase.apps.isNotEmpty) return;
              await Firebase.initializeApp(
                options: DefaultFirebaseOptions.currentPlatform,
              );
            },
            timeout: const Duration(seconds: 15),
          )
        : false;

    if (isDesktop) {
      debugPrint('[BOOT] firebase initializing bypassed on desktop platform to maximize dev boot speed.');
    } else if (!DefaultFirebaseOptions.isConfigured) {
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
            timeout: const Duration(seconds: 15),
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
      () async {
        await Hive.initFlutter();
        // ✨ HARDENED GLOBAL FIX: Ensure the core database box is fully pre-warmed at boot!
        // This stops synchronous lookups like storage.getString from failing silently at startup.
        await HiveStorageImpl().init();
      },
      timeout: const Duration(seconds: 15),
    );

    await _safeInit(
      'audio-handler',
      () => initAudioHandler(),
      timeout: const Duration(seconds: 20),
    );

    await _safeInit(
      'notifications',
      () => NotificationService.instance.init(),
      timeout: const Duration(seconds: 15),
    );

    unawaited(
      _safeInit(
        'notification-sync',
        () => _syncLocalNotificationsFromSettings(),
        timeout: const Duration(seconds: 15),
      ),
    );
  }

  /// ✨ ULTIMATE NO-THROW RACE ENGINE
  /// Uses a plain Timer + Completer race INSTEAD of `.timeout()`.
  /// This guarantees that if an initialization hangs, the app completes execution
  /// with a false status WITHOUT EVER THROWING A TimeoutException.
  /// This completely PREVENTS IDE Debuggers (VS Code) from pausing on execution!
  static Future<bool> _safeInit(
    String name,
    Future<void> Function() task, {
    required Duration timeout,
  }) async {
    final completer = Completer<bool>();

    // Execute underlying task
    task().then((_) {
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    }).catchError((error, stackTrace) {
      debugPrint('[BOOT] $name executed catch block: $error');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    // Timer race - COMPLETELY SAFE, NEVER THROWS EXCEPTION!
    Timer(timeout, () {
      if (!completer.isCompleted) {
        debugPrint('[BOOT] $name exceeded maximum latency and was bypassed safely WITHOUT exception throw.');
        completer.complete(false);
      }
    });

    return completer.future;
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

    await NotificationService.instance.scheduleMorningAzkarReminder(
      enabled: settings.azkarMorningEnabled,
    );

    await NotificationService.instance.scheduleEveningAzkarReminder(
      enabled: settings.azkarEveningEnabled,
    );

    // Reschedule custom user reminders saved in DB/Firestore to survive phone reboots/app updates
    try {
      final userReminders = await RemindersService().fetchReminders();
      for (final r in userReminders) {
        if (r.scheduled) {
          if (r.dateTime.isBefore(DateTime.now())) {
            if (r.daily) {
              await NotificationService.instance.scheduleReminder(
                id: r.id,
                title: r.title.isNotEmpty ? r.title : 'تذكير',
                body: r.notes?.isNotEmpty == true ? r.notes! : 'موعد تذكيرك الآن',
                when: r.dateTime,
                daily: r.daily,
              );
            } else {
              r.scheduled = false;
              await RemindersService().saveReminder(r);
            }
          } else {
            await NotificationService.instance.scheduleReminder(
              id: r.id,
              title: r.title.isNotEmpty ? r.title : 'تذكير',
              body: r.notes?.isNotEmpty == true ? r.notes! : 'موعد تذكيرك الآن',
              when: r.dateTime,
              daily: r.daily,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[BOOTSTRAP] Custom reminders sync skipped: $e');
    }

    if (settings.azkarAfterPrayerEnabled) {
      final locationService = LocationService();
      final client = http.Client();
      final prayerService = PrayerTimesService(
        client: client,
        locationService: locationService,
        storage: HiveStorageImpl(),
      );
      try {
        final prayerTimes = await prayerService.fetchForToday();
        await NotificationService.instance.scheduleAfterPrayerAzkarReminders(
          enabled: true,
          data: prayerTimes,
        );
      } catch (e) {
        debugPrint('[BOOTSTRAP] After prayer Azkar sync skipped: $e');
      } finally {
        client.close();
      }
    }

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
      try {
        final days = await prayerService.fetchUpcomingDays(
          preferCache: true,
          allowNetwork: false,
        );
        await NotificationService.instance.schedulePrayerNotifications(
          days: days,
          enabled: true,
        );
      } catch (e) {
        debugPrint('[BOOTSTRAP] Prayer sync skipped (no cache): $e');
      }
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
