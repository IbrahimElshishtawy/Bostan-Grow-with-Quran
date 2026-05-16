// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';
import 'package:quranglow/features/azkar/presentation/widgets/reminder_editor.dart';
import 'package:quranglow/features/azkar/presentation/widgets/reminder_tile.dart';
import '../../../../../core/model/reminder/reminder.dart';

class ReminderList extends ConsumerStatefulWidget {
  const ReminderList({super.key});

  @override
  ConsumerState<ReminderList> createState() => _ReminderListState();
}

class _ReminderListState extends ConsumerState<ReminderList> {
  final List<Reminder> _items = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final reminders = await ref.read(remindersServiceProvider).fetchReminders();
    if (mounted) {
      setState(() {
        _items
          ..clear()
          ..addAll(reminders);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('إضافة تنبيه جديد'),
        onPressed: _openEditor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _SectionCard(
            title: 'تذكيراتي المخصصة',
            subtitle: 'أنشئ تذكيرات خاصة بك لمواعيد الأذكار، الصلوات، أو أي ورد خاص بك.',
            child: _items.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => ReminderTile(
                      r: _items[i],
                      onEdit: () => _openEditor(edit: _items[i]),
                      onSchedule: () => _schedule(_items[i]),
                      onCancel: () => _cancel(_items[i]),
                      onDelete: () => _delete(_items[i]),
                    ),
                  ),
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Future<void> _openEditor({Reminder? edit}) async {
    final res = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReminderEditor(existing: edit),
    );
    if (!mounted || res == null) return;
    setState(() {
      if (edit == null) {
        _items.add(res);
        ref.read(remindersServiceProvider).saveReminder(res);
      } else {
        edit.title = res.title;
        edit.dateTime = res.dateTime;
        edit.daily = res.daily;
        edit.notes = res.notes;
        ref.read(remindersServiceProvider).saveReminder(edit);
      }
    });
  }

  Future<void> _schedule(Reminder r) async {
    try {
      if (r.dateTime.isBefore(DateTime.now()) && !r.daily) {
        final now = DateTime.now();
        r.dateTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          r.dateTime.hour,
          r.dateTime.minute,
        );
      }

      await NotificationService.instance.scheduleReminder(
        id: r.id,
        title: r.title.isNotEmpty ? r.title : 'تذكير',
        body: r.notes?.isNotEmpty == true ? r.notes! : 'موعد تذكيرك الآن',
        when: r.dateTime,
        daily: r.daily,
      );

      if (!mounted) return;
      setState(() => r.scheduled = true);
      _snack('تمت جدولة التذكير بنجاح');
    } catch (e) {
      _snack('فشلت الجدولة: $e');
    }
  }

  Future<void> _cancel(Reminder r) async {
    try {
      await NotificationService.instance.cancel(r.id);
      if (!mounted) return;
      setState(() => r.scheduled = false);
      _snack('تم إلغاء التذكير');
    } catch (e) {
      _snack('فشل الإلغاء: $e');
    }
  }

  void _delete(Reminder r) async {
    try {
      NotificationService.instance.cancel(r.id).catchError((_) {});
      if (!mounted) return;
      setState(() => _items.removeWhere((x) => x.id == r.id));
      await ref.read(remindersServiceProvider).deleteReminder(r.id);
      if (!mounted) return;
      _snack('تم حذف التذكير');
    } catch (e) {
      _snack('فشل الحذف: $e');
    }
  }

  void _snack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white10 : cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.notifications_active_rounded, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Tajawal',
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ct = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ct.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.alarm_add_rounded, size: 48, color: ct.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد تذكيرات بعد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFamily: 'Tajawal',
                color: ct.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإضافة تذكير خاص بك من الزر أدناه',
              style: TextStyle(
                color: ct.onSurfaceVariant,
                fontFamily: 'Tajawal',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
