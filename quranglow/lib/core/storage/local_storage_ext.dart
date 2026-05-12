// lib/core/storage/local_storage_ext.dart
import 'dart:convert';
import 'package:quranglow/core/storage/local_storage.dart';

extension LocalStorageKV on LocalStorage {
  Future<void> setString(String key, String value) => write(key, value);

  Future<String?> getString(String key) async {
    final v = await read(key);
    if (v == null) return null;
    return v is String ? v : v.toString();
  }

  Future<void> setJson(String key, Object? value) =>
      write(key, jsonEncode(value));

  Future<T?> getJson<T>(String key) async {
    final raw = await read<String>(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded as T;
    } catch (_) {
      return null;
    }
  }
}
