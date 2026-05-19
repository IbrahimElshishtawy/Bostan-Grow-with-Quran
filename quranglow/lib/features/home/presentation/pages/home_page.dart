import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/azkar/presentation/pages/azkar_tasbih_page.dart';
import 'package:quranglow/features/gamification/presentation/pages/modern_home_screen.dart';
import 'package:quranglow/features/home/presentation/widgets/app_drawer.dart';
import 'package:quranglow/features/player/presentation/pages/player_page.dart';
import 'package:quranglow/features/prayer/presentation/pages/prayer_qibla_screen.dart';
import 'package:quranglow/features/surah/presentation/pages/surah_list_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // التحقق من وجود تحديثات تلقائياً عند فتح التطبيق بعد انتهاء رندر الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUpdateServiceProvider).checkForUpdate(context);
    });
  }

  int _tab = 0;
  bool _isNavVisible = true;

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
      icon: Icons.spa_outlined,
      activeIcon: Icons.spa,
    ),
    _NavTab(
      label: 'المشغل',
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle,
    ),
    _NavTab(
      label: 'المصلى',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBody: true, // Crucial for layered stacking!
        drawer: AppDrawer(
          onNavigate: (route) {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
        ),
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            final ScrollDirection direction = notification.direction;
            if (direction == ScrollDirection.reverse) {
              if (_isNavVisible) {
                setState(() => _isNavVisible = false);
              }
            } else if (direction == ScrollDirection.forward) {
              if (!_isNavVisible) {
                setState(() => _isNavVisible = true);
              }
            }
            return false; // allow notification to continue bubbling
          },
          child: Stack(
            children: [
              // The Content
              Positioned.fill(
                child: _buildTabBody(),
              ),
              
              // The Animated Stacked Bottom Nav Bar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 450),
                curve: Curves.fastEaseInToSlowEaseOut,
                left: 0,
                right: 0,
                bottom: _isNavVisible ? 0 : -120, // slide completely off screen
                child: _GlassNavigationBar(
                  tabs: _tabs,
                  selectedIndex: _tab,
                  onSelect: (i) => setState(() => _tab = i),
                ),
              ),
            ],
          ),
        ),
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
        return const PrayerQiblaScreen();
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
                                : cs.onSurfaceVariant
                                    .withValues(alpha: 0.90),
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

