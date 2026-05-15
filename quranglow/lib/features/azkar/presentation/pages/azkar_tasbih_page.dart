import 'package:flutter/material.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:quranglow/features/azkar/presentation/pages/zikr_reader_page.dart';
import 'package:quranglow/features/azkar/presentation/widgets/reminder_list.dart';
import 'package:quranglow/features/azkar/presentation/widgets/tasbih_counter.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/tafsir_integrated_view.dart';

class AzkarTasbihPage extends StatefulWidget {
  const AzkarTasbihPage({super.key});

  @override
  State<AzkarTasbihPage> createState() => _AzkarTasbihPageState();
}

class _AzkarTasbihPageState extends State<AzkarTasbihPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ZikrReaderPage(category: title),
            ),
          );
        },
        borderRadius: BorderRadius.circular(26),
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
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
