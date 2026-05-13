// lib/features/ui/pages/mushaf/span_builder.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quranglow/core/model/aya/aya.dart';

class AyahSpanBuilder {
  AyahSpanBuilder({
    required this.onAyahTap,
    required this.onAyahLongPress,
    required this.fontScale,
  });
  final void Function(int index) onAyahTap;
  final void Function(int index) onAyahLongPress;
  final double fontScale;

  final Map<int, List<InlineSpan>> _cache = {};
  static final _selectedAyahColor = Colors.green.withValues(alpha: 0.16);

  TextStyle get _base => TextStyle(
    fontSize: 22 * fontScale,
    height: 2.1,
    fontFamily: 'KFGQPC Uthmanic Script',
    fontFamilyFallback: const ['Noto Naskh Arabic', 'Scheherazade'],
  );

  List<InlineSpan> buildSpans({
    required List<Aya> ayat,
    required int? currentAyahIndex,
    Color? ayahNumberColor,
    required List<GestureRecognizer> recognizersBucket,
    bool isHifzMode = false,
    Map<int, Set<int>> revealedWords = const {},
    Map<int, Set<int>> mistakenWords = const {},
  }) {
    // Compute stable content hash for the Map cache keys
    int revealedContentHash = 0;
    for (final entry in revealedWords.entries) {
      revealedContentHash ^= Object.hash(entry.key, Object.hashAll(entry.value));
    }
    int mistakenContentHash = 0;
    for (final entry in mistakenWords.entries) {
      mistakenContentHash ^= Object.hash(entry.key, Object.hashAll(entry.value));
    }

    final cacheKey = Object.hash(
      ayat.first.number,
      ayat.last.number,
      currentAyahIndex,
      isHifzMode,
      revealedWords.length,
      revealedContentHash,
      mistakenWords.length,
      mistakenContentHash,
    );
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final out = <InlineSpan>[];
    for (final r in recognizersBucket) {
      r.dispose();
    }
    recognizersBucket.clear();

    for (var i = 0; i < ayat.length; i++) {
      final a = ayat[i];
      final r = TapGestureRecognizer()..onTap = () => onAyahTap(i);
      recognizersBucket.add(r);
      final selected = currentAyahIndex == i;
      
      final words = a.text.trim().split(RegExp(r'\s+'));
      final revealedIndices = revealedWords[a.numberInSurah] ?? const {};
      final mistakenIndices = mistakenWords[a.numberInSurah] ?? const {};
      
      final isAnyWordRevealed = revealedIndices.isNotEmpty || mistakenIndices.isNotEmpty;
      
      TextStyle baseStyle = selected
          ? _base.copyWith(
              backgroundColor: isHifzMode && !isAnyWordRevealed ? Colors.transparent : _selectedAyahColor,
            )
          : _base;

      // 🧩 Split and render word by word
      for (int wIdx = 0; wIdx < words.length; wIdx++) {
        final isWordMistaken = mistakenIndices.contains(wIdx);
        final isWordHidden = isHifzMode && !isWordMistaken && !revealedIndices.contains(wIdx);
        
        TextStyle s = baseStyle;
        if (isWordMistaken) {
          // 🚨 Render mistaken word in striking red!
          s = s.copyWith(
            color: Colors.redAccent.shade700, 
            fontWeight: FontWeight.bold,
          );
        } else if (isWordHidden) {
          s = s.copyWith(color: Colors.transparent, backgroundColor: Colors.transparent);
        }
        out.add(TextSpan(text: '${words[wIdx]} ', style: s, recognizer: r));
      }

      out.add(const TextSpan(text: '\u200F')); // Force RTL continuity for WidgetSpan
      out.add(_ayahMarker(
        ayahNumber: a.numberInSurah,
        selected: selected && (!isHifzMode || isAnyWordRevealed),
        ayahNumberColor: ayahNumberColor,
        onTap: () => onAyahTap(i),
        onLongPress: () => onAyahLongPress(i),
      ));
      out.add(const TextSpan(text: '\u200F'));
      
      final isSpaceHidden = isHifzMode && !isAnyWordRevealed;
      out.add(TextSpan(text: '  ', style: isSpaceHidden ? _base.copyWith(color: Colors.transparent) : _base));
    }
    _cache[cacheKey] = out;
    return out;
  }

  InlineSpan _ayahMarker({
    required int ayahNumber,
    required bool selected,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? ayahNumberColor,
  }) {
    final txt = _toArabicDigits(ayahNumber);
    
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 🌟 8-POINTED ISLAMIC STAR LAYER 1 (BASE)
              Transform.rotate(
                angle: 0.785398, // 45 Degrees
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected ? Colors.green.shade100 : Colors.transparent,
                    border: Border.all(
                      color: ayahNumberColor ?? const Color(0xFFD4AF37),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // 🌟 LAYER 2 (ROTATED)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? Colors.green.shade100 : Colors.transparent,
                  border: Border.all(
                    color: ayahNumberColor ?? const Color(0xFFD4AF37),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // 📜 THE ARABIC NUMBER INSIDE!
              Container(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  txt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'KFGQPC Uthmanic Script',
                    height: 1.0,
                    color: ayahNumberColor ?? const Color(0xFF5D4037),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _toArabicDigits(int n) {
    const east = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final s = n.toString();
    final b = StringBuffer();
    for (final ch in s.runes) {
      final c = String.fromCharCode(ch);
      final d = int.tryParse(c);
      b.write(d == null ? c : east[d]);
    }
    return b.toString();
  }
}
