// ignore_for_file: unused_element

import 'dart:convert';
import 'package:flutter/foundation.dart' as foundation;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:quranglow/core/model/prayer/prayer_times_data.dart';
import 'package:quranglow/core/service/setting/location_service.dart';
import 'package:quranglow/core/storage/local_storage.dart';

class PrayerTimesService {
  PrayerTimesService({
    required this.client,
    required this.locationService,
    required this.storage,
  });

  final http.Client client;
  final LocationService locationService;
  final LocalStorage storage;

  static const _baseHost = 'api.aladhan.com';
  static const _cacheKey = 'prayer_times.cache.v1';
  static const _maxCacheDistanceMeters = 50000.0;
  static const _defaultScheduleDays = 30;
  static const _prayerKeys = <String>[
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  Future<PrayerTimesData> fetchForToday() async {
    final days = await fetchUpcomingDays(days: 2);
    if (days.isEmpty) {
      throw Exception('تعذر تجهيز مواقيت الصلاة.');
    }

    final today = days.first;
    final tomorrow = days.length > 1 ? days[1] : null;
    final now = DateTime.now();
    final next = _findNextPrayer(today.prayers, tomorrow?.prayers, now);

    return PrayerTimesData(
      timezone: today.timezone,
      methodName: today.methodName,
      prayers: today.prayers,
      nextPrayerName: next.$1,
      nextPrayerTime: next.$2,
    );
  }

  Future<List<PrayerScheduleDay>> fetchUpcomingDays({
    int days = _defaultScheduleDays,
    bool preferCache = false,
    bool allowNetwork = true,
  }) async {
    await storage.init();

    final normalizedNow = _normalizeDate(DateTime.now());
    final requestedDays = days < 1 ? 1 : days;
    final cachedBundle = await _readCacheBundle();

    if (preferCache) {
      final cachedDays = _collectCachedDays(
        bundle: cachedBundle,
        startDate: normalizedNow,
        requestedDays: requestedDays,
      );
      if (cachedDays.isNotEmpty) {
        return cachedDays;
      }
    }

    if (!allowNetwork) {
      final cachedDays = _collectCachedDays(
        bundle: cachedBundle,
        startDate: normalizedNow,
        requestedDays: requestedDays,
      );
      if (cachedDays.isNotEmpty) {
        return cachedDays;
      }
      throw Exception('لا توجد مواقيت محفوظة كافية للتشغيل الأوفلاين.');
    }

    final currentPosition = await locationService.getCurrentOnce();
    final cachedPosition = _positionFromCache(cachedBundle);
    final effectivePosition = currentPosition ?? cachedPosition;

    if (effectivePosition == null) {
      throw Exception(
        'تعذر الوصول إلى الموقع. فعّل خدمة الموقع مرة واحدة على الأقل ليتم حفظ المواقيت وتشغيلها أوفلاين.',
      );
    }

    try {
      // ✨ HARDENED FIX: Use month calendar to avoid 429 Too Many Requests
      final monthDays = await _fetchMonth(
        effectivePosition,
        normalizedNow.year,
        normalizedNow.month,
      );

      // If requested days span across next month, we might need another fetch,
      // but for now 1 month is usually enough and much safer.
      final onlineDays = monthDays.where((d) {
        final date = _dateFromKey(d.dateKey);
        return !date.isBefore(normalizedNow);
      }).toList();

      await _writeCacheBundle(position: effectivePosition, days: onlineDays);
      return onlineDays.map(_toScheduleDay).toList(growable: false);
    } catch (e) {
      foundation.debugPrint('[PRAYER] Online fetch failed: $e');
      if (!_canUseCache(currentPosition, cachedPosition)) {
        throw Exception(
          'المواقيت المحفوظة تخص موقعًا مختلفًا. اتصل بالإنترنت مرة واحدة في موقعك الحالي لتحديث المواقيت.',
        );
      }

      final cachedDays = _collectCachedDays(
        bundle: cachedBundle,
        startDate: normalizedNow,
        requestedDays: requestedDays,
      );

      if (cachedDays.isEmpty) {
        throw Exception(
          'لا توجد مواقيت محفوظة قادمة. افتح التطبيق مرة واحدة أثناء الاتصال بالإنترنت لتجهيز الجدول المحلي.',
        );
      }

      return cachedDays;
    }
  }

  // Removed _fetchDay as it is replaced by _fetchMonth

  Future<List<_PrayerDay>> _fetchMonth(
    Position position,
    int year,
    int month,
  ) async {
    final uri = Uri.https(_baseHost, '/v1/calendar', {
      'latitude': position.latitude.toStringAsFixed(6),
      'longitude': position.longitude.toStringAsFixed(6),
      'method': '5',
      'school': '0',
      'latitudeAdjustmentMethod': '3',
      'midnightMode': '1',
      'iso8601': 'true',
      'year': year.toString(),
      'month': month.toString(),
    });

    final res = await client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('فشل جلب جدول المواقيت (${res.statusCode}).');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final dataList = decoded['data'] as List<dynamic>?;
    if (dataList == null) {
      throw Exception('الاستجابة لا تحتوي بيانات جدول.');
    }

    final results = <_PrayerDay>[];
    for (final dayData in dataList) {
      final meta = dayData['meta'] as Map<String, dynamic>?;
      final timingsRaw = dayData['timings'] as Map<String, dynamic>?;
      final dateRaw = dayData['date']?['gregorian']?['date'] as String?;

      if (timingsRaw == null || dateRaw == null) continue;

      // Aladhan calendar returns date as "DD-MM-YYYY"
      final parts = dateRaw.split('-');
      if (parts.length != 3) continue;
      final d = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final y = int.parse(parts[2]);
      final date = DateTime(y, m, d);

      results.add(
        _PrayerDay(
          dateKey: _dateKey(date),
          timezone: (meta?['timezone'] ?? '') as String,
          methodName:
              (meta?['method']?['name'] ?? 'المعيار الافتراضي') as String,
          prayers: _parseTimings(timingsRaw, date),
        ),
      );
    }

    return results;
  }

  Map<String, DateTime> _parseTimings(dynamic rawTimings, DateTime date) {
    if (rawTimings is! Map<String, dynamic>) {
      throw Exception('تنسيق مواقيت الصلاة غير صالح.');
    }

    final parsed = <String, DateTime>{};
    for (final key in _prayerKeys) {
      final raw = (rawTimings[key] ?? '').toString();
      final clean = _normalizeTime(raw);
      final parts = clean.split(':');
      if (parts.length != 2) continue;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) continue;
      parsed[key] = DateTime(date.year, date.month, date.day, h, m);
    }

    if (parsed.length < 5) {
      throw Exception('تعذر قراءة مواقيت اليوم بشكل صحيح.');
    }
    return parsed;
  }

