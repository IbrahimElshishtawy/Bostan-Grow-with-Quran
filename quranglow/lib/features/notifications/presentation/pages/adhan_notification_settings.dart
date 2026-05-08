// ignore_for_file: dangling_library_doc_comments

/// Professional Adhan Notification Settings Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/providers/notification_providers.dart';

class AdhanNotificationSettingsScreen extends ConsumerWidget {
  const AdhanNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adhanSettings = ref.watch(adhanSettingsProvider);
    final notificationPermission = ref.watch(notificationPermissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adhan & Prayer Notifications'),
        backgroundColor: Colors.amberAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amberAccent, Colors.blue.shade50],
          ),
        ),
        child: ListView(
          children: [
            // Permissions Status Card
            notificationPermission.when(
              data: (permission) => _buildPermissionCard(context, permission),
              error: (error, stackTrace) => const SizedBox.shrink(),
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.amberAccent),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Adhan Settings
            _buildSettingsSection(
              title: 'Adhan Settings',
              children: [
                _buildSwitchTile(
                  context,
                  ref,
                  'Enable Adhan',
                  'Play call to prayer at prayer time',
                  adhanSettings.enableAdhan,
                  (value) => ref
                      .read(adhanSettingsProvider.notifier)
                      .updateEnableAdhan(value),
                ),
                if (adhanSettings.enableAdhan) ...[
                  const Divider(),
                  _buildAdhanVoiceSelector(context, ref, adhanSettings),
                  const Divider(),
                  _buildSliderTile(
                    'Adhan Volume',
                    adhanSettings.adhanVolume,
                    (value) => ref
                        .read(adhanSettingsProvider.notifier)
                        .updateAdhanVolume(value),
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    context,
                    ref,
                    'Vibration',
                    'Vibrate on Adhan',
                    adhanSettings.vibrationEnabled,
                    (value) => ref
                        .read(adhanSettingsProvider.notifier)
                        .updateVibrationEnabled(value),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Prayer Reminders
            _buildSettingsSection(
              title: 'Prayer Reminders',
              children: [
                _buildSwitchTile(
                  context,
                  ref,
                  'Enable Reminders',
                  'Get notified before prayer time',
                  adhanSettings.enableReminders,
                  (value) => ref
                      .read(adhanSettingsProvider.notifier)
                      .updateEnableReminders(value),
                ),
                if (adhanSettings.enableReminders) ...[
                  const Divider(),
                  _buildReminderTimePicker(context, ref, adhanSettings),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Test Notification Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () => _testNotification(context),
                icon: const Icon(Icons.notifications_active),
                label: const Text('Test Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context,
    NotificationPermissionState permission,
  ) {
    final isGranted = permission.notificationsEnabled;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: isGranted ? Colors.green.shade300 : Colors.orange.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.warning,
            color: isGranted ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGranted
                      ? 'Notifications Enabled'
                      : 'Notifications Disabled',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isGranted
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGranted
                      ? 'Prayer notifications are enabled'
                      : 'Enable notifications to receive prayer alerts',
                  style: TextStyle(
                    fontSize: 12,
                    color: isGranted
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: () {
                // Trigger notification permission request
              },
              child: const Text('Enable'),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ...children,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.amberAccent,
            activeTrackColor: Colors.amberAccent.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.amberAccent.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            onChanged: onChanged,
            min: 0,
            max: 1,
            activeColor: Colors.amberAccent,
            inactiveColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildAdhanVoiceSelector(
    BuildContext context,
    WidgetRef ref,
    AdhanSettingsState settings,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adhan Voice',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: settings.selectedAdhanVoice,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(adhanSettingsProvider.notifier)
                      .updateAdhanVoice(value);
                }
              },
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'default', child: Text('Default')),
                DropdownMenuItem(value: 'makkah', child: Text('Makkah')),
                DropdownMenuItem(value: 'madinah', child: Text('Madinah')),
                DropdownMenuItem(value: 'alaqsa', child: Text('Al-Aqsa')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTimePicker(
    BuildContext context,
    WidgetRef ref,
    AdhanSettingsState settings,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reminder Time',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<int>(
              value: settings.reminderMinutesBefore,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(adhanSettingsProvider.notifier)
                      .updateReminderMinutes(value);
                }
              },
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                DropdownMenuItem(value: 30, child: Text('30 minutes before')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _testNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification would be sent'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
