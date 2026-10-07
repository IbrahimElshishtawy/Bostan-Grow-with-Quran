import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../domain/entities/ayah.dart';

class AyahActionBottomSheet extends StatelessWidget {
  final Ayah ayah;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onPlayAudio;
  final VoidCallback onShowTafsir;

  const AyahActionBottomSheet({
    super.key,
    required this.ayah,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onPlayAudio,
    required this.onShowTafsir,
  });

  @override
  Widget build(BuildContext context) {
    final surahName = quran.getSurahNameArabic(ayah.surahNumber);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2421) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Surah & Ayah info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سورة $surahName — الآية ${ayah.ayahNumber.toArabic()}',
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldLight : AppColors.primary,
                ),
              ),
              Text(
                'صفحة ${ayah.pageNumber.toArabic()}',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Ayah Preview Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFFBF9F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : AppColors.gold.withOpacity(0.2),
              ),
            ),
            child: Text(
              ayah.textArabic,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 18,
                height: 2.0,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.play_circle_fill_rounded,
                label: 'استماع',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  onPlayAudio();
                },
              ),
              _buildActionButton(
                icon: Icons.menu_book_rounded,
                label: 'التفسير',
                color: AppColors.accent,
                onTap: () {
                  Navigator.pop(context);
                  onShowTafsir();
                },
              ),
              _buildActionButton(
                icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                label: isBookmarked ? 'محفوظة' : 'حفظ',
                color: AppColors.gold,
                onTap: () {
                  onToggleBookmark();
                  Navigator.pop(context);
                },
              ),
              _buildActionButton(
                icon: Icons.copy_rounded,
                label: 'نسخ',
                color: Colors.grey.shade700,
                onTap: () {
                  Clipboard.setData(ClipboardData(
                    text: '${ayah.textArabic} [سورة $surahName: ${ayah.ayahNumber}]',
                  ));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم نسخ الآية الكريمة', style: GoogleFonts.tajawal()),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.share_rounded,
                label: 'مشاركة',
                color: Colors.blue.shade700,
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    '${ayah.textArabic}\n[سورة $surahName: ${ayah.ayahNumber}]',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
