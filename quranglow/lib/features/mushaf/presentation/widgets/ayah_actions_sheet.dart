import 'package:flutter/material.dart';
import 'package:quranglow/core/model/aya/aya.dart';

class AyahActionsSheet extends StatefulWidget {
  const AyahActionsSheet({
    super.key,
    required this.ayat,
    required this.initialAyahNumber,
    required this.onAyahChanged,
    required this.onPlayAyah,
    required this.onOpenTafsir,
    required this.onCopyAyah,
  });

  final List<Aya> ayat;
  final int initialAyahNumber;
  final ValueChanged<int> onAyahChanged;
  final Future<void> Function(List<Aya> ayat, int ayahNumber) onPlayAyah;
  final ValueChanged<int> onOpenTafsir;
  final void Function(int ayahNumber, String ayahText) onCopyAyah;

  @override
  State<AyahActionsSheet> createState() => _AyahActionsSheetState();
}

class _AyahActionsSheetState extends State<AyahActionsSheet> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialAyahNumber - 1).clamp(0, widget.ayat.length - 1);
  }

  TextStyle _ayahPreviewTextStyle(BuildContext context, Color color) =>
      DefaultTextStyle.of(context).style.copyWith(
        color: color,
        fontSize: 22,
        height: 1.8,
        fontFamily: null,
        fontFamilyFallback: const ['Noto Naskh Arabic', 'Scheherazade'],
      );

  void _moveTo(int nextIndex) {
    setState(() => _currentIndex = nextIndex);
    widget.onAyahChanged(widget.ayat[nextIndex].numberInSurah);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentAyah = widget.ayat[_currentIndex];
    final currentAyahNumber = currentAyah.numberInSurah;
    final canGoPrev = _currentIndex > 0;
    final canGoNext = _currentIndex < widget.ayat.length - 1;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'الآية $currentAyahNumber',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canGoPrev ? () => _moveTo(_currentIndex - 1) : null,
                  tooltip: 'الآية السابقة',
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                IconButton(
                  onPressed: canGoNext ? () => _moveTo(_currentIndex + 1) : null,
                  tooltip: 'الآية التالية',
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              currentAyah.text,
              textDirection: TextDirection.rtl,
              style: _ayahPreviewTextStyle(context, cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await widget.onPlayAyah(widget.ayat, currentAyahNumber);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('تشغيل الآية'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onOpenTafsir(currentAyahNumber),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('التفسير'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        widget.onCopyAyah(currentAyahNumber, currentAyah.text),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('نسخ نص الآية'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
