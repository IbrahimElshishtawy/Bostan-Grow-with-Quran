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
    this.onTafsir,
    this.onVoiceRecite,
  });

  final bool visible;
  final AsyncValue<Surah> asyncSurah;
  final int chapter;
  final VoidCallback onBack;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onSave;
  final VoidCallback? onTafsir;
  final VoidCallback? onVoiceRecite;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = cs.onSurface;
    final titleColor = fg.withOpacity(isDark ? 0.95 : 0.90);
    final iconEnabled = fg.withOpacity(isDark ? 0.95 : 0.90);
    final iconDisabled = fg.withOpacity(0.30);

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
                        ? [const Color(0xFF0D2818).withValues(alpha: 0.85), const Color(0xFF113D25).withValues(alpha: 0.75)]
                        : [const Color(0xFFFDFBF7).withValues(alpha: 0.9), const Color(0xFFF5F0E5).withValues(alpha: 0.85)],
                  ),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFD4AF37).withValues(alpha: 0.6),
                    width: 1.2,
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
                          color: isDark ? Colors.white : const Color(0xFFD4AF37),
                        ),
                      ),
                      Row(
                      children: [
                        const SizedBox(width: 4),
                        _roundButton(
                          icon: Icons.arrow_back,
                          onTap: onBack,
                          tooltip: 'عودة',
                          enabledColor: iconEnabled,
                          disabledColor: iconDisabled,
                          isDark: isDark,
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
                                          color: const Color(0xFFF1D486),
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'KFGQPC Uthmanic Script',
                                          fontSize: 24,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 1),
                                              blurRadius: 2,
                                              color: Colors.black.withValues(alpha: 0.2),
                                            )
                                          ]
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
                                          color: const Color(0xFFF1D486),
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'KFGQPC Uthmanic Script',
                                          fontSize: 24,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 1),
                                              blurRadius: 2,
                                              color: Colors.black.withValues(alpha: 0.2),
                                            )
                                          ]
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
                        
                        // 🔮 THE NEW PREMIUM MENU!
                        PopupMenuButton<int>(
                          icon: Icon(Icons.more_vert, color: titleColor),
                          tooltip: 'المزيد من الخيارات',
                          color: isDark ? const Color(0xFF113D25).withOpacity(0.98) : Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 1,
                              enabled: onVoiceRecite != null,
                              child: const ListTile(
                                leading: Icon(Icons.mic_none, color: Colors.blueAccent),
                                title: Text('تسميع الصفحة صوتياً', style: TextStyle(fontSize: 14)),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            PopupMenuItem(
                              value: 2,
                              enabled: onSave != null,
                              child: const ListTile(
                                leading: Icon(Icons.bookmark_add_outlined, color: Colors.green),
                                title: Text('حفظ موضع القراءة', style: TextStyle(fontSize: 14)),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            PopupMenuItem(
                              value: 3,
                              enabled: onTafsir != null,
                              child: const ListTile(
                                leading: Icon(Icons.menu_book_outlined, color: Colors.brown),
                                title: Text('تفسير الآيات', style: TextStyle(fontSize: 14)),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 4,
                              enabled: onNext != null,
                              child: const ListTile(
                                leading: Icon(Icons.skip_next, color: Colors.amber),
                                title: Text('الصفحة / السورة التالية', style: TextStyle(fontSize: 14)),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            PopupMenuItem(
                              value: 5,
                              enabled: onPrev != null,
                              child: const ListTile(
                                leading: Icon(Icons.skip_previous, color: Colors.amber),
                                title: Text('الصفحة / السورة السابقة', style: TextStyle(fontSize: 14)),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 1: onVoiceRecite?.call(); break;
                              case 2: onSave?.call(); break;
                              case 3: onTafsir?.call(); break;
                              case 4: onNext?.call(); break;
                              case 5: onPrev?.call(); break;
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

  Widget _roundButton({
    required IconData icon,
    String? tooltip,
    required VoidCallback? onTap,
    required Color enabledColor,
    required Color disabledColor,
    required bool isDark,
  }) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon),
        color: enabled ? enabledColor : disabledColor,
        splashRadius: 22,
        style: IconButton.styleFrom(
          backgroundColor: (enabled
              ? enabledColor.withOpacity(isDark ? .12 : .10)
              : disabledColor.withOpacity(isDark ? .06 : .04)),
          shape: const CircleBorder(),
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
          decoration: const BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
