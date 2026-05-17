import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quranglow/core/data/surah_names_ar.dart';
import 'package:quranglow/core/di/core_providers.dart';
import 'package:quranglow/core/di/service_providers.dart';
import 'package:quranglow/core/di/settings_providers.dart';
import 'package:quranglow/core/model/book/bookmark.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/features/bookmarks/presentation/providers/bookmarks_controller.dart';
import 'package:quranglow/features/bookmarks/presentation/providers/bookmarks_usecase.dart';
import 'package:quranglow/features/downloads/presentation/providers/download_controller.dart';

final dailyAyahProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final s =
      ref.read(settingsProvider).whenOrNull(data: (v) => v) ??
      await ref.read(settingsServiceProvider).load();

  final editionId = s.readerEditionId.isNotEmpty
      ? s.readerEditionId
      : 'ar.alafasy';

  final dio = ref.read(dioProvider);
  final res = await dio.get(
    'https://api.alquran.cloud/v1/ayah/random/$editionId',
  );

  if (res.statusCode != 200 || res.data == null) {
    throw Exception('تعذر جلب آية اليوم');
  }

  final data = res.data['data'] ?? {};
  final text = (data['text'] ?? data['ayahText'] ?? '').toString();

  final surah = data['surah'] ?? {};
  final surahName = (surah['name'] ?? surah['englishName'] ?? 'سورة غير معروفة')
      .toString();
  final nInSurah = data['numberInSurah']?.toString() ?? '';

  return {'text': text, 'ref': '$surahName • $nInSurah'};
});

final tafsirEditionsProvider = FutureProvider<List<Map<String, String>>>((ref) {
  return ref.read(quranServiceProvider).listTafsirEditions();
});

final tafsirForAyahProvider = FutureProvider.family<String, (int, int, String)>(
  (ref, t) {
    final (surah, ayah, editionId) = t;
    return ref.read(quranServiceProvider).getAyahTafsir(surah, ayah, editionId);
  },
);

final quranSurahProvider = FutureProvider.autoDispose
    .family<Surah, (int, String)>((ref, t) {
      final (surah, editionId) = t;
      return ref.read(quranServiceProvider).getSurahText(editionId, surah);
    });

final tafsirFutureProvider = FutureProvider.autoDispose
    .family<String?, ({int surah, int ayah, String editionId})>((ref, p) async {
      final svc = ref.read(quranServiceProvider);
      try {
        final t = await svc.getAyahTafsir(p.surah, p.ayah, p.editionId);
        return (t.trim().isEmpty) ? null : t;
      } catch (_) {
        return null;
      }
    });

final surahAudioUrlsProvider = FutureProvider.autoDispose
    .family<List<String>, ({int surah, String reciterId})>((ref, p) async {
      final svc = ref.read(quranServiceProvider);
      return svc.getSurahAudioUrls(p.reciterId, p.surah);
    });

final downloadControllerProvider =
    StateNotifierProvider<DownloadController, DownloadState>((ref) {
      return DownloadController(ref);
    });

final bookmarksProvider =
    StateNotifierProvider<BookmarksController, List<Bookmark>>(
      (ref) => BookmarksController(),
    );

final bookmarksUseCaseProvider = Provider<BookmarksUseCase>(
  (ref) => BookmarksUseCase(ref),
);

final surahNameProvider = FutureProvider.family<String, int>((ref, n) {
  final uc = ref.read(bookmarksUseCaseProvider);
  return uc.getSurahName(n);
});

final surahAyatCountProvider = FutureProvider.family<int, int>((ref, n) {
  final uc = ref.read(bookmarksUseCaseProvider);
  return uc.getAyatCount(n);
});

final dailyQuranProvider =
    Provider<
      ({
        String date,
        String time,
        List<({String text, int surah, int ayah, String surahName})> verses,
      })
    >((ref) {
      final now = DateTime.now();
      // Stable random seed for the day
      final random = Random(now.year * 1000 + now.month * 100 + now.day);

      final List<({String text, int surah, int ayah, String surahName})>
      verses = [];

      for (int i = 0; i < 3; i++) {
        final s = random.nextInt(114) + 1;
        final totalAyah = quran.getVerseCount(s);
        final a = random.nextInt(totalAyah) + 1;

        verses.add((
          text: quran.getVerse(s, a, verseEndSymbol: true),
          surah: s,
          ayah: a,
          surahName: kSurahNamesAr[s - 1],
        ));
      }

      // Basic Arabic Date Formatting
      final monthsAr = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      final dateStr = "${now.day} ${monthsAr[now.month - 1]} ${now.year}";

      // Time formatting (HH:mm)
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      final timeStr = "$hour:$minute";

      return (date: dateStr, time: timeStr, verses: verses);
    });
