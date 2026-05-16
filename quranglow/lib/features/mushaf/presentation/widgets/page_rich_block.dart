import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/aya/aya.dart';
import 'package:quranglow/core/model/book/topic.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/span_builder.dart';

class PageRange {
  final int start;
  final int end;

  const PageRange({required this.start, required this.end});

  bool contains(int idx) => idx >= start && idx < end;
}

class PageRichBlock extends ConsumerStatefulWidget {
  const PageRichBlock({
    super.key,
    required this.ayat,
    required this.range,
    required this.showBasmala,
    required this.basmalaText,
    required this.currentAyahIndex,
    required this.onTapIndex,
    required this.onLongPressIndex,
    this.onBackgroundTap,
    this.ayahNumberColor,
    this.surahName,
    this.isHifzMode = false,
    this.revealedWords = const {},
    this.mistakenWords = const {},
    this.fontSize = 24.0,
  });

  final List<Aya> ayat;
  final PageRange range;
  final bool showBasmala;
  final String basmalaText;
  final int? currentAyahIndex;
  final void Function(int index) onTapIndex;
  final void Function(int index) onLongPressIndex;
  final VoidCallback? onBackgroundTap;
  final Color? ayahNumberColor;
  final String? surahName;
  final bool isHifzMode;
  final Map<int, Set<int>> revealedWords;
  final Map<int, Set<int>> mistakenWords;
  final double fontSize;

  @override
  ConsumerState<PageRichBlock> createState() => _PageRichBlockState();
}

