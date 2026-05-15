// ignore_for_file: depend_on_referenced_packages, implementation_imports, avoid_print, unnecessary_import

import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quranglow/core/api/fawaz_cdn_source.dart';
import 'package:quranglow/core/api/alquran_cloud_source.dart';
import 'package:quranglow/core/model/aya/aya.dart';
import 'package:quranglow/core/model/book/surah.dart';

class QuranService {
  final FawazCdnSource fawaz;
  final AlQuranCloudSource cloud;
  QuranService({
    required this.fawaz,
    required this.cloud,
    required AlQuranCloudSource audio, // kept for ctor compatibility
  });

  final Map<String, Map<int, Surah>> _surahCacheByEdition = {};
  final Map<String, Uint8List> _imageCache = {};
  final int _imageCacheMax = 32;

  // de-dupe in-flight requests
  final Map<String, Future<Surah>> _inflight = {};

  // open Hive box once
  final Future<Box> _boxFuture = Hive.openBox('quran_cache');

  Duration _backoff(int attempt) =>
      Duration(milliseconds: (400 * (1 << attempt)).clamp(400, 8000));

  Future<Surah> getSurahText(String editionId, int chapter) async {
    final editionCache = _surahCacheByEdition.putIfAbsent(editionId, () => {});
    final cached = editionCache[chapter];
    if (cached != null) return cached;

    final key = '$editionId-$chapter';
    if (_inflight.containsKey(key)) return _inflight[key]!;

    final completer = Completer<Surah>();
    _inflight[key] = completer.future;

    try {
      final box = await _boxFuture;

      if (box.containsKey(key)) {
        final localJson = Map<String, dynamic>.from(box.get(key));
        final localSurah = await compute(_parseSurahJsonIsolate, {
          'json': localJson,
          'editionId': editionId,
          'chapter': chapter,
        });
        editionCache[chapter] = localSurah;
        debugPrint('[SRV][OFFLINE] loaded surah $chapter from local Hive');
        completer.complete(localSurah);
        return localSurah;
      }

      debugPrint('[SRV][ONLINE] fetch surah=$chapter ed=$editionId');

      // retry/backoff for 429/5xx/timeouts
      int attempt = 0;
      late Map<String, dynamic> json;
      while (true) {
        try {
          json = editionId == 'quran-uthmani'
              ? await cloud.getSurahText(editionId, chapter)
              : await fawaz.getSurah(editionId, chapter);
          break;
        } catch (e) {
          final msg = e.toString();
          final retryable =
              msg.contains('429') ||
              msg.contains(' 5') ||
              msg.contains('Timeout');
          if (!retryable || attempt >= 5) rethrow;
          await Future.delayed(_backoff(attempt++));
        }
      }

      await (await _boxFuture).put(key, json);
      final surah = await compute(_parseSurahJsonIsolate, {
        'json': json,
        'editionId': editionId,
        'chapter': chapter,
      });
      editionCache[chapter] = surah;
      completer.complete(surah);
      return surah;
    } finally {
      _inflight.remove(key);
    }
  }

  // parse on background isolate
  static Surah _parseSurahJsonIsolate(Map args) {
    return _parseSurahJson(
      Map<String, dynamic>.from(args['json']),
      args['editionId'] as String,
      args['chapter'] as int,
    );
  }

