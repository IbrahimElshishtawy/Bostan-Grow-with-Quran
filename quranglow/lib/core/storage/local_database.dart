import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const String boxReadingProgress = 'box_reading_progress';
  static const String boxBookmarks = 'box_bookmarks';
  static const String boxDailyGoals = 'box_daily_goals';
  static const String boxKhatmah = 'box_khatmah';
  static const String boxMemorization = 'box_memorization';
  static const String boxAudioDownloads = 'box_audio_downloads';
  static const String boxSyncQueue = 'box_sync_queue';
  static const String boxSettings = 'box_settings';

  late Box _readingProgressBox;
  late Box _bookmarksBox;
  late Box _dailyGoalsBox;
  late Box _khatmahBox;
  late Box _memorizationBox;
  late Box _audioDownloadsBox;
  late Box _syncQueueBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _readingProgressBox = await Hive.openBox(boxReadingProgress);
    _bookmarksBox = await Hive.openBox(boxBookmarks);
    _dailyGoalsBox = await Hive.openBox(boxDailyGoals);
    _khatmahBox = await Hive.openBox(boxKhatmah);
    _memorizationBox = await Hive.openBox(boxMemorization);
    _audioDownloadsBox = await Hive.openBox(boxAudioDownloads);
    _syncQueueBox = await Hive.openBox(boxSyncQueue);
    _settingsBox = await Hive.openBox(boxSettings);
  }

  // ==================== Reading Progress ====================
  Map<String, dynamic>? getReadingProgress() {
    final raw = _readingProgressBox.get('current');
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    try {
      return jsonDecode(raw.toString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveReadingProgress({
    required int pageNumber,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final data = {
      'pageNumber': pageNumber,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _readingProgressBox.put('current', data);
  }

  // ==================== Bookmarks ====================
  List<Map<String, dynamic>> getAllBookmarks() {
    final list = <Map<String, dynamic>>[];
    for (var key in _bookmarksBox.keys) {
      final val = _bookmarksBox.get(key);
      if (val is Map) {
        list.add(Map<String, dynamic>.from(val));
      } else if (val is String) {
        try {
          list.add(jsonDecode(val) as Map<String, dynamic>);
        } catch (_) {}
      }
    }
    return list;
  }

  Future<void> saveBookmark(Map<String, dynamic> bookmark) async {
    final id = bookmark['id'] as String;
    await _bookmarksBox.put(id, bookmark);
  }

  Future<void> deleteBookmark(String id) async {
    await _bookmarksBox.delete(id);
  }

  bool isAyahBookmarked(int surahNumber, int ayahNumber) {
    for (var key in _bookmarksBox.keys) {
      final val = _bookmarksBox.get(key);
      if (val is Map) {
        if (val['surahNumber'] == surahNumber && val['ayahNumber'] == ayahNumber) {
          return true;
        }
      }
    }
    return false;
  }

  // ==================== Daily Goals ====================
  Map<String, dynamic> getDailyGoals() {
    final raw = _dailyGoalsBox.get('goals');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {
      'targetPages': 4,
      'todayPagesRead': 0,
      'targetMinutes': 20,
      'todayMinutesRead': 0,
      'streak': 1,
      'lastActiveDate': DateTime.now().toIso8601String().substring(0, 10),
    };
  }

  Future<void> saveDailyGoals(Map<String, dynamic> goals) async {
    await _dailyGoalsBox.put('goals', goals);
  }

  // ==================== Khatmah Plans ====================
  List<Map<String, dynamic>> getAllKhatmahPlans() {
    final list = <Map<String, dynamic>>[];
    for (var key in _khatmahBox.keys) {
      final val = _khatmahBox.get(key);
      if (val is Map) {
        list.add(Map<String, dynamic>.from(val));
      }
    }
    return list;
  }

  Future<void> saveKhatmahPlan(Map<String, dynamic> plan) async {
    final id = plan['id'] as String;
    await _khatmahBox.put(id, plan);
  }

  Future<void> deleteKhatmahPlan(String id) async {
    await _khatmahBox.delete(id);
  }

  // ==================== Memorization Plans ====================
  List<Map<String, dynamic>> getAllMemorizationPlans() {
    final list = <Map<String, dynamic>>[];
    for (var key in _memorizationBox.keys) {
      final val = _memorizationBox.get(key);
      if (val is Map) {
        list.add(Map<String, dynamic>.from(val));
      }
    }
    return list;
  }

  Future<void> saveMemorizationPlan(Map<String, dynamic> plan) async {
    final id = plan['id'] as String;
    await _memorizationBox.put(id, plan);
  }

  // ==================== Sync Queue ====================
  List<Map<String, dynamic>> getPendingSyncOperations() {
    final list = <Map<String, dynamic>>[];
    for (var key in _syncQueueBox.keys) {
      final val = _syncQueueBox.get(key);
      if (val is Map) {
        list.add(Map<String, dynamic>.from(val));
      }
    }
    return list;
  }

  Future<void> enqueueSyncOperation(Map<String, dynamic> op) async {
    final id = op['id'] as String;
    await _syncQueueBox.put(id, op);
  }

  Future<void> removeSyncOperation(String id) async {
    await _syncQueueBox.delete(id);
  }

  // ==================== Audio Downloads ====================
  List<Map<String, dynamic>> getAllAudioDownloads() {
    final list = <Map<String, dynamic>>[];
    for (var key in _audioDownloadsBox.keys) {
      final val = _audioDownloadsBox.get(key);
      if (val is Map) {
        list.add(Map<String, dynamic>.from(val));
      }
    }
    return list;
  }

  Future<void> saveAudioDownload(Map<String, dynamic> download) async {
    final id = download['id'] as String;
    await _audioDownloadsBox.put(id, download);
  }

  Future<void> deleteAudioDownload(String id) async {
    await _audioDownloadsBox.delete(id);
  }

  // ==================== App Settings ====================
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }
}

