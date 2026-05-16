import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/setting/adhan_sound.dart';
import 'package:quranglow/core/model/setting/reader_settings.dart';
import 'package:quranglow/core/service/setting/daily_reminder_kind.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';
import 'package:quranglow/features/settings/presentation/widgets/section_header.dart';

class NotificationsSection extends ConsumerStatefulWidget {
  const NotificationsSection({super.key});

  @override
  ConsumerState<NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> {
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _busyPreview = false;

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  void _snack(String text, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: bg ?? Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
        'تعذر تشغيل المعاينة: $e',
        bg: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _busyPreview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;

    return settingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (st) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('إعدادات الإشعارات'),
          const SizedBox(height: 8),

          // 🕋 Prayer Adhan Card
          _buildPremiumCard(
            context,
            title: 'أذان الصلوات',
            icon: Icons.mosque_rounded,
            status: st.prayerNotificationsEnabled ? 'مفعل' : 'متوقف',
            children: [
              _buildModernSwitch(
                context,
                title: 'تفعيل إشعارات الأذان',
                subtitle: 'تنبيهات المواقيت خارج التطبيق',
                value: st.prayerNotificationsEnabled,
                onChanged: (val) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setPrayerNotificationsEnabled(val);
                  await NotificationService.instance
                      .schedulePrayerNotifications(
                        days: await ref
                            .read(prayerTimesServiceProvider)
                            .fetchUpcomingDays(),
                        enabled: val,
                      );
                  _snack(
                    val ? 'تم تفعيل إشعارات الأذان' : 'تم إيقاف إشعارات الأذان',
                  );
                },
              ),
              if (st.prayerNotificationsEnabled) ...[
                const Divider(height: 32),
                _buildModernSwitch(
                  context,
                  title: 'صوت الأذان',
                  subtitle: 'تشغيل صوت الأذان عند التنبيه',
                  value: st.adhanSoundEnabled,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .setAdhanSoundEnabled(val),
                ),
                const SizedBox(height: 16),
                _buildAdhanSelector(context, st),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // 📅 Daily Reminder Card
          _buildPremiumCard(
            context,
            title: 'التذكير اليومي',
            icon: Icons.event_note_rounded,
            status: st.dailyReminderEnabled ? 'مفعل' : 'متوقف',
            children: [
              _buildModernSwitch(
                context,
                title: 'تفعيل التذكير اليومي',
                subtitle: 'وردك اليومي في وقت محدد',
                value: st.dailyReminderEnabled,
                onChanged: (val) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setDailyReminderEnabled(val);
                  await NotificationService.instance.scheduleDailyReminder(
                    enabled: val,
                    time: st.dailyReminderTime,
                    kind: st.dailyReminderKind,
                  );
                },
              ),
              if (st.dailyReminderEnabled) ...[
                const Divider(height: 32),
                _buildModernSwitch(
                  context,
                  title: 'صوت التنبيه',
                  subtitle: 'إشعار مع صوت تذكير هادئ',
                  value: st.dailyReminderSoundEnabled,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .setDailyReminderSoundEnabled(val),
                ),
                const SizedBox(height: 16),
                _buildTimeAndKindPicker(context, st),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // 📿 Salawat Card
          _buildPremiumCard(
            context,
            title: 'الصلاة على النبي ﷺ',
            icon: Icons.auto_awesome_rounded,
            status: st.salawatEnabled ? 'مفعل' : 'متوقف',
            children: [
              _buildModernSwitch(
                context,
                title: 'تفعيل التذكير المتكرر',
                subtitle: 'صلّ وسلم على نبينا محمد ﷺ',
                value: st.salawatEnabled,
                onChanged: (val) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setSalawatEnabled(val);
                  await NotificationService.instance.scheduleSalawat(
                    enabled: val,
                    intervalMinutes: st.salawatIntervalMinutes,
                  );
                },
              ),
              if (st.salawatEnabled) ...[
                const Divider(height: 32),
                _buildModernSwitch(
                  context,
                  title: 'صوت التذكير',
                  subtitle: 'تنبيه صوتي بالصلاة على النبي',
                  value: st.salawatSoundEnabled,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .setSalawatSoundEnabled(val),
                ),
                const SizedBox(height: 16),
                _buildIntervalSelector(context, st),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // 📿 Azkar & Wird Card
          _buildPremiumCard(
            context,
            title: 'الأذكار والأوراد',
            icon: Icons.menu_book_rounded,
            status: (st.azkarMorningEnabled || st.azkarEveningEnabled || st.azkarAfterPrayerEnabled) ? 'مفعل' : 'متوقف',
            children: [
              _buildModernSwitch(
                context,
                title: 'أذكار الصباح',
                subtitle: 'تذكير يومي عند الساعة 8 صباحاً',
                value: st.azkarMorningEnabled,
                onChanged: (val) => ref
                    .read(settingsProvider.notifier)
                    .setAzkarMorningEnabled(val),
              ),
              const Divider(height: 24),
              _buildModernSwitch(
                context,
                title: 'أذكار المساء',
                subtitle: 'تذكير يومي عند الساعة 6 مساءً',
                value: st.azkarEveningEnabled,
                onChanged: (val) => ref
                    .read(settingsProvider.notifier)
                    .setAzkarEveningEnabled(val),
              ),
              const Divider(height: 24),
              _buildModernSwitch(
                context,
                title: 'أذكار بعد الصلاة',
                subtitle: 'تذكير بالأذكار بعد كل صلاة بـ 15 دقيقة',
                value: st.azkarAfterPrayerEnabled,
                onChanged: (val) => ref
                    .read(settingsProvider.notifier)
                    .setAzkarAfterPrayerEnabled(val),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🎓 Smart Learning Card
          _buildPremiumCard(
            context,
            title: 'التعلم الذكي والتحفيز',
            icon: Icons.psychology_rounded,
            status: st.smartLearningEnabled ? 'مفعل' : 'متوقف',
            children: [
              _buildModernSwitch(
                context,
                title: 'تفعيل التنبيهات الذكية',
                subtitle: 'رسائل تحفيزية عند الانقطاع عن التلاوة',
                value: st.smartLearningEnabled,
                onChanged: (val) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setSmartLearningEnabled(val);
                },
              ),
              if (st.smartLearningEnabled) ...[
                const Divider(height: 32),
                const Text(
                  'مستوى الإلحاح في التذكير',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStrictnessSelector(context, st),
                const SizedBox(height: 8),
                Text(
                  _getStrictnessDescription(st.smartLearningStrictness),
                  style: TextStyle(
                    color: cs.primary.withOpacity(0.7),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),
          // Test Button
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await NotificationService.instance
                    .requestPermissionsIfNeededFromUI(context);
                await NotificationService.instance.showInstant(
                  id: 999,
                  title: 'اختبار الإشعارات',
                  body: 'الإشعارات تعمل بنجاح خارج التطبيق ✅',
                );
                _snack('تم إرسال إشعار تجريبي');
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('اختبار إشعار فوري الآن'),
              style: TextButton.styleFrom(foregroundColor: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    String? status,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'مفعل' 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'مفعل' ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernSwitch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: cs.primary,
        ),
      ],
    );
  }

  Widget _buildAdhanSelector(BuildContext context, AppSettings st) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'صوت الأذان المفضل',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AdhanSounds.values.map((sound) {
              final isSelected = st.adhanSoundId == sound.id;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(sound.label),
                  selected: isSelected,
                  onSelected: (val) async {
                    if (val) {
                      await ref
                          .read(settingsProvider.notifier)
                          .setAdhanSoundId(sound.id);
                      if (st.prayerNotificationsEnabled) {
                        await NotificationService.instance
                            .schedulePrayerNotifications(
                              days: await ref
                                  .read(prayerTimesServiceProvider)
                                  .fetchUpcomingDays(),
                              enabled: true,
                            );
                      }
                      _previewSelectedAdhan(sound);
                    }
                  },
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: cs.primary.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide.none,
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAndKindPicker(BuildContext context, AppSettings st) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'وقت التذكير',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            st.dailyReminderTime.format(context),
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
          ),
          trailing: Icon(Icons.access_time_rounded, color: cs.primary),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: st.dailyReminderTime,
            );
            if (picked != null) {
              await ref
                  .read(settingsProvider.notifier)
                  .setDailyReminderTime(picked);
              await NotificationService.instance.scheduleDailyReminder(
                enabled: true,
                time: picked,
                kind: st.dailyReminderKind,
              );
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: DailyReminderKind.values.map((kind) {
            final isSelected = st.dailyReminderKind == kind;
            final label = switch (kind) {
              DailyReminderKind.quran => 'القرآن',
              DailyReminderKind.adhan => 'الصلاة',
              DailyReminderKind.dhikr => 'الأذكار',
            };
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (val) async {
                  if (val) {
                    await ref
                        .read(settingsProvider.notifier)
                        .setDailyReminderKind(kind);
                    await NotificationService.instance.scheduleDailyReminder(
                      enabled: true,
                      time: st.dailyReminderTime,
                      kind: kind,
                    );
                  }
                },
                selectedColor: cs.secondary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: cs.secondary.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide.none,
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIntervalSelector(BuildContext context, AppSettings st) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تكرار التذكير',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [15, 30, 60, 120].map((mins) {
            final isSelected = st.salawatIntervalMinutes == mins;
            return ChoiceChip(
              label: Text(
                mins >= 60 ? 'كل ${mins ~/ 60} ساعة' : 'كل $mins دقيقة',
              ),
              selected: isSelected,
              onSelected: (val) async {
                if (val) {
                  await ref
                      .read(settingsProvider.notifier)
                      .setSalawatIntervalMinutes(mins);
                  await NotificationService.instance.scheduleSalawat(
                    enabled: true,
                    intervalMinutes: mins,
                  );
                }
              },
              selectedColor: cs.tertiary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: cs.tertiary.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide.none,
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStrictnessSelector(BuildContext context, AppSettings st) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [1, 2, 3].map((level) {
        final isSelected = st.smartLearningStrictness == level;
        final label = switch (level) {
          1 => 'هادئ',
          2 => 'مستمر',
          3 => 'عاجل',
          _ => '',
        };
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                ref
                    .read(settingsProvider.notifier)
                    .setSmartLearningStrictness(level);
              }
            },
            selectedColor: cs.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getStrictnessDescription(int level) {
    return switch (level) {
      1 => 'تنبيهات لطيفة تظهر بعد 3 أيام من الانقطاع.',
      2 => 'تنبيهات منتظمة تظهر كل يومين لتشجيعك.',
      3 => 'تنبيهات قوية ومتكررة تبدأ بعد 24 ساعة من التكاسل.',
      _ => '',
    };
  }
}
