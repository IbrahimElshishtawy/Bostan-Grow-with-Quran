import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quranglow/features/azkar/presentation/pages/azkar_tasbih_page.dart';
import 'package:quranglow/features/gamification/presentation/pages/gamification_home_page.dart';
import 'package:quranglow/features/gamification/presentation/pages/modern_home_screen.dart';
import 'package:quranglow/features/home/presentation/widgets/app_drawer.dart';
import 'package:quranglow/features/player/presentation/pages/player_page.dart';
import 'package:quranglow/features/search/presentation/pages/search_page.dart';
import 'package:quranglow/features/surah/presentation/pages/surah_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  static const _tabs = <_NavTab>[
    _NavTab(
      label: 'التعلم',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
    ),
    _NavTab(
      label: 'المصحف',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
    ),
    _NavTab(
      label: 'الأذكار',
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
    ),
    _NavTab(
      label: 'المشغل',
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle,
    ),
    _NavTab(
      label: 'بحث',
      icon: Icons.search_rounded,
      activeIcon: Icons.manage_search_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: AppDrawer(
          onNavigate: (route) {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
        ),
        bottomNavigationBar: _GlassNavigationBar(
          tabs: _tabs,
          selectedIndex: _tab,
          onSelect: (i) => setState(() => _tab = i),
        ),
        body: _buildTabBody(),
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_tab) {
      case 0:
        return const ModernHomeScreen();
      case 1:
        return const SurahListPage();
      case 2:
        return const AzkarTasbihPage();
      case 3:
        return const PlayerPage();
      case 4:
        return const SearchPage();
      default:
        return const ModernHomeScreen();
    }
  }
}

class _NavTab {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _GlassNavigationBar extends StatelessWidget {
  const _GlassNavigationBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_NavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: cs.surface.withValues(alpha: 0.70),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.60),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final active = i == selectedIndex;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: active
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  cs.primary.withValues(alpha: 0.26),
                                  cs.primary.withValues(alpha: 0.12),
                                ],
                              )
                            : null,
                        border: active
                            ? Border.all(
                                color: cs.primary.withValues(alpha: 0.45),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            active ? tab.activeIcon : tab.icon,
                            size: active ? 24 : 22,
                            color: active
                                ? cs.primary
                                : cs.onSurfaceVariant.withValues(alpha: 0.90),
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: active ? 11 : 10,
                              height: 1,
                              fontWeight: active
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: active
                                  ? cs.primary
                                  : cs.onSurfaceVariant.withValues(alpha: 0.85),
                            ),
                            child: Text(
                              tab.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

