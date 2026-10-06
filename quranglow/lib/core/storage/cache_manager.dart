import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum CachePolicy {
  cacheFirst,
  networkFirst,
  cacheOnly,
  networkOnly,
}

class CacheManager {
  final SharedPreferences _prefs;
  final Map<String, dynamic> _memoryCache = {};

  CacheManager(this._prefs);

  /// Saves data to cache with optional TTL in hours (default 24 hours)
  Future<void> set(String key, dynamic data, {Duration ttl = const Duration(hours: 24)}) async {
    final expiryTime = DateTime.now().add(ttl).millisecondsSinceEpoch;
    final payload = {
      'expiry': expiryTime,
      'data': data,
    };
    final jsonString = jsonEncode(payload);

    _memoryCache[key] = payload;
    await _prefs.setString('cache_$key', jsonString);
  }

  /// Gets data from cache if not expired
  dynamic get(String key) {
    // 1. Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final item = _memoryCache[key];
      final expiry = item['expiry'] as int?;
      if (expiry != null && DateTime.now().millisecondsSinceEpoch < expiry) {
        return item['data'];
      } else {
        _memoryCache.remove(key);
      }
    }

    // 2. Check disk cache (SharedPreferences)
    final stored = _prefs.getString('cache_$key');
    if (stored != null) {
      try {
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        final expiry = decoded['expiry'] as int?;
        if (expiry != null && DateTime.now().millisecondsSinceEpoch < expiry) {
          _memoryCache[key] = decoded;
          return decoded['data'];
        } else {
          _prefs.remove('cache_$key');
        }
      } catch (_) {
        _prefs.remove('cache_$key');
      }
    }

    return null;
  }

  /// Invalidate specific cache key
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _prefs.remove('cache_$key');
  }

  /// Clear all cached network responses
  Future<void> clearNetworkCache() async {
    _memoryCache.clear();
    final keys = _prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