class _PageRichBlockState extends ConsumerState<PageRichBlock> {
  final List<GestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.range.start < 0 ||
        widget.range.end > widget.ayat.length ||
        widget.range.start >= widget.range.end) {
      return const SizedBox.shrink();
    }

    final subAyat = widget.ayat.sublist(widget.range.start, widget.range.end);
    if (subAyat.isEmpty) {
      return const SizedBox.shrink();
    }

    final fontScale = ref.watch(
      settingsProvider.select(
        (value) => value.maybeWhen(data: (s) => s.fontScale, orElse: () => 1.0),
      ),
    );

    final localCurrentIndex = widget.currentAyahIndex == null
        ? null
        : _mapToLocal(
            widget.currentAyahIndex!,
            widget.range.start,
            widget.range.end,
          );

    _disposeRecognizers();

    final builder = AyahSpanBuilder(
      fontScale: fontScale,
      onAyahTap: (localIndex) =>
          widget.onTapIndex(widget.range.start + localIndex),
      onAyahLongPress: (localIndex) =>
          widget.onLongPressIndex(widget.range.start + localIndex),
    );

    final spans = builder.buildSpans(
      ayat: subAyat,
      currentAyahIndex: localCurrentIndex,
      ayahNumberColor: widget.ayahNumberColor,
      recognizersBucket: _recognizers,
      isHifzMode: widget.isHifzMode,
      revealedWords: widget.revealedWords,
      mistakenWords: widget.mistakenWords,
    );

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? cs.onSurface : const Color(0xFF2E2212);

    final currentTopics = mockTopics
        .where(
          (t) =>
              t.surah == subAyat.first.surah &&
              subAyat.any(
                (a) =>
                    a.numberInSurah >= t.startAyah &&
                    a.numberInSurah <= t.endAyah,
              ),
        )
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, c) {
        return ScrollConfiguration(
          behavior: const _NoGlowBehavior(),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onBackgroundTap,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.surahName != null) ...[
                      Builder(
                        builder: (context) {
                          // Strip duplicate "سورة" prefix if the API name already contains it
                          String cleanName = widget.surahName!.trim();
                          if (RegExp(r'^سورة\s+سو').hasMatch(cleanName)) {
                            cleanName = cleanName.replaceFirst(
                              RegExp(r'^سورة\s+'),
                              '',
                            );
                          }
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return _SurahTitleBanner(
                            name: cleanName,
                            fontScale: fontScale,
                            isDark: isDark,
                            frameColor: widget.ayahNumberColor,
                          );
                        },
                      ),
                    ],
                    if (widget.showBasmala) ...[
                      Text(
                        widget.basmalaText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'KFGQPC Uthmanic Script',
                          fontFamilyFallback: const [
                            'Hafs',
                            'Noto Naskh Arabic',
                            'Scheherazade',
                          ],
                          height: 2.0,
                          fontSize: (widget.fontSize + 3) * fontScale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    RichText(
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      strutStyle: StrutStyle(
                        fontSize: widget.fontSize * fontScale,
                        height: 2.25,
                      ),
                      text: TextSpan(
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'KFGQPC Uthmanic Script',
                          fontFamilyFallback: const [
                            'Hafs',
                            'Noto Naskh Arabic',
                            'Scheherazade',
                          ],
                          height: 2.25,
                          fontSize: widget.fontSize * fontScale,
                          letterSpacing: 0.2,
                        ),
                        children: spans,
                      ),
                    ),
                    if (currentTopics.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: currentTopics
                            .map(
                              (topic) => Chip(
                                label: Text(
                                  topic.title,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: cs.secondaryContainer
                                    .withValues(alpha: 0.6),
                                labelStyle: TextStyle(
                                  color: cs.onSecondaryContainer,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int? _mapToLocal(int global, int start, int end) {
    if (global < start || global >= end) return null;
    return global - start;
  }
}

// ═══════════════════════════════════════════════════════════════
// 📖 AUTHENTIC MUSHAF-STYLE SURAH TITLE BANNER
// Faithfully reproduces the classic printed Quran surah header:
//   • Ornamental outer double-line frame
//   • Pointed side protrusions (like a traditional scroll/certificate)
//   • Corner diamond rosette ornaments
//   • Surah name in calligraphic gold script
// ═══════════════════════════════════════════════════════════════
class _SurahTitleBanner extends StatelessWidget {
  const _SurahTitleBanner({
    required this.name,
    required this.fontScale,
    required this.isDark,
    this.frameColor,
  });

  final String name;
  final double fontScale;
  final bool isDark;
  final Color? frameColor;

  @override
  Widget build(BuildContext context) {
    // Traditional Mushaf ink colors or custom unified color
    final Color finalFrameColor = frameColor ?? (isDark
        ? const Color.fromARGB(255, 89, 212, 67) // warm gold on dark
        : const Color(0xFF8B6914)); // deep Quran-ink gold on light

    final Color bgColor = Colors.transparent;

    final Color textColor = frameColor ?? (isDark
        ? const Color(0xFFF0D98C)
        : const Color(0xFF3A2200)); // dark Quran ink

    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 8),
      height: 96,
      child: CustomPaint(
        painter: _MushafFramePainter(frameColor: finalFrameColor, bgColor: bgColor),
        child: Center(
          child: Padding(
            // Keep text away from the pointed side ornaments
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'KFGQPC Uthmanic Script',
                  fontFamilyFallback: const [
                    'Scheherazade',
                    'Noto Naskh Arabic',
                  ],
                  fontSize: 30 * fontScale,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      color: finalFrameColor.withValues(alpha: isDark ? 0.5 : 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
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

/// Draws the traditional Mushaf surah header frame:
///  ┌────────────────────────────────────────┐
///  │  ◆──────────────────────────────◆     │  ← outer thin line
///  │  │         SURAH NAME           │  ◀══╪══ pointed side tabs
///  │  ◆──────────────────────────────◆     │  ← outer thin line
///  └────────────────────────────────────────┘
///
/// Two concentric rectangles, pointed protrusions on left & right,
/// corner diamond rosettes.
class _MushafFramePainter extends CustomPainter {
  const _MushafFramePainter({required this.frameColor, required this.bgColor});

  final Color frameColor;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Fill solid background ──────────────────────────────
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.fill;

    // ── 2. Outer frame rectangle ──────────────────────────────
    const outerPad = 6.0;
    final outerRect = Rect.fromLTWH(
      outerPad,
      outerPad,
      w - outerPad * 2,
      h - outerPad * 2,
    );
    canvas.drawRect(outerRect, framePaint);

    // ── 3. Inner frame rectangle ──────────────────────────────
    const innerPad = 11.0;
    final innerRect = Rect.fromLTWH(
      innerPad,
      innerPad,
      w - innerPad * 2,
      h - innerPad * 2,
    );
    canvas.drawRect(innerRect, framePaint);

    // ── 4. Side pointed protrusions (left & right) ────────────
    // Each protrusion is a filled diamond/arrow pointing outward from the middle
    final midY = h / 2;
    const tabW = 14.0; // how far out the point extends from the outer rect
    const tabH = 20.0; // half-height of the tab

    // LEFT protrusion (pointing left)
    final leftPath = Path()
      ..moveTo(outerPad, midY - tabH)
      ..lineTo(outerPad, midY + tabH)
      ..lineTo(outerPad - tabW, midY)
      ..close();
    canvas.drawPath(leftPath, fillPaint);
    // Outline the protrusion
    canvas.drawPath(leftPath, framePaint..style = PaintingStyle.stroke);

    // RIGHT protrusion (pointing right)
    final rightPath = Path()
      ..moveTo(w - outerPad, midY - tabH)
      ..lineTo(w - outerPad, midY + tabH)
      ..lineTo(w - outerPad + tabW, midY)
      ..close();
    // fill with bg first so it overlaps outer rect cleanly
    canvas.drawPath(rightPath, bgPaint);
    canvas.drawPath(rightPath, fillPaint);
    canvas.drawPath(rightPath, framePaint..style = PaintingStyle.stroke);

    // ── 5. Corner diamond rosettes at the 4 inner-rect corners ─
    _drawDiamond(canvas, fillPaint, framePaint, Offset(innerPad, innerPad));
    _drawDiamond(canvas, fillPaint, framePaint, Offset(w - innerPad, innerPad));
    _drawDiamond(canvas, fillPaint, framePaint, Offset(innerPad, h - innerPad));
    _drawDiamond(
      canvas,
      fillPaint,
      framePaint,
      Offset(w - innerPad, h - innerPad),
    );

    // ── 6. Midpoint rosettes on top & bottom inner edges ──────
    _drawDiamond(canvas, fillPaint, framePaint, Offset(w / 2, innerPad));
    _drawDiamond(canvas, fillPaint, framePaint, Offset(w / 2, h - innerPad));

    // ── 7. Thin decorative line between the two frame borders ─
    // (small diagonal strokes at corners, like classic Mushaf corner fills)
    const cp = outerPad;
    const ip = innerPad;
    final cornerLinePaint = Paint()
      ..color = frameColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    // top-left corner fill lines
    canvas.drawLine(Offset(cp, cp), Offset(ip, ip), cornerLinePaint);
    // top-right
    canvas.drawLine(Offset(w - cp, cp), Offset(w - ip, ip), cornerLinePaint);
    // bottom-left
    canvas.drawLine(Offset(cp, h - cp), Offset(ip, h - ip), cornerLinePaint);
    // bottom-right
    canvas.drawLine(
      Offset(w - cp, h - cp),
      Offset(w - ip, h - ip),
      cornerLinePaint,
    );
  }

  void _drawDiamond(Canvas canvas, Paint fill, Paint stroke, Offset center) {
    const r = 4.5;
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(_MushafFramePainter old) =>
      old.frameColor != frameColor || old.bgColor != bgColor;
}

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
