// lib/features/ui/pages/mushaf/widgets/mushaf_top_bar.dart
// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/model/book/surah.dart';

class MushafTopBar extends StatelessWidget {
  const MushafTopBar({
    super.key,
    required this.visible,
    required this.asyncSurah,
    required this.chapter,
    required this.onBack,
    this.onPrev,
    this.onNext,
    this.onSave,
    this.onZoomIn,
    this.onZoomOut,
    this.onTafsir,
    this.onVoiceRecite,
    this.onPlayAll,
    this.onDownload,
  });

  final bool visible;
  final AsyncValue<Surah> asyncSurah;
  final int chapter;
  final VoidCallback onBack;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onSave;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onTafsir;
  final VoidCallback? onVoiceRecite;
  final VoidCallback? onPlayAll;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = cs.onSurface;
    final titleColor = fg.withOpacity(isDark ? 0.95 : 0.90);
    final _ = fg.withOpacity(isDark ? 0.95 : 0.90);
    fg.withOpacity(0.30);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: visible ? 1 : 0,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF0D2818).withValues(alpha: 0.45),
                            const Color(0xFF061A10).withValues(alpha: 0.35),
                          ]
                        : [
                            const Color(0xFFFFFFFF).withValues(alpha: 0.25),
                            const Color(0xFFFDFCF0).withValues(alpha: 0.15),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                        : const Color(0xFFC5A028).withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 🏆 AUTHENTIC BACKGROUND PATTERN!
                        Opacity(
                          opacity: isDark ? 0.12 : 0.3,
                          child: Image.asset(
                            'assets/images/islamic_pattern.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFFD4AF37),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_rounded, color: titleColor),
                              onPressed: onBack,
                              tooltip: 'رجوع',
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline_rounded, color: titleColor, size: 22),
                              onPressed: onZoomIn,
                              tooltip: 'تكبير الخط',
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded, color: titleColor, size: 22),
                              onPressed: onZoomOut,
                              tooltip: 'تصغير الخط',
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: asyncSurah.maybeWhen(
                                  data: (s) => Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildAuthenticStar(isDark),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            s.name,
                                            key: ValueKey('title-${s.name}'),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFF1D486) : const Color(0xFF004D40),
                                              fontWeight: FontWeight.w900,
                                              fontFamily:
                                                  'KFGQPC Uthmanic Script',
                                              fontSize: 24,
                                              shadows: [
                                                Shadow(
                                                  offset: const Offset(0, 1),
                                                  blurRadius: 2,
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildAuthenticStar(isDark),
                                    ],
                                  ),
                                  orElse: () => Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildAuthenticStar(isDark),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'سورة $chapter',
                                            key: ValueKey('title-$chapter'),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFF1D486) : const Color(0xFF004D40),
                                              fontWeight: FontWeight.w900,
                                              fontFamily:
                                                  'KFGQPC Uthmanic Script',
                                              fontSize: 24,
                                              shadows: [
                                                Shadow(
                                                  offset: const Offset(0, 1),
                                                  blurRadius: 2,
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildAuthenticStar(isDark),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            PopupMenuButton<int>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: titleColor,
                              ),
                              tooltip: 'المزيد من الخيارات',
                              color: isDark
                                  ? const Color(0xFF113D25).withOpacity(0.98)
                                  : Colors.white,
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 7,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      'تشغيل السورة كاملة',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 6,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.cloud_download_outlined,
                                      color: Colors.amber,
                                    ),
                                    title: Text(
                                      'تحميل السورة للاستماع أوفلاين',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 1,
                                  enabled: onVoiceRecite != null,
                                  child: const ListTile(
                                    leading: Icon(
                                      Icons.mic_none,
                                      color: Colors.blueAccent,
                                    ),
                                    title: Text(
                                      'تسميع الصفحة صوتياً',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 2,
                                  enabled: onSave != null,
                                  child: const ListTile(
                                    leading: Icon(
                                      Icons.bookmark_add_outlined,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      'حفظ موضع القراءة',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 3,
                                  enabled: onTafsir != null,
                                  child: const ListTile(
                                    leading: Icon(
                                      Icons.menu_book_outlined,
                                      color: Colors.brown,
                                    ),
                                    title: Text(
                                      'تفسير الآيات',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 4,
                                  enabled: onNext != null,
                                  child: const ListTile(
                                    leading: Icon(
                                      Icons.skip_next,
                                      color: Colors.amber,
                                    ),
                                    title: Text(
                                      'الصفحة / السورة التالية',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 5,
                                  enabled: onPrev != null,
                                  child: const ListTile(
                                    leading: Icon(
                                      Icons.skip_previous,
                                      color: Colors.amber,
                                    ),
                                    title: Text(
                                      'الصفحة / السورة السابقة',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 1:
                                    onVoiceRecite?.call();
                                    break;
                                  case 2:
                                    onSave?.call();
                                    break;
                                  case 3:
                                    onTafsir?.call();
                                    break;
                                  case 4:
                                    onNext?.call();
                                    break;
                                  case 5:
                                    onPrev?.call();
                                    break;
                                  case 7:
                                    onPlayAll?.call();
                                    break;
                                  case 6:
                                    onDownload?.call();
                                    break;
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticStar(bool isDark) {
    const color = Color(0xFFF1D486);
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.star_border, color: color, size: 20),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}
