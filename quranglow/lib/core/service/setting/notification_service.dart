import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quranglow/core/model/prayer/prayer_times_data.dart';
import 'package:quranglow/core/model/setting/reader_settings.dart';
import 'package:quranglow/core/service/quran/settings_service.dart';
import 'package:quranglow/core/service/setting/daily_reminder_kind.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  bool get _isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  static const _dailyChannelId = 'daily_reminder_ch';
  static const _salawatChannelId = 'salawat_ch';
  static const _remindersChannelId = 'reminders_ch';
  static const _smartLearningChannelId = 'smart_learning_ch';
  static const _deviceChannel = MethodChannel('quranglow/device');
  static const _fallbackTimezoneName = 'Africa/Cairo';

  static const _dailyId = 1001;
  static const _salawatId = 1002;
  static const _salawatBatchSize = 96;
  static const _prayerBaseId = 2000;
  static const _prayerScheduleWindowDays = 30;
  static const _prayerCount = 5;
  static const _azkarMorningId = 3001;
  static const _azkarEveningId = 3002;
  static const _azkarPrayerBaseId = 3100;
  static const _smartLearningIdBase = 4000;

  Future<void> init() async {
    if (!_isSupported) return;

    await _configureLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(settings);

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      try {
        await android?.requestExactAlarmsPermission();
      } catch (_) {}
    }
  }

  Future<void> requestPermissionsIfNeededFromUI(BuildContext context) async {
    if (!_isSupported || !context.mounted) return;

    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final enabled = await android?.areNotificationsEnabled();
        if (enabled != true) {
          await android?.requestNotificationsPermission();
        }
        try {
          await android?.requestExactAlarmsPermission();
        } catch (_) {}
        return;
      }

      if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
        return;
      }

      if (Platform.isMacOS) {
        final mac = _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        await mac?.requestPermissions(alert: true, badge: true, sound: true);
        return;
      }
    } catch (e) {
      debugPrint('[NOTIF] permission request skipped: $e');
    }
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (kIsWeb || !Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      final canScheduleExact = await android?.canScheduleExactNotifications();
      if (canScheduleExact == false) {
        return AndroidScheduleMode.inexactAllowWhileIdle;
      }
    } catch (e) {
      debugPrint('[NOTIF] exact alarm capability check skipped: $e');
    }
    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  Future<void> _configureLocalTimezone({String? preferredTimezone}) async {
    tz.initializeTimeZones();

    final candidateTimezones = <String>{
      if (preferredTimezone != null && preferredTimezone.trim().isNotEmpty)
        preferredTimezone.trim(),
    };

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      try {
        final deviceTimezone = await _deviceChannel.invokeMethod<String>(
          'getTimeZone',
        );
        if (deviceTimezone != null && deviceTimezone.trim().isNotEmpty) {
          candidateTimezones.add(deviceTimezone.trim());
        }
      } catch (e) {
        debugPrint('[NOTIF] device timezone lookup skipped: $e');
      }
    }

    candidateTimezones.add(_fallbackTimezoneName);

    for (final timezoneName in candidateTimezones) {
      try {
        tz.setLocalLocation(tz.getLocation(timezoneName));
        return;
      } catch (e) {
        debugPrint('[NOTIF] unsupported timezone "$timezoneName": $e');
      }
    }
  }

  Future<void> _ensurePrayerChannel(AppSettings settings) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    final adhanSound = settings.adhanSound;
    final channelId = _prayerChannelId(adhanSound.id);

    try {
      await android.deleteNotificationChannel(channelId);
    } catch (_) {}

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        'أذان الصلوات',
        description: 'تنبيهات الأذان مع صوت أذان مخصص',
        importance: Importance.max,
        playSound: settings.adhanSoundEnabled,
        sound: settings.adhanSoundEnabled
            ? RawResourceAndroidNotificationSound(adhanSound.resourceName)
            : null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        showBadge: true,
      ),
    );
  }

  Future<void> _ensureSalawatChannel(AppSettings settings) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    const channelId = _salawatChannelId;

    try {
      await android.deleteNotificationChannel(channelId);
    } catch (_) {}

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        'تذكير الصلاة على النبي ﷺ',
        description: 'تذكير دوري محلي للصلاة على النبي ﷺ',
        importance: Importance.max,
        playSound: settings.salawatSoundEnabled,
        sound: settings.salawatSoundEnabled
            ? const RawResourceAndroidNotificationSound('salawat')
            : null,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        showBadge: true,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay t) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      t.hour,
      t.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> scheduleDailyReminder({
    required bool enabled,
    required TimeOfDay time,
    DailyReminderKind kind = DailyReminderKind.quran,
  }) async {
    if (!_isSupported) return;
    await _plugin.cancel(_dailyId);
    if (!enabled) return;

    final settings = await SettingsService().load();
    final mode = await _androidScheduleMode();

    final android = AndroidNotificationDetails(
      _dailyChannelId,
      'التذكير اليومي',
      channelDescription: 'تذكير يومي للورد والذكر والاستعداد للصلاة',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: settings.dailyReminderSoundEnabled,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    const ios = DarwinNotificationDetails();
    const mac = DarwinNotificationDetails();
    const win = WindowsNotificationDetails();

    final (title, body) = switch (kind) {
      DailyReminderKind.quran => (
        'وردك القرآني ينتظرك',
        'افتح المصحف الآن وخذ دقائق هادئة مع التلاوة والقراءة.',
      ),
      DailyReminderKind.adhan => (
        'استعد للصلاة',
        'اقترب وقت الصلاة، توضأ وتهيأ للوقوف بين يدي الله.',
      ),
      DailyReminderKind.dhikr => (
        'وقت الذكر',
        'جدد قلبك الآن بذكر الله واستحضر الطمأنينة.',
      ),
    };

    await _plugin.zonedSchedule(
      _dailyId,
      title,
      body,
      _nextInstanceOf(time),
      NotificationDetails(android: android, iOS: ios, macOS: mac, windows: win),
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleSalawat({
    required bool enabled,
    required int intervalMinutes,
  }) async {
    if (!_isSupported) return;
    for (var i = 0; i < _salawatBatchSize; i++) {
      await _plugin.cancel(_salawatId + i);
    }
    if (!enabled) return;

    final settings = await SettingsService().load();
    await _ensureSalawatChannel(settings);
    final mode = await _androidScheduleMode();

    final android = AndroidNotificationDetails(
      _salawatChannelId,
      'تذكير الصلاة على النبي ﷺ',
      channelDescription: 'تذكير دوري محلي للصلاة على النبي ﷺ',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      playSound: settings.salawatSoundEnabled,
      sound: settings.salawatSoundEnabled
          ? const RawResourceAndroidNotificationSound('salawat')
          : null,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    const ios = DarwinNotificationDetails();
    const mac = DarwinNotificationDetails();
    const win = WindowsNotificationDetails();

    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i < _salawatBatchSize; i++) {
      final scheduled = now.add(Duration(minutes: intervalMinutes * (i + 1)));
      await _plugin.zonedSchedule(
        _salawatId + i,
        'الصلاة على النبي ﷺ',
        'اللهم صل وسلم على نبينا محمد ﷺ',
        scheduled,
        NotificationDetails(
          android: android,
          iOS: ios,
          macOS: mac,
          windows: win,
        ),
        androidScheduleMode: mode,
      );
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required bool daily,
  }) async {
    if (!_isSupported) return;
    await _plugin.cancel(id);

    final mode = await _androidScheduleMode();

    final android = AndroidNotificationDetails(
      _remindersChannelId,
      'تذكيرات الأذكار',
      channelDescription: 'تذكيرات الأذكار والمواعيد التي يحددها المستخدم',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    const ios = DarwinNotificationDetails();
    const mac = DarwinNotificationDetails();
    const win = WindowsNotificationDetails();

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled;

    if (daily) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        when.hour,
        when.minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    } else {
      scheduled = tz.TZDateTime.from(when, tz.local);
      if (scheduled.isBefore(now)) {
        scheduled = now.add(const Duration(seconds: 5));
      }
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(android: android, iOS: ios, macOS: mac, windows: win),
      androidScheduleMode: mode,
      matchDateTimeComponents: daily ? DateTimeComponents.time : null,
    );
  }

  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isSupported) return;

    const android = AndroidNotificationDetails(
      _remindersChannelId,
      'تذكيرات الأذكار',
      channelDescription: 'تذكيرات الأذكار والمواعيد التي يحددها المستخدم',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const ios = DarwinNotificationDetails();
    const mac = DarwinNotificationDetails();
    const win = WindowsNotificationDetails();

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: android,
        iOS: ios,
        macOS: mac,
        windows: win,
      ),
    );
  }

  Future<void> scheduleSmartLearningReminders({
    required bool enabled,
    int strictness = 1,
  }) async {
    if (!_isSupported) return;
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(_smartLearningIdBase + i);
    }
    if (!enabled) return;

    final mode = await _androidScheduleMode();
    const android = AndroidNotificationDetails(
      _smartLearningChannelId,
      'تنبيهات التعلم النشط',
      channelDescription: 'تذكير ذكي عند الانقطاع عن القراءة أو التعلم',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    final now = tz.TZDateTime.now(tz.local);

    final reminders = strictness == 3
        ? [
            (
              delay: 24,
              title: 'افتقدنا نور تلاوتك',
              body: 'لا تجعل اليوم يمر دون نصيب من كتاب الله، انضم إلينا الآن.',
            ),
            (
              delay: 36,
              title: 'وردك اليومي أمانة',
              body: 'الاستمرارية سر النجاح، القرآن ينير دربك فلا تغفل عنه.',
            ),
            (
              delay: 48,
              title: 'أين أنت يا محب القرآن؟',
              body: 'بستانك بانتظارك، لا تبتعد كثيراً عن آيات الله البينات.',
            ),
            (
              delay: 72,
              title: 'نداء للقلب الذاكر',
              body: 'اشحن روحك بآيات السكينة، القرآن شفاء لما في الصدور.',
            ),
          ]
        : strictness == 2
        ? [
            (
              delay: 48,
              title: 'وقت مستقطع للروح',
              body: 'بضع دقائق مع القرآن كفيلة بتغيير يومك للأفضل.',
            ),
            (
              delay: 96,
              title: 'تذكير بالورد اليومي',
              body: 'لا يزال بستانك يزهر بقرائتك، عد لنبع الصفاء.',
            ),
          ]
        : [
            (
              delay: 72,
              title: 'بانتظار عودتك',
              body: 'اشتقنا لتفاعلك في بستان، القرآن يفتح لك آفاقاً جديدة.',
            ),
          ];

    for (var i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      await _plugin.zonedSchedule(
        _smartLearningIdBase + i,
        r.title,
        r.body,
        now.add(Duration(hours: r.delay)),
        const NotificationDetails(
          android: android,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: mode,
      );
    }
  }

  static const _firstStagePromptIdBase = 5000;

  Future<void> scheduleFirstStageReminders({
    required bool hasStartedFirstStage,
  }) async {
    if (!_isSupported) return;
    
    final settings = await SettingsService().load();
    final enabled = settings.smartLearningEnabled;
    
    // Cancel any existing first stage prompts
    await _plugin.cancel(_firstStagePromptIdBase);
    await _plugin.cancel(_firstStagePromptIdBase + 1);

    if (!enabled || hasStartedFirstStage) return;

    final mode = await _androidScheduleMode();
    const android = AndroidNotificationDetails(
      _smartLearningChannelId,
      'تنبيهات التعلم النشط',
      channelDescription: 'تذكير ذكي عند الانقطاع عن القراءة أو التعلم',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    const ios = DarwinNotificationDetails();
    const mac = DarwinNotificationDetails();

    final now = tz.TZDateTime.now(tz.local);

    // 1. Encouraging/enthusiastic notification after 24 hours (1 day)
    await _plugin.zonedSchedule(
      _firstStagePromptIdBase,
      'رحلتك في بستان النور تنتظرك! ✨',
      'ابدأ خطوتك الأولى في فهم آيات القرآن وتدبرها الآن. نحن بانتظارك لتنال أول نجمة! 🌟',
      now.add(const Duration(days: 1)),
      const NotificationDetails(android: android, iOS: ios, macOS: mac),
      androidScheduleMode: mode,
    );

    // 2. Sad/reflective notification after 3 days (72 hours) if still not started
    await _plugin.zonedSchedule(
      _firstStagePromptIdBase + 1,
      'محزونون لغيابك عن بستان القرآن.. 😔',
      'مضت ثلاثة أيام ولم تبدأ خطوتك الأولى بعد. لا تحرم قلبك من ربيع آيات الله، ابدأ الآن ولو بآية واحدة.',
      now.add(const Duration(days: 3)),
      const NotificationDetails(android: android, iOS: ios, macOS: mac),
      androidScheduleMode: mode,
    );
  }

  Future<void> showAdhanPreview({
    required String title,
    required String body,
    required AppSettings settings,
  }) async {
    if (!_isSupported) return;

    // Request permissions before showing the preview to ensure it works
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }

    await _ensurePrayerChannel(settings);
    final adhanSound = settings.adhanSound;

    final android = AndroidNotificationDetails(
      _prayerChannelId(adhanSound.id),
      'أذان الصلوات',
      channelDescription: 'تنبيهات الأذان مع صوت أذان مخصص',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      showWhen: true,
      enableVibration: true,
      playSound: settings.adhanSoundEnabled,
      sound: settings.adhanSoundEnabled
          ? RawResourceAndroidNotificationSound(adhanSound.resourceName)
          : null,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      channelShowBadge: true,
      fullScreenIntent: true,
    );

    await _plugin.show(
      991002,
      title,
      body,
      NotificationDetails(
        android: android,
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      ),
    );
  }

  Future<void> schedulePrayerNotifications({
    required List<PrayerScheduleDay> days,
    bool enabled = true,
  }) async {
    if (!_isSupported) return;
    await cancelPrayerNotifications();
    if (!enabled || days.isEmpty) return;

    await _configureLocalTimezone(
      preferredTimezone: _firstValidPrayerTimezone(days),
    );
    final settings = await SettingsService().load();
    await _ensurePrayerChannel(settings);
    final adhanSound = settings.adhanSound;
    final android = AndroidNotificationDetails(
      _prayerChannelId(adhanSound.id),
      'أذان الصلوات',
      channelDescription: 'تنبيهات الأذان مع صوت أذان مخصص',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      showWhen: true,
      enableVibration: true,
      playSound: settings.adhanSoundEnabled,
      sound: settings.adhanSoundEnabled
          ? RawResourceAndroidNotificationSound(adhanSound.resourceName)
          : null,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      channelShowBadge: true,
      fullScreenIntent: true,
    );
    const ios = DarwinNotificationDetails();
    const mac = DarwinNotificationDetails();
    const win = WindowsNotificationDetails();

    final mode = await _androidScheduleMode();
    final now = tz.TZDateTime.now(tz.local);
    const orderedPrayerKeys = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final daysToSchedule = days
        .take(_prayerScheduleWindowDays)
        .toList(growable: false);

    for (var dayIndex = 0; dayIndex < daysToSchedule.length; dayIndex++) {
      final day = daysToSchedule[dayIndex];
      for (
        var prayerIndex = 0;
        prayerIndex < orderedPrayerKeys.length;
        prayerIndex++
      ) {
        final key = orderedPrayerKeys[prayerIndex];
        final time = day.prayers[key];
        if (time == null) continue;

        final scheduled = tz.TZDateTime.from(time, tz.local);
        if (!scheduled.isAfter(now)) continue;

        // 1. Schedule the main Adhan notification
        await _plugin.zonedSchedule(
          _prayerNotificationId(dayIndex, prayerIndex),
          'حان الآن موعد صلاة ${_arabicPrayerName(key)}',
          'حيّ على الصلاة، الآن أذان ${_arabicPrayerName(key)}.',
          scheduled,
          NotificationDetails(
            android: android,
            iOS: ios,
            macOS: mac,
            windows: win,
          ),
          androidScheduleMode: mode,
        );

        // 2. Schedule the "Did you pray?" follow-up notification (5 minutes later)
        final followUpTime = scheduled.add(const Duration(minutes: 5));
        final religiousMsg = _getReligiousReminderTitleAndBody(key);
        await _plugin.zonedSchedule(
          _prayerFollowUpId(dayIndex, prayerIndex),
          religiousMsg['title']!,
          religiousMsg['body']!,
          followUpTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _prayerChannelId(adhanSound.id),
              'أذان الصلوات',
              channelDescription: 'تنبيهات الأذان مع صوت أذان مخصص',
              importance: Importance.max,
              priority: Priority.high,
              category: AndroidNotificationCategory.alarm,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              showWhen: true,
              enableVibration: true,
              playSound: true,
              sound: null, // Use standard notification sound for the question
              icon: '@mipmap/ic_launcher',
              largeIcon: const DrawableResourceAndroidBitmap(
                '@mipmap/ic_launcher',
              ),
              channelShowBadge: true,
              styleInformation: const BigTextStyleInformation(''),
            ),
            iOS: ios,
            macOS: mac,
            windows: win,
          ),
          androidScheduleMode: mode,
        );
      }
    }
  }

  Map<String, String> _getReligiousReminderTitleAndBody(String prayerKey) {
    switch (prayerKey) {
      case 'Fajr':
        return {
          'title': 'حبيبي في الله، حان وقت صلاة الفجر 🤍',
          'body': 'الجمال والراحة ينتظرانك في وقوفك بين يدي الله.. لا تفوّت الصلاة، أقبل إليها بقلبٍ مشتاق ✨',
        };
      case 'Dhuhr':
        return {
          'title': 'نور صلاتك يناديك لصلاة الظهر 🕊️',
          'body': 'ارحل بقلبك عن الدنيا لدقائق معدودة، لتغتسل من هموم يومك في رحاب الصلاة 🌿',
        };
      case 'Asr':
        return {
          'title': 'صلاة العصر يا رفيق الجنة 🌟',
          'body': 'أرح قلبك وأقم فرضك، فلا تفوّت صلاة العصر فإنها صلاة وسطى عظيمة الأجر 🤍',
        };
      case 'Maghrib':
        return {
          'title': 'حان وقت السكينة.. صلاة المغرب 🌅',
          'body': 'خمس دقائق مضت على الأذان، صلاتك هي صلتك بخالقك ومصدر طمأنينتك.. قم إليها الآن 🌱',
        };
      case 'Isha':
        return {
          'title': 'خِتام يومك الجميل.. صلاة العشاء 🌙',
          'body': 'أنهِ يومك بوقوفٍ خاشع بين يدي ربك لتنعم بليلة هادئة ونفس مطمئنة. أقم صلاتك يا طيب 💎',
        };
      default:
        return {
          'title': 'نداء من الله.. حان وقت الصلاة 🤍',
          'body': 'الصلاة هي صلتك بربك، ونور لقلبك، فلا تدع شواغل الدنيا تؤخرك عن لقائه 🕊️',
        };
    }
  }

  int _prayerFollowUpId(int dayIndex, int prayerIndex) {
    return _prayerBaseId + 100 + (dayIndex * 10) + prayerIndex;
  }

  Future<void> cancelPrayerNotifications() async {
    if (!_isSupported) return;
    for (var dayIndex = 0; dayIndex < _prayerScheduleWindowDays; dayIndex++) {
      for (var prayerIndex = 0; prayerIndex < _prayerCount; prayerIndex++) {
        await _plugin.cancel(_prayerNotificationId(dayIndex, prayerIndex));
        await _plugin.cancel(_prayerFollowUpId(dayIndex, prayerIndex));
      }
    }
  }

  Future<void> scheduleMorningAzkarReminder({required bool enabled}) async {
    if (!_isSupported) return;
    await _plugin.cancel(_azkarMorningId);
    if (!enabled) return;
    await scheduleReminder(
      id: _azkarMorningId,
      title: 'أذكار الصباح',
      body: 'ابدأ يومك بذكر الله ونور الطمأنينة.',
      when: DateTime(2000, 1, 1, 8, 0),
      daily: true,
    );
  }

  Future<void> scheduleEveningAzkarReminder({required bool enabled}) async {
    if (!_isSupported) return;
    await _plugin.cancel(_azkarEveningId);
    if (!enabled) return;
    await scheduleReminder(
      id: _azkarEveningId,
      title: 'أذكار المساء',
      body: 'اختم يومك بذكر الله ودعاء السكينة.',
      when: DateTime(2000, 1, 1, 18, 0),
      daily: true,
    );
  }

  Future<void> scheduleAfterPrayerAzkarReminders({
    required bool enabled,
    required PrayerTimesData data,
  }) async {
    if (!_isSupported) return;
    await cancelAfterPrayerAzkarReminders();
    if (!enabled) return;

    final mode = await _androidScheduleMode();
    const android = AndroidNotificationDetails(
      _remindersChannelId,
      'تذكيرات الأذكار',
      channelDescription: 'تذكيرات الأذكار والمواعيد التي يحددها المستخدم',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    const ios = DarwinNotificationDetails();
    const mac = DarwinNotificationDetails();
    const win = WindowsNotificationDetails();

    const prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    for (var i = 0; i < prayerOrder.length; i++) {
      final key = prayerOrder[i];
      final prayerTime = data.prayers[key];
      if (prayerTime == null) continue;

      final afterPrayer = prayerTime.add(const Duration(minutes: 15));
      final scheduled = _nextInstanceOf(
        TimeOfDay(hour: afterPrayer.hour, minute: afterPrayer.minute),
      );

      await _plugin.zonedSchedule(
        _azkarPrayerBaseId + i,
        'أذكار بعد الصلاة',
        'حان وقت أذكار ما بعد صلاة ${_arabicPrayerName(key)}.',
        scheduled,
        const NotificationDetails(
          android: android,
          iOS: ios,
          macOS: mac,
          windows: win,
        ),
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAfterPrayerAzkarReminders() async {
    if (!_isSupported) return;
    for (var i = 0; i < 5; i++) {
      await _plugin.cancel(_azkarPrayerBaseId + i);
    }
  }

  Future<void> cancel(int id) async {
    if (!_isSupported) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_isSupported) return;
    await _plugin.cancelAll();
  }

  static String _prayerChannelId(String soundId) =>
      'adhan_channel_${soundId}_v4';

  int _prayerNotificationId(int dayIndex, int prayerIndex) {
    return _prayerBaseId + (dayIndex * 10) + prayerIndex;
  }

  String? _firstValidPrayerTimezone(List<PrayerScheduleDay> days) {
    for (final day in days) {
      final timezoneName = day.timezone.trim();
      if (timezoneName.isEmpty) continue;
      try {
        tz.getLocation(timezoneName);
        return timezoneName;
      } catch (_) {}
    }
    return null;
  }

  String _arabicPrayerName(String key) {
    switch (key) {
      case 'Fajr':
        return 'الفجر';
      case 'Dhuhr':
        return 'الظهر';
      case 'Asr':
        return 'العصر';
      case 'Maghrib':
        return 'المغرب';
      case 'Isha':
        return 'العشاء';
      default:
        return key;
    }
  }
}
