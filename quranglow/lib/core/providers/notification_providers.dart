/// Notification and Adhan settings Riverpod providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/notifications/services/adhan_notification_service.dart';

/// Adhan settings state
class AdhanSettingsState {
  final bool enableAdhan;
  final bool enableReminders;
  final int reminderMinutesBefore;
  final double adhanVolume;
  final bool vibrationEnabled;
  final String selectedAdhanVoice;

  AdhanSettingsState({
    required this.enableAdhan,
    required this.enableReminders,
    required this.reminderMinutesBefore,
    required this.adhanVolume,
    required this.vibrationEnabled,
    required this.selectedAdhanVoice,
  });

  AdhanSettingsState copyWith({
    bool? enableAdhan,
    bool? enableReminders,
    int? reminderMinutesBefore,
    double? adhanVolume,
    bool? vibrationEnabled,
    String? selectedAdhanVoice,
  }) {
    return AdhanSettingsState(
      enableAdhan: enableAdhan ?? this.enableAdhan,
      enableReminders: enableReminders ?? this.enableReminders,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      adhanVolume: adhanVolume ?? this.adhanVolume,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      selectedAdhanVoice: selectedAdhanVoice ?? this.selectedAdhanVoice,
    );
  }
}

/// Adhan settings notifier
class AdhanSettingsNotifier extends StateNotifier<AdhanSettingsState> {
  AdhanSettingsNotifier()
      : super(AdhanSettingsState(
          enableAdhan: true,
          enableReminders: true,
          reminderMinutesBefore: 5,
          adhanVolume: 1.0,
          vibrationEnabled: true,
          selectedAdhanVoice: 'default',
        ));

  void updateEnableAdhan(bool value) {
    state = state.copyWith(enableAdhan: value);
  }

  void updateEnableReminders(bool value) {
    state = state.copyWith(enableReminders: value);
  }

  void updateReminderMinutes(int minutes) {
    state = state.copyWith(reminderMinutesBefore: minutes);
  }

  void updateAdhanVolume(double volume) {
    state = state.copyWith(adhanVolume: volume);
  }

  void updateVibrationEnabled(bool value) {
    state = state.copyWith(vibrationEnabled: value);
  }

  void updateAdhanVoice(String voice) {
    state = state.copyWith(selectedAdhanVoice: voice);
  }
}

/// Adhan settings provider
final adhanSettingsProvider =
    StateNotifierProvider<AdhanSettingsNotifier, AdhanSettingsState>((ref) {
  return AdhanSettingsNotifier();
});

/// Available Adhan sounds
const adhanSounds = [
  'default',
  'makkah',
  'madinah',
  'alaqsa',
];

/// Notification permissions state
class NotificationPermissionState {
  final bool androidGranted;
  final bool iosGranted;
  final bool notificationsEnabled;

  NotificationPermissionState({
    required this.androidGranted,
    required this.iosGranted,
    required this.notificationsEnabled,
  });

  NotificationPermissionState copyWith({
    bool? androidGranted,
    bool? iosGranted,
    bool? notificationsEnabled,
  }) {
    return NotificationPermissionState(
      androidGranted: androidGranted ?? this.androidGranted,
      iosGranted: iosGranted ?? this.iosGranted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

/// Check notification permissions
final notificationPermissionProvider =
    FutureProvider<NotificationPermissionState>((ref) async {
  final service = AdhanNotificationService();
  
  try {
    final permissions = await service.requestPermissions();
    final enabled = await service.areNotificationsEnabled();
    
    return NotificationPermissionState(
      androidGranted: permissions,
      iosGranted: permissions,
      notificationsEnabled: enabled,
    );
  } catch (e) {
    return NotificationPermissionState(
      androidGranted: false,
      iosGranted: false,
      notificationsEnabled: false,
    );
  }
});

/// Track notification scheduled state
class NotificationScheduleState {
  final bool isScheduling;
  final String? lastError;
  final DateTime? lastScheduleTime;

  NotificationScheduleState({
    required this.isScheduling,
    this.lastError,
    this.lastScheduleTime,
  });

  NotificationScheduleState copyWith({
    bool? isScheduling,
    String? lastError,
    DateTime? lastScheduleTime,
  }) {
    return NotificationScheduleState(
      isScheduling: isScheduling ?? this.isScheduling,
      lastError: lastError ?? this.lastError,
      lastScheduleTime: lastScheduleTime ?? this.lastScheduleTime,
    );
  }
}
