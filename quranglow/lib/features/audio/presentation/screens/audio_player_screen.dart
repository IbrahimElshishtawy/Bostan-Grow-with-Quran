import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/quran_typography.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../domain/entities/reciter.dart';
import '../providers/audio_player_notifier.dart';

class AudioPlayerScreen extends ConsumerWidget {
  const AudioPlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showReciterPicker(BuildContext context, WidgetRef ref, Reciter current) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر القارئ',
                style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ...Reciter.defaultReciters.map(
                (reciter) => ListTile(
                  title: Text(reciter.nameArabic, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
                  subtitle: Text(reciter.style, style: GoogleFonts.tajawal(fontSize: 12)),
                  trailing: reciter.id == current.id
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(quranAudioNotifierProvider.notifier).setReciter(reciter);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(quranAudioNotifierProvider);
    final audioNotifier = ref.read(quranAudioNotifierProvider.notifier);

    final surahName = quran.getSurahNameArabic(audioState.currentSurah);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التلاوة والاستماع',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldLight : AppColors.primary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const Spacer(),

            // Reciter Badge Button
            InkWell(
              onTap: () => _showReciterPicker(context, ref, audioState.selectedReciter),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2320) : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      audioState.selectedReciter.nameArabic,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldLight : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Quran Card View with Surah & Ayah
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.darkEmeraldGradient : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'سورة $surahName',
                    style: QuranTypography.surahTitle(
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الآية ${audioState.currentAyah.toArabic()} من ${quran.getVerseCount(audioState.currentSurah).toArabic()}',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    quran.getVerse(audioState.currentSurah, audioState.currentAyah, verseEndSymbol: true),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: QuranTypography.ayahText(
                      fontSize: 20,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Progress Slider
            Column(
              children: [
                Slider(
                  value: audioState.currentPosition.inSeconds.toDouble().clamp(
                        0.0,
                        (audioState.totalDuration.inSeconds > 0
                                ? audioState.totalDuration.inSeconds
                                : 1)
                            .toDouble(),
                      ),
                  max: (audioState.totalDuration.inSeconds > 0
                          ? audioState.totalDuration.inSeconds
                          : 1)
                      .toDouble(),
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    audioNotifier.seek(Duration(seconds: val.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(audioState.currentPosition),
                        style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _formatDuration(audioState.totalDuration),
                        style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Audio Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Repeat Ayah Toggle
                IconButton(
                  icon: Icon(
                    Icons.repeat_one_rounded,
                    color: audioState.repeatAyah ? AppColors.primary : Colors.grey,
                  ),
                  onPressed: () => audioNotifier.toggleRepeatAyah(),
                ),

                // Previous Ayah
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: () => audioNotifier.previousAyah(),
                ),

                // Play / Pause Button
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: audioState.isBuffering
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : IconButton(
                            iconSize: 32,
                            color: Colors.white,
                            icon: Icon(audioState.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded),
                            onPressed: () {
                              if (audioState.isPlaying) {
                                audioNotifier.pause();
                              } else {
                                audioNotifier.playAyah(audioState.currentSurah, audioState.currentAyah);
                              }
                            },
                          ),
                  ),
                ),

                // Next Ayah
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: () => audioNotifier.nextAyah(),
                ),

                // Speed Selector
                PopupMenuButton<double>(
                  initialValue: audioState.speed,
                  tooltip: 'سرعة القراءة',
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${audioState.speed}x',
                      style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onSelected: (val) => audioNotifier.setSpeed(val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                    const PopupMenuItem(value: 1.0, child: Text('1.0x (طبيعي)')),
                    const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                    const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
