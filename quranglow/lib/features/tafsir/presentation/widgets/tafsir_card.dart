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
    final isDark = theme.brightness == Brightness.dark;

    // Premium Deep Teal/Gold palette for Tafsir
    final Color primaryBg = isDark
        ? const Color(0xFF0F2921)
        : const Color(0xFFF6FAF7);
    final Color accentColor = const Color(0xFFD4AF37); // Gold
    final Color primaryText = isDark ? Colors.white : const Color(0xFF1B4D3E);

    return tafsir.when(
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: primaryBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accentColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const LinearProgressIndicator(minHeight: 2, color: Color(0xFFD4AF37)),
            const SizedBox(height: 12),
            Text(
              'جارٍ جلب التفسير...',
              style: TextStyle(
                color: primaryText.withValues(alpha: 0.6),
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
          color: primaryBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التفسير',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        Text(
                          editionName ?? 'المصدر الحالي',
                          style: TextStyle(
                            color: primaryText.withValues(alpha: 0.6),
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
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  text.isEmpty ? 'لا يوجد نص تفسير متاح لهذه الآية.' : text,
                  textAlign: TextAlign.justify,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    fontSize: 17,
                    color: primaryText.withValues(alpha: 0.9),
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
    final accent = const Color(0xFFD4AF37);

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

