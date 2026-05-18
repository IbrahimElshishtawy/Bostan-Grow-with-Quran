import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' as intl;
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/ui/routes/app_routes.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, this.onNavigate});

  final void Function(String route)? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;
    final isDark = b == Brightness.dark;
    final settingsAsync = ref.watch(settingsProvider);
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

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.88,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: isDark ? 0.82 : 0.94),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 🌳 Drawer Header with Background Image & Info Card
                    _DrawerHeader(isDark: isDark),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        children: [
                          // 🎨 Theme Toggle (Now at the top)
                          _ThemeToggle(settingsAsync: settingsAsync),

                          const SizedBox(height: 20),

                          // 🎙️ Reciter Selection (Professional Vertical List)
                          _ReciterSection(settingsAsync: settingsAsync),

                          const SizedBox(height: 24),

                          _DrawerTile(
                            icon: Icons.settings_suggest_rounded,
                            title: 'الإعدادات',
                            subtitle: 'تخصيص تجربة القراءة والتنبيهات',
                            selected: currentRoute == AppRoutes.setting,
                            onTap: () => go(AppRoutes.setting),
                          ),
                          _DrawerTile(
                            icon: Icons.info_outline_rounded,
                            title: 'عن التطبيق',
                            subtitle: 'معلومات الإصدار والمطور',
                            selected: currentRoute == AppRoutes.about,
                            onTap: () => go(AppRoutes.about),
                          ),
                        ],
                      ),
                    ),

                    // 🏁 Footer
                    _DrawerFooter(cs: cs),
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

class _DrawerHeader extends StatelessWidget {
  final bool isDark;
  const _DrawerHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        image: const DecorationImage(
          image: AssetImage('assets/images/bustan_splash.png'),
          fit: BoxFit.cover,
          opacity: 0.25, // Subtle background
        ),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.surface.withOpacity(0.4), cs.surface.withOpacity(0.9)],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: cs.primary.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/bustan_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'بُستان',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                              fontFamily: 'ScheherazadeNew',
                            ),
                          ),
                          const _TextDownloadButton(),
                        ],
                      ),
                      Text(
                        'تلاوة • تدبر • تقدّم',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withOpacity(0.8),
                          fontSize: 12,
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
            // 🕒 Professional Clock & Hijri Card
            const _TemporalCard(),
          ],
        ),
      ),
    );
  }
}

class _TextDownloadButton extends ConsumerStatefulWidget {
  const _TextDownloadButton();

  @override
  ConsumerState<_TextDownloadButton> createState() => _TextDownloadButtonState();
}

class _TextDownloadButtonState extends ConsumerState<_TextDownloadButton> {
  double? _progress;
  bool _isDownloaded = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final downloaded = await ref.read(quranServiceProvider).isQuranTextDownloaded();
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
        _checking = false;
      });
    }
  }

  Future<void> _startDownload() async {
    final isOnlineAsync = ref.read(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? true;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يوجد اتصال بالإنترنت لتحميل نصوص القرآن',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _progress = 0.0;
    });

    ref.read(quranServiceProvider).downloadQuranText().listen(
      (p) {
        if (mounted) {
          setState(() {
            _progress = p;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _progress = null;
            _isDownloaded = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم تحميل نصوص القرآن بالكامل بنجاح للقراءة دون إنترنت!',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              backgroundColor: Colors.teal,
            ),
          );
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _progress = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'فشل تحميل نصوص القرآن: $e',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    if (_checking) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_progress != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${(_progress! * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.primary,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      );
    }

    if (_isDownloaded) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: Icon(
        Icons.cloud_download_rounded,
        color: cs.onSurfaceVariant.withOpacity(0.7),
      ),
      tooltip: 'تحميل نصوص القرآن للقراءة دون إنترنت',
      onPressed: _startDownload,
    );
  }
}

class _TemporalCard extends StatefulWidget {
  const _TemporalCard();

  @override
  State<_TemporalCard> createState() => _TemporalCardState();
}

