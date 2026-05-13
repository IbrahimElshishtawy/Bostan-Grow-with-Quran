import 'package:hive_flutter/hive_flutter.dart';

/// Smart caching strategy for API responses
class ApiCacheManager {
  ApiCacheManager({required this.boxName});

  final String boxName;

  Future<Box<String>> _getOrOpenBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<String>(boxName);
    }
    return await Hive.openBox<String>(boxName);
  }

  Box<String>? _getBoxIfOpen() {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<String>(boxName);
    }
    return null;
  }

  Future<void> init() async {
    await _getOrOpenBox();
  }

  /// Cache API response with TTL
  Future<void> set(
    String key,
    String value, {
    Duration ttl = const Duration(hours: 24),
  }) async {
    try {
      final box = await _getOrOpenBox();
      final expiryTime = DateTime.now().add(ttl).millisecondsSinceEpoch;
      final cacheData = '$value|$expiryTime';
      await box.put(key, cacheData);
    } catch (_) {
      // Fail gracefully on edge case storage locking
    }
  }

  /// Get cached value if not expired
  String? get(String key) {
    final box = _getBoxIfOpen();
    if (box == null) return null; // Return null gracefully if storage not ready yet!

    final cached = box.get(key);
    if (cached == null) return null;

    final parts = cached.split('|');
    if (parts.length != 2) return null;

    final expiryTime = int.tryParse(parts[1]);
    if (expiryTime == null) return null;

    if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
      box.delete(key);
      return null;
    }

    return parts[0];
  }

  /// Check if key exists and is not expired
  bool has(String key) => get(key) != null;

  /// Clear specific cache entry
  Future<void> remove(String key) async {
    final box = await _getOrOpenBox();
    await box.delete(key);
  }

  /// Clear all cache
  Future<void> clear() async {
    final box = await _getOrOpenBox();
    await box.clear();
  }

  /// Get cache size in bytes
  int getSize() {
    final box = _getBoxIfOpen();
    if (box == null) return 0;
    
    int size = 0;
    for (final value in box.values) {
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

