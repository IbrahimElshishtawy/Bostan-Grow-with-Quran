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
    this.ayahNumberColor,
  });

  final List<Aya> ayat;
  final PageRange range;
  final bool showBasmala;
  final String basmalaText;
  final int? currentAyahIndex;
  final void Function(int index) onTapIndex;
  final void Function(int index) onLongPressIndex;
  final Color? ayahNumberColor;

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
      onAyahTap: (localIndex) => widget.onTapIndex(widget.range.start + localIndex),
      onAyahLongPress: (localIndex) =>
          widget.onLongPressIndex(widget.range.start + localIndex),
    );

    final spans = builder.buildSpans(
      ayat: subAyat,
      currentAyahIndex: localCurrentIndex,
      ayahNumberColor: widget.ayahNumberColor,
      recognizersBucket: _recognizers,
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30), // Generous, wide reading margins
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: c.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                        fontSize: 30 * fontScale, // Scaled up for impact
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  RichText(
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    strutStyle: StrutStyle(
                      fontSize: 27 * fontScale, // Bigger, grander typeface
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
                        height: 2.25, // Breathing room vertically
                        fontSize: 27 * fontScale, 
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
                              backgroundColor: cs.secondaryContainer.withValues(alpha: 0.6),
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
        );
      },
    );
  }

  int? _mapToLocal(int global, int start, int end) {
    if (global < start || global >= end) return null;
    return global - start;
  }
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
