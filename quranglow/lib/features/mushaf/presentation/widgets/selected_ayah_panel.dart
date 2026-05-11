import 'package:flutter/material.dart';

class SelectedAyahPanel extends StatelessWidget {
  const SelectedAyahPanel({
    super.key,
    required this.visible,
    required this.ayahNumber,
    required this.ayahText,
    required this.onClear,
    required this.onOpenTafsir,
    required this.onPlay,
    required this.onCopy,
    this.isPlaying = false,
  });

  final bool visible;
  final int? ayahNumber;
  final String? ayahText;
  final VoidCallback onClear;
  final VoidCallback onOpenTafsir;
  final VoidCallback onPlay;
  final VoidCallback onCopy;
  final bool isPlaying;

  TextStyle _ayahPreviewTextStyle(BuildContext context, Color color) =>
      DefaultTextStyle.of(context).style.copyWith(
        color: color,
        fontSize: 20,
        height: 1.7,
        fontFamily: null,
        fontFamilyFallback: const ['Noto Naskh Arabic', 'Scheherazade'],
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'الآية ${ayahNumber ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'إغلاق المعاينة',
                      ),
                    ],
                  ),
                  if (ayahText != null && ayahText!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SelectableText(
                        ayahText!,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: _ayahPreviewTextStyle(
                          context,
                          cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onPlay,
                          style: isPlaying
                              ? FilledButton.styleFrom(
                                  backgroundColor: Colors.red.shade800,
                                  foregroundColor: Colors.white,
                                )
                              : null,
                          icon: Icon(
                            isPlaying
                                ? Icons.stop_circle_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(isPlaying ? 'إيقاف' : 'تشغيل'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onOpenTafsir,
                          icon: const Icon(Icons.menu_book_rounded),
                          label: const Text('عرض التفسير'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('نسخ الآية'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
