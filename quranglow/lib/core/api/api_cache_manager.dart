import 'package:hive_flutter/hive_flutter.dart';

/// Smart caching strategy for API responses
class ApiCacheManager {
  ApiCacheManager({required this.boxName});

  final String boxName;
  late Box<String> _cache;

  Future<void> init() async {
    _cache = await Hive.openBox<String>(boxName);
  }

  /// Cache API response with TTL
  Future<void> set(
    String key,
    String value, {
    Duration ttl = const Duration(hours: 24),
  }) async {
    final expiryTime = DateTime.now().add(ttl).millisecondsSinceEpoch;
    final cacheData = '$value|$expiryTime';
    await _cache.put(key, cacheData);
  }

  /// Get cached value if not expired
  String? get(String key) {
    final cached = _cache.get(key);
    if (cached == null) return null;

    final parts = cached.split('|');
    if (parts.length != 2) return null;

    final expiryTime = int.tryParse(parts[1]);
    if (expiryTime == null) return null;

    if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
      _cache.delete(key);
      return null;
    }

    return parts[0];
  }

  /// Check if key exists and is not expired
  bool has(String key) => get(key) != null;

  /// Clear specific cache entry
  Future<void> remove(String key) => _cache.delete(key);

  /// Clear all cache
  Future<void> clear() => _cache.clear();

  /// Get cache size in bytes
  int getSize() {
    int size = 0;
    for (final value in _cache.values) {
      size += value.length;
    }
    return size;
  }

  /// Clear cache if size exceeds limit (in MB)
  Future<void> clearIfExceedsLimit(int limitMB) async {
    final limitBytes = limitMB * 1024 * 1024;
    if (getSize() > limitBytes) {
      await clear();
    }
  }
}