  (String, DateTime) _findNextPrayer(
    Map<String, DateTime> today,
    Map<String, DateTime>? tomorrow,
    DateTime now,
  ) {
    const order = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    for (final key in order) {
      final t = today[key];
      if (t != null && t.isAfter(now)) return (key, t);
    }

    final nextFajr = tomorrow?['Fajr'];
    if (nextFajr != null) return ('Fajr', nextFajr);

    throw Exception(
      'تعذر تحديد الصلاة القادمة من الكاش. افتح التطبيق مرة واحدة أونلاين لتحديث مواقيت الغد.',
    );
  }

  Future<Map<String, dynamic>?> _readCacheBundle() async {
    final raw = await storage.read<dynamic>(_cacheKey);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw.cast<String, dynamic>());
    }
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded.cast<String, dynamic>());
      }
    }
    return null;
  }

  Future<void> _writeCacheBundle({
    required Position position,
    required List<_PrayerDay> days,
  }) async {
    final dayMaps = <String, dynamic>{};
    for (final day in days) {
      dayMaps[day.dateKey] = day.toJson();
    }

    await storage.write(_cacheKey, <String, dynamic>{
      'lat': position.latitude,
      'lon': position.longitude,
      'savedAt': DateTime.now().toIso8601String(),
      'days': dayMaps,
    });
  }

  List<PrayerScheduleDay> _collectCachedDays({
    required Map<String, dynamic>? bundle,
    required DateTime startDate,
    required int requestedDays,
  }) {
    final cachedDays = <PrayerScheduleDay>[];
    for (var offset = 0; offset < requestedDays; offset++) {
      final date = startDate.add(Duration(days: offset));
      final cachedDay = _readCachedDay(bundle, _dateKey(date));
      if (cachedDay == null) continue;
      cachedDays.add(_toScheduleDay(cachedDay));
    }
    return cachedDays;
  }

  _PrayerDay? _readCachedDay(Map<String, dynamic>? bundle, String dateKey) {
    final days = bundle?['days'];
    if (days is! Map) return null;
    final raw = days[dateKey];
    if (raw is! Map) return null;
    return _PrayerDay.fromJson(
      Map<String, dynamic>.from(raw.cast<String, dynamic>()),
    );
  }

  Position? _positionFromCache(Map<String, dynamic>? bundle) {
    if (bundle == null) return null;
    final lat = (bundle['lat'] as num?)?.toDouble();
    final lon = (bundle['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    return Position(
      longitude: lon,
      latitude: lat,
      timestamp:
          DateTime.tryParse((bundle['savedAt'] ?? '').toString()) ??
          DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  bool _canUseCache(Position? currentPosition, Position? cachedPosition) {
    if (cachedPosition == null) return false;
    if (currentPosition == null) return true;
    final distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      cachedPosition.latitude,
      cachedPosition.longitude,
    );
    return distance <= _maxCacheDistanceMeters;
  }

  PrayerScheduleDay _toScheduleDay(_PrayerDay day) {
    return PrayerScheduleDay(
      date: _dateFromKey(day.dateKey),
      timezone: day.timezone,
      methodName: day.methodName,
      prayers: day.prayers,
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _dateFromKey(String dateKey) {
    return DateTime.tryParse(dateKey) ?? DateTime.now();
  }

  String _normalizeTime(String raw) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) return raw;
    final hh = int.parse(match.group(1)!);
    final mm = int.parse(match.group(2)!);
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }
}

class _PrayerDay {
  const _PrayerDay({
    required this.dateKey,
    required this.timezone,
    required this.methodName,
    required this.prayers,
  });

  final String dateKey;
  final String timezone;
  final String methodName;
  final Map<String, DateTime> prayers;

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey,
    'timezone': timezone,
    'methodName': methodName,
    'prayers': prayers.map(
      (key, value) => MapEntry(key, value.toIso8601String()),
    ),
  };

  factory _PrayerDay.fromJson(Map<String, dynamic> json) {
    final rawPrayers = json['prayers'];
    final prayers = <String, DateTime>{};
    if (rawPrayers is Map) {
      for (final entry in rawPrayers.entries) {
        final key = entry.key.toString();
        final value = DateTime.tryParse(entry.value.toString());
        if (value != null) {
          prayers[key] = value;
        }
      }
    }

    return _PrayerDay(
      dateKey: (json['dateKey'] ?? '').toString(),
      timezone: (json['timezone'] ?? '').toString(),
      methodName: (json['methodName'] ?? '').toString(),
      prayers: prayers,
    );
  }
}