class _TemporalCardState extends State<_TemporalCard> {
  Timer? _timer;
  String _time = '';
  String _gregorian = '';
  String _hijri = '';

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _update();
    });
  }

  void _update() {
    final now = DateTime.now();
    HijriCalendar.setLocal('ar');
    final h = HijriCalendar.now();
    setState(() {
      _time = intl.DateFormat('hh:mm:ss a', 'ar').format(now);
      _gregorian = intl.DateFormat('d MMMM yyyy', 'ar').format(now);
      _hijri = '${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time_filled_rounded,
                size: 16,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _time,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: cs.outlineVariant.withOpacity(0.3)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('التاريخ الميلادي', style: _labelStyle(cs)),
                    const SizedBox(height: 4),
                    Text(_gregorian, style: _valueStyle(cs)),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: cs.outlineVariant.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'التاريخ الهجري',
                      style: _labelStyle(cs).copyWith(color: cs.tertiary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hijri,
                      style: _valueStyle(cs).copyWith(color: cs.tertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle(ColorScheme cs) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    fontFamily: 'Tajawal',
    color: cs.onSurfaceVariant.withOpacity(0.6),
  );

  TextStyle _valueStyle(ColorScheme cs) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    fontFamily: 'Tajawal',
    color: cs.onSurface,
  );
}

class _ReciterSection extends ConsumerStatefulWidget {
  final AsyncValue<dynamic> settingsAsync;
  const _ReciterSection({required this.settingsAsync});

  @override
  ConsumerState<_ReciterSection> createState() => _ReciterSectionState();
}

class _ReciterSectionState extends ConsumerState<_ReciterSection> {
  bool _isExpanded = false;

  static const _allReciters = [
    (id: 'ar.alafasy', name: 'مشاري العفاسي', desc: 'كويت - مرتلاً'),
    (
      id: 'ar.abdurrahmaansudais',
      name: 'عبد الرحمن السديس',
      desc: 'الحرم المكي',
    ),
    (id: 'ar.minshawi', name: 'محمد صديق المنشاوي', desc: 'مصر - مرتلاً'),
    (
      id: 'ar.abdulbasitmurattal',
      name: 'عبد الباسط عبد الصمد',
      desc: 'مصر - مرتلاً',
    ),
    (id: 'ar.mahermuaiqly', name: 'ماهر المعيقلي', desc: 'الحرم المكي'),
    (id: 'ar.husary', name: 'محمود خليل الحصري', desc: 'مصر - مرتلاً'),
    (id: 'ar.ghamadi', name: 'سعد الغامدي', desc: 'السعودية - مرتلاً'),
    (id: 'ar.hudhaify', name: 'علي الحذيفي', desc: 'الحرم المدني'),
    (id: 'ar.saoodshuraym', name: 'سعود الشريم', desc: 'الحرم المكي'),
    (id: 'ar.aymanswayd', name: 'أيمن سويد', desc: 'سوريا - معلم'),
    (id: 'ar.hanirifai', name: 'هاني الرفاعي', desc: 'السعودية - مرتلاً'),
    (id: 'ar.abdulsamad', name: 'عبد الباسط (مجود)', desc: 'مصر - مجوداً'),
    (
      id: 'ar.khaleel_al_hussary_mujawwad',
      name: 'الحصري (مجود)',
      desc: 'مصر - مجوداً',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return widget.settingsAsync.when(
      data: (settings) {
        final currentReader = settings.readerEditionId;
        final selectedReciter = _allReciters.firstWhere(
          (r) => r.id == currentReader,
          orElse: () => _allReciters.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _isExpanded ? cs.primary.withOpacity(0.08) : cs.surfaceContainerHighest.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isExpanded ? cs.primary.withOpacity(0.3) : cs.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mic_none_rounded, 
                      size: 20, 
                      color: _isExpanded ? cs.primary : cs.onSurfaceVariant
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'قارئك المفضل',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Tajawal',
                              color: _isExpanded ? cs.primary : cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'القارئ الحالي: ${selectedReciter.name}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Tajawal',
                              color: cs.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _isExpanded ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _allReciters.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final r = _allReciters[index];
                      final isSelected = currentReader == r.id;
                      return _ReciterTile(
                        name: r.name,
                        desc: r.desc,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(settingsProvider.notifier).setReader(r.id);
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 100),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ReciterTile extends StatelessWidget {
  final String name;
  final String desc;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReciterTile({
    required this.name,
    required this.desc,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white24
                    : cs.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name[0],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : cs.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Tajawal',
                      color: isSelected ? Colors.white : cs.onSurface,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Tajawal',
                      color: isSelected ? Colors.white70 : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  final AsyncValue<dynamic> settingsAsync;
  const _ThemeToggle({required this.settingsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return settingsAsync.when(
      data: (settings) {
        final mode = settings.themeMode;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _ToggleItem(
                title: 'فاتح',
                icon: Icons.light_mode_rounded,
                selected: mode == ThemeMode.light,
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
              _ToggleItem(
                title: 'داكن',
                icon: Icons.dark_mode_rounded,
                selected: mode == ThemeMode.dark,
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Tajawal',
                  color: selected ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: selected ? cs.primary.withOpacity(0.08) : null,
        border: Border.all(
          color: selected
              ? cs.primary.withOpacity(0.2)
              : cs.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        dense: true,
        minTileHeight: 58,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Icon(
          icon,
          size: 20,
          color: selected ? cs.primary : cs.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            fontFamily: 'Tajawal',
            color: selected ? cs.primary : cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          style: TextStyle(
            color: cs.onSurfaceVariant.withOpacity(0.6),
            fontSize: 10,
            fontFamily: 'Tajawal',
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  final ColorScheme cs;
  const _DrawerFooter({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        children: [
          Divider(color: cs.outlineVariant.withOpacity(0.2)),
          const SizedBox(height: 8),
          Text(
            'بُستان • الإصدار 1.0.0',
            style: TextStyle(
              color: cs.onSurfaceVariant.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
