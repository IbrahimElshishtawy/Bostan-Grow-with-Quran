// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/setting/adhan_sound.dart';
import 'package:quranglow/core/model/setting/reader_settings.dart';
import 'package:quranglow/core/service/setting/daily_reminder_kind.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';

class NotificationsSection extends ConsumerStatefulWidget {
  const NotificationsSection({super.key});

  @override
  ConsumerState<NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> {
  static const _salawatIntervals = <int>[5, 10, 15, 20, 25, 30, 60];

  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _busyPrayerSync = false;
  bool _busyPreview = false;

  String _kindLabel(DailyReminderKind kind) {
    switch (kind) {
      case DailyReminderKind.quran:
        return 'تلاوة القرآن';
      case DailyReminderKind.adhan:
        return 'الاستعداد للصلاة';
      case DailyReminderKind.dhikr:
        return 'الأذكار';
    }
  }

  void _snack(String text, {Color? bg}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: bg ?? cs.primary),
    );
  }

  Future<void> _rescheduleDaily(AppSettings settings) async {
    await NotificationService.instance.scheduleDailyReminder(
      enabled: settings.dailyReminderEnabled,
      time: settings.dailyReminderTime,
      kind: settings.dailyReminderKind,
    );
  }

  Future<void> _rescheduleSalawat(AppSettings settings) async {
    await NotificationService.instance.scheduleSalawat(
      enabled: settings.salawatEnabled,
      intervalMinutes: settings.salawatIntervalMinutes,
    );
  }

  Future<void> _syncPrayerNotifications(AppSettings settings) async {
    if (_busyPrayerSync) return;
    setState(() => _busyPrayerSync = true);
    try {
      if (!settings.prayerNotificationsEnabled) {
        await NotificationService.instance.cancelPrayerNotifications();
        return;
      }

      await NotificationService.instance.requestPermissionsIfNeededFromUI(
        context,
      );
      final days = await ref
          .read(prayerTimesServiceProvider)
          .fetchUpcomingDays();
      await NotificationService.instance.schedulePrayerNotifications(
        days: days,
        enabled: true,
      );
    } finally {
      if (mounted) {
        setState(() => _busyPrayerSync = false);
      }
    }
  }

  Future<void> _previewSelectedAdhan(AdhanSoundOption sound) async {
    if (_busyPreview) return;
    setState(() => _busyPreview = true);
    try {
      await _previewPlayer.stop();
      await _previewPlayer.setAsset(sound.assetPath);
      await _previewPlayer.seek(Duration.zero);
      await _previewPlayer.play();
    } catch (e) {
      _snack(
        'تعذر تشغيل معاينة الصوت: $e',
        bg: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() => _busyPreview = false);
      }
    }
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider).valueOrNull;

    if (settings == null) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final selectedAdhan = settings.adhanSound;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: cs.primary),
                const SizedBox(width: 8),
                const Text(
                  'إعدادات الإشعارات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'كل التذكيرات هنا لوكل على الجهاز وتستمر خارج التطبيق بعد الجدولة.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'أذان الصلاة',
              subtitle: 'تنبيهات محلية خارج التطبيق مع صوت أذان تختاره بنفسك.',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.prayerNotificationsEnabled,
                    title: const Text('تفعيل إشعارات الأذان'),
                    subtitle: const Text(
                      'جدولة المواقيت القادمة محليًا على الجهاز',
                    ),
                    onChanged: (value) async {
                      try {
                        await ref
                            .read(settingsProvider.notifier)
                            .setPrayerNotificationsEnabled(value);
                        final nextSettings = settings.copyWith(
                          prayerNotificationsEnabled: value,
                        );
                        await _syncPrayerNotifications(nextSettings);
                        _snack(
                          value
                              ? 'تم تفعيل إشعارات الأذان المحلية'
                              : 'تم إيقاف إشعارات الأذان المحلية',
                        );
                      } catch (e) {
                        _snack('تعذر تحديث إشعارات الأذان: $e', bg: cs.error);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('صوت الأذان'),
                    subtitle: Text(selectedAdhan.label),
                    trailing: DropdownButton<String>(
                      value: selectedAdhan.id,
                      onChanged: (value) async {
                        if (value == null) return;
                        try {
                          await ref
                              .read(settingsProvider.notifier)
                              .setAdhanSoundId(value);
                          final nextSettings = settings.copyWith(
                            adhanSoundId: value,
                          );
                          if (nextSettings.prayerNotificationsEnabled) {
                            await _syncPrayerNotifications(nextSettings);
                          }
                          _snack(
                            'تم تغيير صوت الأذان إلى ${AdhanSounds.byId(value).label}',
                          );
                        } catch (e) {
                          _snack('تعذر تغيير صوت الأذان: $e', bg: cs.error);
                        }
                      },
                      items: AdhanSounds.values
                          .map(
                            (sound) => DropdownMenuItem<String>(
                              value: sound.id,
                              child: Text(sound.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            icon: Icon(
                              _busyPreview
                                  ? Icons.hourglass_top_rounded
                                  : Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _busyPreview ? 'جارٍ التشغيل' : 'استماع للصوت',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: _busyPreview
                                ? null
                                : () => _previewSelectedAdhan(selectedAdhan),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                              size: 18,
                            ),
                            label: const Text(
                              'اختبار الإشعار',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () async {
                              try {
                                await NotificationService.instance
                                    .requestPermissionsIfNeededFromUI(context);
                                await _previewSelectedAdhan(selectedAdhan);
                                await NotificationService.instance.showAdhanPreview(
                                  title: 'اختبار أذان ${selectedAdhan.label}',
                                  body:
                                      'هذا إشعار محلي تجريبي للتأكد من عمل صوت الأذان خارج التطبيق.',
                                  settings: settings,
                                );
                                _snack('تم إرسال إشعار أذان تجريبي');
                              } catch (e) {
                                _snack(
                                  'تعذر إرسال إشعار الأذان التجريبي: $e',
                                  bg: cs.error,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _busyPrayerSync
                          ? null
                          : () async {
                              try {
                                await _syncPrayerNotifications(settings);
                                _snack(
                                  'تمت إعادة جدولة إشعارات الأذان القادمة',
                                );
                              } catch (e) {
                                _snack(
                                  'تعذر إعادة جدولة الأذان: $e',
                                  bg: cs.error,
                                );
                              }
                            },
                      icon: const Icon(Icons.sync_rounded),
                      label: Text(
                        _busyPrayerSync
                            ? 'جارٍ جدولة الأذان'
                            : 'إعادة جدولة الأذان القادم',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'التذكير اليومي',
              subtitle:
                  'ورد قرآني أو ذكر أو استعداد للصلاة في وقت ثابت كل يوم.',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.dailyReminderEnabled,
                    title: const Text('تفعيل التذكير اليومي'),
                    onChanged: (value) async {
                      try {
                        await ref
                            .read(settingsProvider.notifier)
                            .setDailyReminderEnabled(value);
                        final nextSettings = settings.copyWith(
                          dailyReminderEnabled: value,
                        );
                        await _rescheduleDaily(nextSettings);
                        _snack(
                          value
                              ? 'تم تفعيل التذكير اليومي'
                              : 'تم إيقاف التذكير اليومي',
                        );
                      } catch (e) {
                        _snack('تعذر تحديث التذكير اليومي: $e', bg: cs.error);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('وقت التذكير'),
                    subtitle: Text(settings.dailyReminderTime.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: settings.dailyReminderTime,
                      );
                      if (picked == null) return;
                      try {
                        await ref
                            .read(settingsProvider.notifier)
                            .setDailyReminderTime(picked);
                        final nextSettings = settings.copyWith(
                          dailyReminderHour: picked.hour,
                          dailyReminderMinute: picked.minute,
                        );
                        await _rescheduleDaily(nextSettings);
                        _snack(
                          'تم تحديث وقت التذكير إلى ${picked.format(context)}',
                        );
                      } catch (e) {
                        _snack('تعذر تحديث وقت التذكير: $e', bg: cs.error);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('نوع التذكير'),
                    subtitle: Text(_kindLabel(settings.dailyReminderKind)),
                    trailing: DropdownButton<DailyReminderKind>(
                      value: settings.dailyReminderKind,
                      onChanged: (value) async {
                        if (value == null) return;
                        try {
                          await ref
                              .read(settingsProvider.notifier)
                              .setDailyReminderKind(value);
                          final nextSettings = settings.copyWith(
                            dailyReminderKind: value,
                          );
                          await _rescheduleDaily(nextSettings);
                          _snack('تم تحديث نوع التذكير اليومي');
                        } catch (e) {
                          _snack('تعذر تحديث نوع التذكير: $e', bg: cs.error);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: DailyReminderKind.quran,
                          child: Text('القرآن'),
                        ),
                        DropdownMenuItem(
                          value: DailyReminderKind.adhan,
                          child: Text('الصلاة'),
                        ),
                        DropdownMenuItem(
                          value: DailyReminderKind.dhikr,
                          child: Text('الأذكار'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'الصلاة على النبي ﷺ',
              subtitle: 'إشعار محلي متكرر كل عدد دقائق تختاره.',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.salawatEnabled,
                    title: const Text('تفعيل التذكير المتكرر'),
                    subtitle: const Text('اللهم صل وسلم على نبينا محمد ﷺ'),
                    onChanged: (value) async {
                      try {
                        await ref
                            .read(settingsProvider.notifier)
                            .setSalawatEnabled(value);
                        final nextSettings = settings.copyWith(
                          salawatEnabled: value,
                        );
                        await _rescheduleSalawat(nextSettings);
                        _snack(
                          value
                              ? 'تم تفعيل التذكير المتكرر'
                              : 'تم إيقاف التذكير المتكرر',
                        );
                      } catch (e) {
                        _snack('تعذر تحديث التذكير المتكرر: $e', bg: cs.error);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تكرار الإشعار'),
                    subtitle: Text(
                      'كل ${settings.salawatIntervalMinutes} دقيقة',
                    ),
                    trailing: DropdownButton<int>(
                      value: settings.salawatIntervalMinutes,
                      onChanged: (value) async {
                        if (value == null) return;
                        try {
                          await ref
                              .read(settingsProvider.notifier)
                              .setSalawatIntervalMinutes(value);
                          final nextSettings = settings.copyWith(
                            salawatIntervalMinutes: value,
                          );
                          await _rescheduleSalawat(nextSettings);
                          _snack('تم تحديث تكرار التذكير');
                        } catch (e) {
                          _snack('تعذر تحديث التكرار: $e', bg: cs.error);
                        }
                      },
                      items: _salawatIntervals
                          .map(
                            (minutes) => DropdownMenuItem<int>(
                              value: minutes,
                              child: Text('كل $minutes دقيقة'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('إرسال إشعار عام تجريبي الآن'),
                onPressed: () async {
                  try {
                    await NotificationService.instance
                        .requestPermissionsIfNeededFromUI(context);
                    await NotificationService.instance.showInstant(
                      id: 991001,
                      title: 'تنبيه تجريبي من QuranGlow',
                      body:
                          'هذا إشعار محلي تجريبي للتأكد من أن الإشعارات تعمل خارج التطبيق.',
                    );
                    _snack('تم إرسال إشعار تجريبي فوري');
                  } catch (e) {
                    _snack('تعذر إرسال الإشعار التجريبي: $e', bg: cs.error);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
