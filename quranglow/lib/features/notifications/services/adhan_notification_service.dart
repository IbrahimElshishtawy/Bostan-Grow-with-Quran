/// Adhan notification and reminder service
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:quranglow/core/models/prayer_models.dart';

class AdhanNotificationService {
  static final AdhanNotificationService _instance =
      AdhanNotificationService._internal();

  factory AdhanNotificationService() {
    return _instance;
  }

  AdhanNotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  final Map<String, int> _notificationIds = {};

  /// Initialize notification service
  Future<void> initialize() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('app_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Create notification channels
    await _createNotificationChannels();
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    const adhanChannel = AndroidNotificationChannel(
      'adhan_channel',
      'Adhan Notifications',
      description: 'Notifications for prayer times',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    const reminderChannel = AndroidNotificationChannel(
      'reminder_channel',
      'Prayer Reminders',
      description: 'Reminders before prayer times',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(adhanChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(reminderChannel);
  }

  /// Schedule Adhan notification for prayer time
  Future<void> scheduleAdhanNotification({
    required PrayerTime prayer,
    required String adhanUrl,
    required bool playSound,
  }) async {
    final notificationId = _getNotificationId(prayer.type.name);

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Time for ${prayer.type.englishName}',
        'It\'s time to pray ${prayer.type.englishName}',
        tz.TZDateTime.from(prayer.time, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'adhan_channel',
            'Adhan Notifications',
            channelDescription: 'Notifications for prayer times',
            importance: Importance.max,
            priority: Priority.high,
            playSound: playSound,
            enableVibration: true,
            fullScreenIntent: true,
            sound: const RawResourceAndroidNotificationSound('adhan'),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
      );
    } catch (e) {
      throw Exception('Failed to schedule Adhan notification: $e');
    }
  }

  /// Schedule prayer reminder notification
  Future<void> scheduleReminderNotification({
    required PrayerTime prayer,
    required int minutesBefore,
  }) async {
    final reminderTime = prayer.time.subtract(Duration(minutes: minutesBefore));
    final notificationId = _getNotificationId('${prayer.type.name}_reminder');

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '${prayer.type.englishName} in $minutesBefore minutes',
        'Prepare for ${prayer.type.englishName} prayer',
        tz.TZDateTime.from(reminderTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Prayer Reminders',
            channelDescription: 'Reminders before prayer times',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
      );
    } catch (e) {
      throw Exception('Failed to schedule reminder notification: $e');
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(String prayerType) async {
    final notificationId = _getNotificationId(prayerType);
    await _notificationsPlugin.cancel(notificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get notification ID for prayer type
  int _getNotificationId(String prayerType) {
    if (!_notificationIds.containsKey(prayerType)) {
      _notificationIds[prayerType] = _notificationIds.length + 1;
    }
    return _notificationIds[prayerType]!;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool androidGranted = true;
    bool iosGranted = true;

    if (androidPlugin != null) {
      androidGranted =
          await androidPlugin.requestNotificationsPermission() ?? false;
    }

    if (iosPlugin != null) {
      iosGranted =
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return androidGranted && iosGranted;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }

    return true;
  }
}

class AdhanSettings {
  const AdhanSettings({
    this.enableAdhan = true,
    this.enableReminders = true,
    this.reminderMinutesBefore = 5,
    this.adhanVolume = 1.0,
    this.vibrationEnabled = true,
    this.silentModeHandling = SilentModeHandling.respectSilent,
    this.selectedAdhanVoice = 'default',
  });

  final bool enableAdhan;
  final bool enableReminders;
  final int reminderMinutesBefore;
  final double adhanVolume;
  final bool vibrationEnabled;
  final SilentModeHandling silentModeHandling;
  final String selectedAdhanVoice;

  AdhanSettings copyWith({
    bool? enableAdhan,
    bool? enableReminders,
    int? reminderMinutesBefore,
    double? adhanVolume,
    bool? vibrationEnabled,
    SilentModeHandling? silentModeHandling,
    String? selectedAdhanVoice,
  }) {
    return AdhanSettings(
      enableAdhan: enableAdhan ?? this.enableAdhan,
      enableReminders: enableReminders ?? this.enableReminders,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      adhanVolume: adhanVolume ?? this.adhanVolume,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      silentModeHandling: silentModeHandling ?? this.silentModeHandling,
      selectedAdhanVoice: selectedAdhanVoice ?? this.selectedAdhanVoice,
    );
  }

  Map<String, dynamic> toJson() => {
    'enableAdhan': enableAdhan,
    'enableReminders': enableReminders,
    'reminderMinutesBefore': reminderMinutesBefore,
    'adhanVolume': adhanVolume,
    'vibrationEnabled': vibrationEnabled,
    'silentModeHandling': silentModeHandling.name,
    'selectedAdhanVoice': selectedAdhanVoice,
  };

  factory AdhanSettings.fromJson(Map<String, dynamic> json) {
    return AdhanSettings(
      enableAdhan: json['enableAdhan'] as bool? ?? true,
      enableReminders: json['enableReminders'] as bool? ?? true,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int? ?? 5,
      adhanVolume: json['adhanVolume'] as double? ?? 1.0,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      silentModeHandling: SilentModeHandling.values.firstWhere(
        (s) => s.name == json['silentModeHandling'],
        orElse: () => SilentModeHandling.respectSilent,
      ),
      selectedAdhanVoice: json['selectedAdhanVoice'] as String? ?? 'default',
    );
  }
}

enum SilentModeHandling { respectSilent, ignoreSilent, vibrateOnly }
