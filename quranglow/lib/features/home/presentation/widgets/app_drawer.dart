import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quranglow/features/downloads/presentation/pages/downloads_library_page.dart';
import 'package:quranglow/features/ui/routes/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.onNavigate});

  final void Function(String route)? onNavigate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    void go(String route) {
      if (currentRoute == route) {
        Scaffold.maybeOf(context)?.closeDrawer();
        return;
      }
      Scaffold.maybeOf(context)?.closeDrawer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (onNavigate != null) {
          onNavigate!(route);
        } else if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.of(context).pushNamed(route);
        }
      });
    }

    Widget tile({
      required IconData icon,
      required String title,
      required String subtitle,
      String? route,
      VoidCallback? onTap,
    }) {
      final selected = route != null && currentRoute == route;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    cs.primary.withValues(alpha: 0.20),
                    cs.primary.withValues(alpha: 0.09),
                  ],
                )
              : null,
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: ListTile(
          dense: true,
          minTileHeight: 62,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withValues(alpha: 0.18)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: selected ? cs.primary : cs.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            Icons.chevron_left_rounded,
            size: 18,
            color: selected ? cs.primary : cs.outline,
          ),
          onTap: onTap ?? () => go(route!),
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.65),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            cs.primary.withValues(alpha: 0.20),
                            cs.tertiary.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  cs.primary.withValues(alpha: 0.95),
                                  cs.primary.withValues(alpha: 0.72),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              color: cs.onPrimary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'QuranGlow',
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 19,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'وصول أسرع للمصحف والتفسير والأهداف والتنزيلات',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        children: [
                          tile(
                            icon: Icons.menu_book_rounded,
                            title: 'المصحف',
                            subtitle: 'قراءة مباشرة واستكمال آخر موضع',
                            route: AppRoutes.mushaf,
                          ),
                          tile(
                            icon: Icons.list_alt_rounded,
                            title: 'السور',
                            subtitle: 'تصفح السور والتنقل السريع',
                            route: AppRoutes.surahs,
                          ),
                          tile(
                            icon: Icons.bookmarks_rounded,
                            title: 'المحفوظات',
                            subtitle: 'الرجوع السريع إلى ما حفظته',
                            route: AppRoutes.bookmarks,
                          ),
                          tile(
                            icon: Icons.spa_rounded,
                            title: 'الأذكار',
                            subtitle: 'حصن المسلم والورد اليومي',
                            route: AppRoutes.azkar,
                          ),
                          tile(
                            icon: Icons.menu_book_outlined,
                            title: 'التفسير',
                            subtitle: 'فهم المعنى أثناء القراءة',
                            route: AppRoutes.tafsir,
                          ),
                          tile(
                            icon: Icons.flag_rounded,
                            title: 'الأهداف',
                            subtitle: 'متابعة أهدافك وتقدمك اليومي',
                            route: AppRoutes.goals,
                          ),
                          tile(
                            icon: Icons.insights_rounded,
                            title: 'الإحصاءات',
                            subtitle: 'نظرة سريعة على نشاطك',
                            route: AppRoutes.stats,
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Text(
                              'أدوات إضافية',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          tile(
                            icon: Icons.settings_rounded,
                            title: 'الإعدادات',
                            subtitle: 'الإشعارات والأهداف وتخصيص التجربة',
                            route: AppRoutes.setting,
                          ),
                          tile(
                            icon: Icons.info_outline_rounded,
                            title: 'عن التطبيق',
                            subtitle: 'معلومات التطبيق والمطور ووسائل التواصل',
                            route: AppRoutes.about,
                          ),
                          tile(
                            icon: Icons.library_music_rounded,
                            title: 'مكتبة التنزيلات',
                            subtitle: 'الملفات الصوتية التي تم حفظها',
                            onTap: () {
                              Scaffold.maybeOf(context)?.closeDrawer();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DownloadsLibraryPage(),
                                  ),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shield_moon_outlined,
                              size: 18,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'الإصدار 1.0.0',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'واجهة محسنة',
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
