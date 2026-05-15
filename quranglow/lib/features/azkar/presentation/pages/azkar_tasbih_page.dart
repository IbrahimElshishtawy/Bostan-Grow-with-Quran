import 'package:flutter/material.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:quranglow/features/azkar/presentation/pages/zikr_reader_page.dart';
import 'package:quranglow/features/azkar/presentation/widgets/reminder_list.dart';
import 'package:quranglow/features/azkar/presentation/widgets/tasbih_counter.dart';
import 'package:quranglow/features/ui/routes/app_routes.dart';

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
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const ProAppBar(
          title: 'الروحانيات والتذكير',
          subtitle: 'أذكار، تفسير، تسبيح، وتنبيهات مخصصة',
          showBack: false,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: TabBar(
                  controller: _tab,
                  labelColor: cs.onPrimary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  indicator: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(child: Text('الأذكار', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold))),
                    Tab(child: Text('التسبيح', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold))),
                    Tab(child: Text('التفسير', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold))),
                    Tab(child: Text('التنبيهات', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold))),
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
                  _buildTafsirTab(context),
                  const ReminderList(), // Uses existing ReminderList
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
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle('الورد اليومي', Icons.wb_sunny_rounded),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _buildCategoryCard(context, 'أذكار الصباح', Icons.wb_sunny_rounded, Colors.orange),
            _buildCategoryCard(context, 'أذكار المساء', Icons.nights_stay_rounded, Colors.indigo),
            _buildCategoryCard(context, 'أذكار النوم', Icons.bedtime_rounded, Colors.purple),
            _buildCategoryCard(context, 'أذكار الاستيقاظ', Icons.wb_twilight_rounded, Colors.amber),
            _buildCategoryCard(context, 'أذكار بعد الصلاة', Icons.mosque_rounded, Colors.teal),
            _buildCategoryCard(context, 'تسابيح منوعة', Icons.bubble_chart_rounded, Colors.blueGrey),
          ],
        ),
      ],
    );
  }

  Widget _buildTasbihTab(BuildContext context) {
    return const TasbihCounter();
  }

  Widget _buildTafsirTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Tafsir Banner
        InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.tafsir),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.blue.shade900],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مستكشف التفسير',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'تصفح معاني وتفسير الآيات بعمق وسهولة',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
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
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
