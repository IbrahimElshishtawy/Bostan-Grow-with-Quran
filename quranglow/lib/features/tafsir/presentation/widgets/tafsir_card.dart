// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'error_card.dart';

class TafsirCard extends StatelessWidget {
  const TafsirCard({
    super.key,
    required this.tafsir,
    required this.editionName,
  });

  final AsyncValue<String> tafsir;
  final String? editionName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Premium Indigo/Blue palette for Tafsir
    final Color indigoBg = isDark ? const Color(0xFF1A1F3D) : const Color(0xFFF0F2FF);
    final Color indigoAccent = isDark ? const Color(0xFF3F51B5) : const Color(0xFF3949AB);
    final Color indigoText = isDark ? Colors.white : const Color(0xFF1A237E);

    return tafsir.when(
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: indigoBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: indigoAccent.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 12),
            Text(
              'جارٍ جلب التفسير من المصادر...',
              style: TextStyle(
                color: indigoText.withValues(alpha: 0.6),
                fontSize: 12,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => ErrorCard(msg: 'خطأ في جلب التفسير: $e'),
      data: (text) => Container(
        decoration: BoxDecoration(
          color: indigoBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: indigoAccent.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: indigoAccent.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: indigoAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.auto_stories_rounded, color: indigoAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التفسير الميسّر',
                          style: TextStyle(
                            color: indigoText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        Text(
                          editionName ?? 'المصدر الحالي',
                          style: TextStyle(
                            color: indigoText.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ActionIcon(
                    icon: Icons.copy_all_rounded,
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('تم نسخ نص التفسير'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: indigoAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _ActionIcon(
                    icon: Icons.ios_share_rounded,
                    onTap: () => Share.share(text),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  text.isEmpty ? 'لا يوجد نص تفسير متاح لهذه الآية.' : text,
                  textAlign: TextAlign.justify,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    fontSize: 17,
                    color: indigoText.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF3F51B5) : const Color(0xFF3949AB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: accent),
      ),
    );
  }
}
