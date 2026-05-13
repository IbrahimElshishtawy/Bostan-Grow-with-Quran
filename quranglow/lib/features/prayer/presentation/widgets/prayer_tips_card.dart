import 'package:flutter/material.dart';

class PrayerTipsCard extends StatelessWidget {
  const PrayerTipsCard({super.key});

  static const List<Map<String, dynamic>> _tips = [
    {
      'title': 'الخشوع والطمأنينة',
      'desc': 'استشعر وقوفك بين يدي الله سبحانه، فكلما زادت الطمأنينة زاد الأجر وحلاوة الصلاة في قلبك.',
      'icon': Icons.spa_rounded,
      'color': Color(0xFF2E7D32),
    },
    {
      'title': 'التزين للمسجد',
      'desc': 'احرص على اللباس النظيف والطيب والسواك عملاً بقوله تعالى: "يَا بَنِي آدَمَ خُذُوا زِينَتَكُمْ عِندَ كُلِّ مَسْجِدٍ".',
      'icon': Icons.checkroom_rounded,
      'color': Color(0xFF00796B),
    },
    {
      'title': 'إسباغ الوضوء',
      'desc': 'أعطِ كل عضو حقه الكامل من الماء مع استحضار النية واستشعار مغفرة الذنوب مع كل قطرة ماء.',
      'icon': Icons.opacity_rounded,
      'color': Color(0xFF0288D1),
    },
    {
      'title': 'التبكير للصلاة',
      'desc': 'السعي للصف الأول والانتظار قبل الأذان، يكتب لك أجر صلاة ويُبقي قلبك معلقاً بالمساجد.',
      'icon': Icons.directions_walk_rounded,
      'color': Color(0xFFE65100),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lightbulb_outline_rounded, size: 16, color: cs.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'مستلزمات ونصائح الصلاة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Tajawal',
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 125,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _tips.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _tips[index];
              final Color primaryClr = item['color'] as Color;

              return Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.surface,
                      cs.surfaceContainerLowest,
                    ],
                  ),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left visual icon marker
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryClr.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: primaryClr,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Content text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: cs.onSurface,
                              fontFamily: 'Tajawal',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              item['desc'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                                fontFamily: 'Tajawal',
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
