// ignore_for_file: depend_on_referenced_packages, no_leading_underscores_for_local_identifiers

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/book/surah.dart';

class DailyAyah {
  final String text;
  final String ref;
  final int surah;
  final int ayah;

  const DailyAyah({
    required this.text,
    required this.ref,
    required this.surah,
    required this.ayah,
  });
}

final dailyAyatLocalProvider = FutureProvider.autoDispose<List<DailyAyah>>((
  ref,
) async {
  const editionId = 'quran-uthmani';
  const count = 3;
  final rnd = Random();
  final quranService = ref.read(quranServiceProvider);
  final box = await Hive.openBox('quran_cache');

  // Check 24-hour cache first
  final lastCachedTimeStr = box.get('daily_ayahs_timestamp') as String?;
  final cachedListRaw = box.get('daily_ayahs_data');

  bool useCache = false;
  if (lastCachedTimeStr != null && cachedListRaw is List) {
    final lastCachedTime = DateTime.tryParse(lastCachedTimeStr);
    if (lastCachedTime != null) {
      final difference = DateTime.now().difference(lastCachedTime);
      if (difference.inHours < 24) {
        useCache = true;
      }
    }
  }

  if (useCache && cachedListRaw is List) {
    try {
      final list = cachedListRaw.map((item) {
        final m = Map<String, dynamic>.from(item as Map);
        return DailyAyah(
          text: m['text'] as String,
          ref: m['ref'] as String,
          surah: m['surah'] as int,
          ayah: m['ayah'] as int,
        );
      }).toList();
      if (list.length == count) {
        return list;
      }
    } catch (_) {}
  }

  List<String> _surahKeys() => box.keys
      .where((k) => k.toString().startsWith('$editionId-'))
      .map((e) => e.toString())
      .toList();

  Map<String, dynamic> _asStringKeyMap(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(
        raw.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    throw Exception('صيغة غير متوقعة لبيانات السورة.');
  }

  Map<String, dynamic> _root(Map<String, dynamic> j) =>
      _asStringKeyMap(j['chapter'] ?? j['data'] ?? j);

  List _verses(Map<String, dynamic> r) {
    final v = r['verses'] ?? r['ayahs'] ?? r['aya'] ?? r['list'] ?? [];
    return v is List ? v : <dynamic>[];
  }

  int _parseInt(Object? o, {int orElse = 1}) {
    if (o is int) return o;
    final s = o?.toString() ?? '';
    final n = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
    return n ?? orElse;
  }

  String _verseText(Map<String, dynamic> m) =>
      (m['text'] ?? m['arabic'] ?? m['quran'] ?? '').toString();

  final chosen = <String>{};
  final out = <DailyAyah>[];

  bool _addAyah({
    required int surahNum,
    required int ayahNum,
    required String text,
    required String surahName,
  }) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return false;

    final uniqueKey = '$surahNum:$ayahNum';
    if (!chosen.add(uniqueKey)) return false;

    out.add(
      DailyAyah(
        text: trimmedText,
        ref:
            surahName.trim().isEmpty
                ? 'آية $ayahNum'
                : 'سورة $surahName • آية $ayahNum',
        surah: surahNum,
        ayah: ayahNum,
      ),
    );
    return true;
  }

  final keys = _surahKeys();
  for (int i = 0; i < count * 3 && out.length < count && keys.isNotEmpty; i++) {
    final k = keys[rnd.nextInt(keys.length)];
    final raw = box.get(k);

    try {
      final j = _asStringKeyMap(raw);
      final r = _root(j);
      final parts = k.split('-');
      final surahNum = _parseInt(parts.isNotEmpty ? parts.last : null);
      final surahName =
          (r['name_ar'] ?? r['name_arabic'] ?? r['name'] ?? '').toString();
      final verses = _verses(r);
      if (verses.isEmpty) continue;

      final vMap = _asStringKeyMap(verses[rnd.nextInt(verses.length)]);
      final ayahNum = _parseInt(
        vMap['number'] ??
            vMap['numberInSurah'] ??
            vMap['verse'] ??
            vMap['verse_number'] ??
            vMap['id'],
      );

      _addAyah(
        surahNum: surahNum,
        ayahNum: ayahNum,
        text: _verseText(vMap),
        surahName: surahName,
      );
    } catch (_) {
      continue;
    }
  }

  if (out.length < count) {
    final chapters = List<int>.generate(114, (i) => i + 1)..shuffle(rnd);
    final maxFetches = min(8, chapters.length);

    for (int i = 0; i < maxFetches && out.length < count; i++) {
      try {
        final Surah surah = await quranService.getSurahText(
          editionId,
          chapters[i],
        );
        if (surah.ayat.isEmpty) continue;

        final ayah = surah.ayat[rnd.nextInt(surah.ayat.length)];
        _addAyah(
          surahNum: surah.number,
          ayahNum: ayah.numberInSurah,
          text: ayah.text,
          surahName: surah.name,
        );
      } catch (_) {
        continue;
      }
    }
  }

  if (out.isEmpty) {
    throw Exception(
      'لا توجد آيات متاحة حاليًا. جرّب فتح سورة مع اتصال بالإنترنت ثم أعد المحاولة.',
    );
  }

  try {
    final dataToCache = out.map((a) => {
      'text': a.text,
      'ref': a.ref,
      'surah': a.surah,
      'ayah': a.ayah,
    }).toList();
    await box.put('daily_ayahs_timestamp', DateTime.now().toIso8601String());
    await box.put('daily_ayahs_data', dataToCache);

    // Save and update the home screen widget "outside the app"
    final versesText = out.map((v) => v.text).join('\n\n');
    final versesRef = out.map((v) => v.ref).join('\n');
    
    await HomeWidget.saveWidgetData<String>('widget_quran_verse', versesText);
    await HomeWidget.saveWidgetData<String>('widget_quran_ref', versesRef);
    
    for (int i = 0; i < out.length; i++) {
      await HomeWidget.saveWidgetData<String>('verse_${i + 1}_text', out[i].text);
      await HomeWidget.saveWidgetData<String>('verse_${i + 1}_ref', out[i].ref);
    }

    await HomeWidget.updateWidget(
      androidName: 'LearningWidgetProvider',
      iOSName: 'LearningWidgetProvider',
    );
  } catch (e) {
    // Robust error handling to make sure any home widget API issues don't block the app
    print('Error updating HomeWidget in daily_ayah_provider: $e');
  }

  return out;
});

/// Clears the 24-hour cache and triggers a fresh fetch of daily verses
Future<void> refreshDailyAyah(WidgetRef ref) async {
  try {
    final box = await Hive.openBox('quran_cache');
    await box.delete('daily_ayahs_timestamp');
    await box.delete('daily_ayahs_data');
  } catch (_) {}
  ref.invalidate(dailyAyatLocalProvider);
}