  static Surah _parseSurahJson(
    Map<String, dynamic> json,
    String editionId,
    int chapter,
  ) {
    final root = json['chapter'] ?? json['data'] ?? json;
    final name =
        (root['name_ar'] ??
                root['name_arabic'] ??
                root['name'] ??
                'سورة $chapter')
            as String;

    final dynamic versesAny =
        root['verses'] ?? root['ayahs'] ?? root['aya'] ?? root['list'] ?? [];
    final List list = versesAny is List ? versesAny : [];

    final ayat =
        list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return Aya.fromMap({
            'global': m['global'] ?? m['globalId'] ?? m['id'] ?? m['number'],
            'surah': chapter,
            'numberInSurah':
                m['numberInSurah'] ??
                m['number_in_surah'] ??
                m['verse'] ??
                m['verse_number'] ??
                m['ayah'] ??
                m['aya'],
            'number':
                m['number'] ??
                m['numberInSurah'] ??
                m['verse'] ??
                m['verse_number'] ??
                m['id'] ??
                0,
            'text': m['text'] ?? m['arabic'] ?? m['quran'] ?? '',
          });
        }).toList()..sort((a, b) {
          final bySurahOrder = a.numberInSurah.compareTo(b.numberInSurah);
          if (bySurahOrder != 0) return bySurahOrder;
          return a.number.compareTo(b.number);
        });

    return Surah(number: chapter, name: name, ayat: ayat.cast<Aya>());
  }

  /// Avoid calling this at startup. Prefer on-demand loading.
  Future<List<Surah>> getQuranAllText(String editionId) async {
    final out = <Surah>[];
    for (var i = 1; i <= 114; i++) {
      try {
        final s = await getSurahText(editionId, i);
        out.add(s);
        await Future.delayed(const Duration(milliseconds: 50)); // throttle
      } catch (e) {
        debugPrint('[SRV][ALL] skip $i: $e');
      }
    }
    return out;
  }

  Future<List> listAudioEditions() => cloud.listAudioEditions();
  Future<Map<String, dynamic>> getSurahAudio(String ed, int s) =>
      cloud.getSurahAudio(ed, s);

  // Search locally first for speed/offline behavior, then fall back to API.
  Future<List<Map<String, dynamic>>> searchAyat(
    String query, {
    required String editionId,
    int limit = 50,
  }) async {
    final q = _normalizeArabicForSearch(query);
    if (q.isEmpty) return const [];
    final cache = _surahCacheByEdition.putIfAbsent(editionId, () => {});
    final box = await _boxFuture;

    final hits = <Map<String, dynamic>>[];
    var inspectedLocalContent = false;
    for (var s = 1; s <= 114; s++) {
      Surah? surah = cache[s];
      if (surah == null) {
        final key = '$editionId-$s';
        if (!box.containsKey(key)) continue;
        final json = Map<String, dynamic>.from(box.get(key));
        surah = await compute(_parseSurahJsonIsolate, {
          'json': json,
          'editionId': editionId,
          'chapter': s,
        });
        cache[s] = surah!;
      }
      inspectedLocalContent = true;
      for (final aya in surah.ayat) {
        if (_normalizeArabicForSearch(aya.text).contains(q)) {
          hits.add({
            'surahNumber': surah.number,
            'ayahNumber': aya.number,
            'surahName': surah.name,
            'text': aya.text,
          });
          if (hits.length >= limit) return hits;
        }
      }
    }

    if (hits.isNotEmpty) return hits;

    try {
      final remoteHits = await cloud.searchAyat(query, editionId: editionId);
      if (remoteHits.isNotEmpty) {
        return remoteHits.take(limit).toList(growable: false);
      }
    } catch (e) {
      debugPrint('[SRV][SEARCH] remote search failed: $e');
    }

    if (!inspectedLocalContent) {
      debugPrint('[SRV][SEARCH] no local Quran cache available for $editionId');
    }
    return hits;
  }

  Future<Uint8List> getImageBytes(String url) async {
    final u = url.trim();
    if (u.isEmpty) throw ArgumentError('empty url');
    final cached = _imageCache[u];
    if (cached != null) return cached;
    final uri = Uri.parse(u);
    final byteData = await NetworkAssetBundle(uri).load(uri.toString());
    final bytes = byteData.buffer.asUint8List();
    if (bytes.isEmpty) throw Exception('failed to load image: $u');
    if (_imageCache.length >= _imageCacheMax) {
      _imageCache.remove(_imageCache.keys.first);
    }
    _imageCache[u] = bytes;
    return bytes;
  }

  ImageProvider getImageProvider(String url) {
    final cached = _imageCache[url];
    if (cached != null) return MemoryImage(cached);
    return NetworkImage(url);
  }

  String _normalizeArabicForSearch(String input) {
    var s = input.trim();
    const diacritics = r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]';
    s = s.replaceAll(RegExp(diacritics), '');
    s = s.replaceAll('\u0640', '');
    s = s.replaceAll(RegExp(r'[^\u0600-\u06FF0-9\s]'), '');
    s = s.replaceAll(RegExp('[\u0623\u0625\u0622\u0671]'), '\u0627');
    s = s.replaceAll('\u0649', '\u064A');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  void clearImageCache() => _imageCache.clear();

  Future<List<Map<String, String>>> listTafsirEditions() async {
    final raw = await cloud.listTafsirEditions();
    return raw.map((m) {
      final id = (m['identifier'] ?? m['id'] ?? '').toString();
      final name = (m['name'] ?? m['englishName'] ?? id).toString();
      return {'id': id, 'name': name};
    }).toList();
  }

  Future<String> getAyahTafsir(int surah, int ayah, String editionId) {
    return cloud.getAyahTafsir(surah: surah, ayah: ayah, editionId: editionId);
  }

  Future<List<String>> getSurahAudioUrls(String editionId, int surah) async {
    final localFiles = await _getLocalDownloadedSurahAudioFiles(
      editionId,
      surah,
    );
    if (localFiles.isNotEmpty) {
      return localFiles.map((file) => Uri.file(file.path).toString()).toList();
    }

    final map = await cloud.getSurahAudio(editionId, surah);
    final ayahs = _extractAudioAyahs(map);
    if (ayahs.isNotEmpty) {
      return ayahs
          .map(_readAudioUrl)
          .whereType<String>()
          .where((url) => url.trim().isNotEmpty)
          .toList(growable: false);
    }
    throw Exception('No ayah audio URLs found for $editionId in surah $surah');
  }

  /// Returns the URL for a single audio file containing the entire Surah.
  /// This is useful for continuous playback with correct total duration.
  String getSurahFullAudioUrl(String editionId, int surah) {
    // Map AlQuran.cloud edition IDs to Quran.com reciter IDs
    final Map<String, int> reciterMap = {
      'ar.alafasy': 7,
      'ar.abdulsamad': 1,
      'ar.abdullahbasfar': 3,
      'ar.abdurrahmaansudais': 4,
      'ar.ahmedajamy': 5,
      'ar.alajmy': 5,
      'ar.hanirifai': 6,
      'ar.hudhaify': 8,
      'ar.husary': 9,
      'ar.minshawi': 10,
      'ar.mahermuaiqly': 11,
      'ar.saoodshuraym': 12,
    };

    final reciterId = reciterMap[editionId];
    if (reciterId != null) {
      // Use Quran.com CDN (Very reliable, supports range requests, gapless)
      return 'https://audio.qurancdn.com/reciters/$reciterId/chapters/$surah.mp3';
    }

    // Fallback to Islamic Network CDN with User-Agent headers (handled in player)
    return 'https://cdn.islamic.network/quran/audio-surah/128/$editionId/$surah.mp3';
  }

  Future<Map<int, String>> getSurahAudioUrlMap(
    String editionId,
    int surah,
  ) async {
    final localFiles = await _getLocalDownloadedSurahAudioFiles(
      editionId,
      surah,
    );
    if (localFiles.isNotEmpty) {
      final out = <int, String>{};
      for (final file in localFiles) {
        final ayahNumber = int.tryParse(p.basenameWithoutExtension(file.path));
        if (ayahNumber == null) continue;
        out[ayahNumber] = Uri.file(file.path).toString();
      }
      if (out.isNotEmpty) {
        return out;
      }
    }

    final map = await cloud.getSurahAudio(editionId, surah);
    final ayahs = _extractAudioAyahs(map);
    if (ayahs.isEmpty) {
      return <int, String>{};
    }

    final out = <int, String>{};
    for (final item in ayahs) {
      final rawAyahNumber =
          item['numberInSurah'] ??
          item['number_in_surah'] ??
          item['ayah'] ??
          item['aya'] ??
          item['verseNumber'];
      final ayahNumber = switch (rawAyahNumber) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      };
      final audio = _readAudioUrl(item);
      if (ayahNumber == null || audio == null || audio.trim().isEmpty) {
        continue;
      }
      out[ayahNumber] = audio;
    }
    return out;
  }

  List<Map<String, dynamic>> _extractAudioAyahs(Map<String, dynamic> payload) {
    final data = payload['data'];
    final candidates = <dynamic>[
      data is Map ? data['ayahs'] : null,
      payload['ayahs'],
      data is Map ? data['verses'] : null,
      payload['verses'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
    }

    return const <Map<String, dynamic>>[];
  }

  String? _readAudioUrl(Map<String, dynamic> ayah) {
    final direct = ayah['audio']?.toString().trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final secondary = ayah['audioSecondary'];
    if (secondary is List) {
      for (final item in secondary) {
        final value = item?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    final audioUrl = ayah['audioUrl']?.toString().trim();
    if (audioUrl != null && audioUrl.isNotEmpty) {
      return audioUrl;
    }

    return null;
  }

  Future<List<File>> _getLocalDownloadedSurahAudioFiles(
    String editionId,
    int surah,
  ) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(docs.path, 'QuranGlow', 'downloads', 'audio', editionId, '$surah'),
    );
    if (!await dir.exists()) {
      return const <File>[];
    }

    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.mp3'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return files;
  }
}
