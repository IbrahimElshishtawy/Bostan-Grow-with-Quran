import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:quranglow/features/azkar/domain/azkar_model.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';
import 'package:quranglow/core/model/reminder/reminder.dart';

class ZikrReaderPage extends ConsumerStatefulWidget {
  final String category;
  const ZikrReaderPage({super.key, required this.category});

  @override
  ConsumerState<ZikrReaderPage> createState() => _ZikrReaderPageState();
}

class _ZikrReaderPageState extends ConsumerState<ZikrReaderPage> {
  late List<Zikr> _items;
  final Map<int, int> _counts = {};

  bool _isScheduled = false;
  late TimeOfDay _reminderTime;

  @override
  void initState() {
    super.initState();
    _items = AzkarData.getByCategory(widget.category);
    for (int i = 0; i < _items.length; i++) {
      _counts[i] = int.tryParse(_items[i].count ?? '1') ?? 1;
    }

    // Default time from meta
    final meta = AzkarData.categoryMeta[widget.category];
    _reminderTime = meta != null 
      ? TimeOfDay(hour: meta.hour, minute: meta.minute) 
      : const TimeOfDay(hour: 5, minute: 0);

    _checkScheduledStatus();
  }

  Future<void> _checkScheduledStatus() async {
    final meta = AzkarData.categoryMeta[widget.category];
    if (meta == null) return;

    final reminders = await ref.read(remindersServiceProvider).fetchReminders();
    final reminder = reminders.where((r) => r.id == meta.id && r.scheduled).firstOrNull;
    
    if (mounted && reminder != null) {
      setState(() {
        _isScheduled = true;
        _reminderTime = TimeOfDay.fromDateTime(reminder.dateTime);
      });
    }
  }

  Future<void> _toggleNotification() async {
    final meta = AzkarData.categoryMeta[widget.category];
    if (meta == null) return;

    if (_isScheduled) {
      final action = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إعدادات التنبيه', textAlign: TextAlign.right),
          content: Text('أنت مشترك حالياً في تنبيه ${widget.category} عند الساعة ${_reminderTime.format(context)}. هل تود الإلغاء أم تغيير الوقت؟', textAlign: TextAlign.right),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, 'cancel'), child: const Text('إلغاء التنبيه', style: TextStyle(color: Colors.red))),
            TextButton(onPressed: () => Navigator.pop(c, 'change'), child: const Text('تغيير الوقت')),
            TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('إغلاق', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );

      if (action == 'cancel') {
        await NotificationService.instance.cancel(meta.id);
        await ref.read(remindersServiceProvider).deleteReminder(meta.id);
        setState(() => _isScheduled = false);
        _snack('تم إلغاء التنبيه');
        return;
      } else if (action != 'change') {
        return;
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: Theme.of(context).primaryColor)),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    );

    if (picked != null) {
      final now = DateTime.now();
      var scheduleTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      if (scheduleTime.isBefore(now)) scheduleTime = scheduleTime.add(const Duration(days: 1));

      await NotificationService.instance.scheduleReminder(
        id: meta.id,
        title: widget.category,
        body: 'حان وقت قراءة ${widget.category}، طمئن قلبك بذكر الله.',
        when: scheduleTime,
        daily: true,
      );

      await ref.read(remindersServiceProvider).saveReminder(Reminder(
        id: meta.id,
        title: widget.category,
        dateTime: scheduleTime,
        daily: true,
        scheduled: true,
      ));

      setState(() {
        _isScheduled = true;
        _reminderTime = picked;
      });
      _snack('تم ضبط التنبيه يومياً في ${picked.format(context)}');
    }
  }

  void _snack(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)), behavior: SnackBarBehavior.floating));
  }

  void _increment(int index) {
    if (_counts[index]! > 0) {
      setState(() {
        _counts[index] = _counts[index]! - 1;
      });
      HapticFeedback.lightImpact();
      if (_counts[index] == 0) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: ProAppBar(
          title: widget.category,
          onBack: () => Navigator.pop(context),
          actions: [
            IconButton(
              icon: Icon(
                _isScheduled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                color: _isScheduled ? Colors.amber : null,
              ),
              onPressed: _toggleNotification,
              tooltip: 'ضبط تذكير يومي',
            ),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = _items[index];
            final remaining = _counts[index]!;
            final total = int.tryParse(item.count ?? '1') ?? 1;
            final isDone = remaining == 0;

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isDone ? 0.6 : 1.0,
              child: Card(
                elevation: 0,
                color: isDone ? cs.surfaceContainer : cs.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isDone ? Colors.transparent : cs.primary.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: () => _increment(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.8,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Amiri',
                            color: isDone ? cs.onSurfaceVariant : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (item.reference != null)
                              Text(
                                item.reference!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.primary.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDone ? Colors.green.withValues(alpha: 0.1) : cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isDone ? 'تم القراءة' : '$remaining / $total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDone ? Colors.green : cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
