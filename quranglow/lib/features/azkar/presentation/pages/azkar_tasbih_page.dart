import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/reminder/reminder.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';
import 'package:quranglow/features/azkar/presentation/pages/zikr_reader_page.dart';
import 'package:quranglow/features/azkar/presentation/widgets/reminder_list.dart';
import 'package:quranglow/features/azkar/presentation/widgets/tasbih_counter.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/tafsir_integrated_view.dart';
import 'package:quranglow/features/azkar/domain/azkar_model.dart';

class AzkarTasbihPage extends ConsumerStatefulWidget {
  const AzkarTasbihPage({super.key});

  @override
  ConsumerState<AzkarTasbihPage> createState() => _AzkarTasbihPageState();
}

class _AzkarTasbihPageState extends ConsumerState<AzkarTasbihPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  
  // Use the centralized meta from AzkarData but allow local overrides in state if they change time
  late Map<String, ({TimeOfDay time, int id})> _azkarMeta;

  final List<int> _scheduledIds = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    
    // Initialize local meta from the central source
    _azkarMeta = AzkarData.categoryMeta.map((key, meta) => MapEntry(
      key, 
      (time: TimeOfDay(hour: meta.hour, minute: meta.minute), id: meta.id)
    ));

    _loadScheduledReminders();
  }

  Future<void> _loadScheduledReminders() async {
    final reminders = await ref.read(remindersServiceProvider).fetchReminders();
    if (mounted) {
      setState(() {
        _scheduledIds.clear();
        _scheduledIds.addAll(reminders.where((r) => r.scheduled).map((r) => r.id));
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const ProAppBar(
          title: 'الواحة الروحانية',
          subtitle: 'سكينة للقلب، طمأنينة للروح، ورفيق للذكر',
          showBack: false,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: TabBar(
                  controller: _tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(text: 'الأذكار'),
                    Tab(text: 'التسبيح'),
                    Tab(text: 'التفسير'),
                    Tab(text: 'التنبيهات'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildAzkarTab(context),
                  _buildTasbihTab(context),
                  const TafsirIntegratedView(), // Full Tafsir explorer directly in the tab
                  const ReminderList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAzkarTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle('الورد والذكر اليومي', Icons.auto_awesome_mosaic_rounded),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildCategoryCard(context, 'أذكار الصباح', Icons.wb_sunny_rounded, const Color(0xFFF97316)),
            _buildCategoryCard(context, 'أذكار المساء', Icons.nights_stay_rounded, const Color(0xFF6366F1)),
            _buildCategoryCard(context, 'أذكار النوم', Icons.bedtime_rounded, const Color(0xFFA855F7)),
            _buildCategoryCard(context, 'أذكار الاستيقاظ', Icons.wb_twilight_rounded, const Color(0xFFEAB308)),
            _buildCategoryCard(context, 'أذكار الصلاة', Icons.mosque_rounded, const Color(0xFF10B981)),
            _buildCategoryCard(context, 'تسابيح منوعة', Icons.star_rounded, const Color(0xFF64748B)),
          ],
        ),
      ],
    );
  }

  Widget _buildTasbihTab(BuildContext context) {
    return const TasbihCounter();
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = _azkarMeta[title];
    final isScheduled = meta != null && _scheduledIds.contains(meta.id);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isScheduled 
            ? color.withValues(alpha: 0.4) 
            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: isScheduled ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Stack(
        children: [
          if (meta != null)
            PositionScaler(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  isScheduled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                  size: 18,
                  color: isScheduled ? color : Colors.grey,
                ),
                onPressed: () => _toggleReminder(title, meta),
              ),
            ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ZikrReaderPage(category: title),
                ),
              );
            },
            borderRadius: BorderRadius.circular(26),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  if (meta != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta.time.format(context),
                      style: TextStyle(
                        fontSize: 11,
                        color: isScheduled ? color : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleReminder(String title, ({TimeOfDay time, int id}) meta) async {
    final isScheduled = _scheduledIds.contains(meta.id);
    
    if (isScheduled) {
      // Show choice: Cancel or Change Time
      final action = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('إعدادات تنبيه $title', textAlign: TextAlign.right),
          content: const Text('هل تود تغيير وقت التنبيه أم إلغاءه؟', textAlign: TextAlign.right),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, 'cancel'),
              child: const Text('إلغاء التنبيه', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, 'change'),
              child: const Text('تغيير الوقت'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, null),
              child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );

      if (action == 'cancel') {
        await NotificationService.instance.cancel(meta.id);
        await ref.read(remindersServiceProvider).deleteReminder(meta.id);
        setState(() => _scheduledIds.remove(meta.id));
        _snack('تم إلغاء تنبيه $title');
        return;
      } else if (action != 'change') {
        return;
      }
    }

    if (!mounted) return;

    // Pick Time (New or Change)
    final picked = await showTimePicker(
      context: context,
      initialTime: meta.time,
      helpText: 'اختر وقت التنبيه لـ $title',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      try {
        final now = DateTime.now();
        var scheduleTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        if (scheduleTime.isBefore(now)) {
          scheduleTime = scheduleTime.add(const Duration(days: 1));
        }

        await NotificationService.instance.scheduleReminder(
          id: meta.id,
          title: title,
          body: 'حان وقت قراءة $title، طمئن قلبك بذكر الله.',
          when: scheduleTime,
          daily: true,
        );

        final r = Reminder(
          id: meta.id,
          title: title,
          dateTime: scheduleTime,
          daily: true,
          scheduled: true,
          notes: 'تذكير يومي تلقائي',
        );
        await ref.read(remindersServiceProvider).saveReminder(r);
        
        // Update local meta for display if needed (though it's hardcoded in state map for now, 
        // we can update it in the UI or just rely on the snackbar feedback)
        setState(() {
          _scheduledIds.add(meta.id);
          // Update the meta map to show the new time in the card
          _azkarMeta[title] = (time: picked, id: meta.id);
        });
        
        if (!mounted) return;
        _snack('تم ضبط تنبيه $title يومياً في ${picked.format(context)}');
      } catch (e) {
        if (!mounted) return;
        _snack('حدث خطأ أثناء ضبط التنبيه: $e');
      }
    }
  }

  void _snack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class PositionScaler extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  const PositionScaler({super.key, required this.child, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: child,
    );
  }
}
