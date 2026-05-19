// lib/features/mushaf/presentation/widgets/mushaf_top_bar.dart
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
    this.onHide,
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
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Rich Colors
    final Color barBorderColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.35)
        : const Color(0xFFC5A85C).withOpacity(0.55);

    final Color titleColor = isDark
        ? const Color(0xFFF1D486)
        : const Color(0xFF0F4C3A);

    final Color iconColor = isDark
        ? const Color(0xFFECE5D8)
        : const Color(0xFF333333);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, -0.2),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: visible ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                        spreadRadius: -2,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF0F261C).withOpacity(0.92), // rich dark emerald
                              const Color(0xFF091610).withOpacity(0.96), // deep jade black
                            ]
                          : [
                              const Color(0xFFFCFAF2).withOpacity(0.94), // rich ivory/cream
                              const Color(0xFFF3EDDF).withOpacity(0.98), // soft warm sand
                            ],
                    ),
                    border: Border.all(
                      color: barBorderColor,
                      width: 1.2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 🕌 Authentic Subtle Islamic Pattern Overlay
                          Opacity(
                            opacity: isDark ? 0.04 : 0.08,
                            child: Image.asset(
                              'assets/images/islamic_pattern.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              color: isDark ? Colors.white : const Color(0xFF8B6D3A),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                // Back Button with micro-background
                                _buildBarButton(
                                  icon: Icons.arrow_back_rounded,
                                  onPressed: onBack,
                                  tooltip: 'رجوع',
                                  color: iconColor,
                                ),
                                const SizedBox(width: 4),
                                
                                // Hide controls button
                                _buildBarButton(
                                  icon: Icons.visibility_off_outlined,
                                  onPressed: onHide,
                                  tooltip: 'إخفاء الأزرار للقراءة الكاملة',
                                  color: iconColor,
                                ),
                                
                                // Title Section (Fills Middle Space)
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
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                s.name,
                                                key: ValueKey('title-${s.name}'),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  color: titleColor,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: 'KFGQPC Uthmanic Script',
                                                  fontSize: 22,
                                                  shadows: [
                                                    Shadow(
                                                      offset: const Offset(0, 1),
                                                      blurRadius: 3,
                                                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          _buildAuthenticStar(isDark),
                                        ],
                                      ),
                                      orElse: () => Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildAuthenticStar(isDark),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                'سورة $chapter',
                                                key: ValueKey('title-$chapter'),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  color: titleColor,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: 'KFGQPC Uthmanic Script',
                                                  fontSize: 22,
                                                  shadows: [
                                                    Shadow(
                                                      offset: const Offset(0, 1),
                                                      blurRadius: 3,
                                                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          _buildAuthenticStar(isDark),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // More options menu
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                  ),
                                  child: PopupMenuButton<int>(
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.more_vert_rounded,
                                        color: iconColor,
                                        size: 22,
                                      ),
                                    ),
                                    tooltip: 'المزيد من الخيارات',
                                    color: isDark
                                        ? const Color(0xFF0F261C).withOpacity(0.98)
                                        : Colors.white,
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: barBorderColor.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    itemBuilder: (context) => [
                                      PopupMenuItem<int>(
                                        enabled: false,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'حجم الخط',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline_rounded,
                                                    color: Colors.amber,
                                                    size: 24,
                                                  ),
                                                  onPressed: onZoomOut,
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.add_circle_outline_rounded,
                                                    color: Colors.green,
                                                    size: 24,
                                                  ),
                                                  onPressed: onZoomIn,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
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
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildBarButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    required Color color,
    double size = 22,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              color: onPressed != null ? color : color.withOpacity(0.3),
              size: size,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticStar(bool isDark) {
    final color = isDark ? const Color(0xFFF1D486) : const Color(0xFFC5A85C);
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _IslamicStarPainter(color: color),
      ),
    );
  }
}

class _IslamicStarPainter extends CustomPainter {
  const _IslamicStarPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w / 2 - 2;

    // Draw first square
    final path1 = Path()
      ..moveTo(cx - r, cy - r)
      ..lineTo(cx + r, cy - r)
      ..lineTo(cx + r, cy + r)
      ..lineTo(cx - r, cy + r)
      ..close();

    // Draw second square rotated 45 degrees
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(3.1415926535 / 4);
    final path2 = Path()
      ..moveTo(-r, -r)
      ..lineTo(r, -r)
      ..lineTo(r, r)
      ..lineTo(-r, r)
      ..close();
    
    canvas.drawPath(path2, paint);
    canvas.restore();

    canvas.drawPath(path1, paint);

    // Draw central dot
    canvas.drawCircle(Offset(cx, cy), 2.2, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
