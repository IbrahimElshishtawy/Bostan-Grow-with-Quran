// lib/features/mushaf/presentation/widgets/selected_ayah_panel.dart
import 'dart:ui';
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
    required this.onSave,
    this.isPlaying = false,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  final bool visible;
  final int? ayahNumber;
  final String? ayahText;
  final VoidCallback onClear;
  final VoidCallback onOpenTafsir;
  final VoidCallback onPlay;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final bool isPlaying;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  TextStyle _ayahPreviewTextStyle(BuildContext context, Color color) =>
      TextStyle(
        color: color,
        fontSize: 22,
        height: 1.8,
        fontFamily: 'KFGQPC Uthmanic Script',
        fontFamilyFallback: const ['Noto Naskh Arabic', 'Scheherazade'],
        shadows: [
          Shadow(
            offset: const Offset(0, 0.5),
            blurRadius: 2,
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Glassmorphic Colors
    final Color barBorderColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.35)
        : const Color(0xFFC5A85C).withOpacity(0.55);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.1),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -150) {
                  // Swipe Left -> next Ayah
                  onSwipeLeft?.call();
                } else if (details.primaryVelocity! > 150) {
                  // Swipe Right -> previous Ayah
                  onSwipeRight?.call();
                }
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: barBorderColor,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
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
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Row: Ayah Badge and Close button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF144D34)
                                      : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0x66D4AF37)
                                        : const Color(0x66C5A85C),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'الآية ${ayahNumber ?? ''}',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFD4AF37)
                                        : const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Tajawal',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: onClear,
                                icon: const Icon(Icons.close_rounded, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.05),
                                  foregroundColor: isDark
                                      ? Colors.white70
                                      : const Color(0xFF5D4037),
                                  padding: const EdgeInsets.all(6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                tooltip: 'إغلاق المعاينة',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Ayah Quran Text
                          if (ayahText != null && ayahText!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                              child: Text(
                                ayahText!,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: _ayahPreviewTextStyle(
                                  context,
                                  isDark ? Colors.white.withOpacity(0.95) : const Color(0xFF2E2212),
                                ),
                              ),
                            ),
                            
                          // Action Row 1: Play & Tafsir
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: onPlay,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isPlaying
                                        ? Colors.red.shade900
                                        : (isDark
                                            ? const Color(0xFF1E3A2F)
                                            : const Color(0xFFE8F5E9)),
                                    foregroundColor: isPlaying
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.green.shade300
                                            : Colors.green.shade800),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: Icon(
                                    isPlaying
                                        ? Icons.stop_circle_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isPlaying ? 'إيقاف الصّوت' : 'تشغيل الصّوت',
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: onOpenTafsir,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? const Color(0xFF3E2D1A)
                                        : const Color(0xFFFFF3E0),
                                    foregroundColor: isDark
                                        ? const Color(0xFFFFB74D)
                                        : const Color(0xFFE65100),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                                  label: const Text(
                                    'عرض التفسير',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          
                          // Action Row 2: Bookmark & Copy
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: onSave,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? const Color(0xFF333A18)
                                        : const Color(0xFFF1F8E9),
                                    foregroundColor: isDark
                                        ? const Color(0xFFAED581)
                                        : const Color(0xFF33691E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                                  label: const Text(
                                    'حفظ موضع القراءة',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onCopy,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF2C3E35)
                                          : const Color(0xFFE0D8C5),
                                    ),
                                    foregroundColor: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5D4037),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  label: const Text(
                                    'نسخ النص',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
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
      ),
    );
  }
}
