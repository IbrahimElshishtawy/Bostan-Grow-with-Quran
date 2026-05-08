/// Offline support and caching manager
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OfflineManager {
  OfflineManager({required this.boxName});

  final String boxName;
  late Box<dynamic> _offlineBox;
  final Connectivity _connectivity = Connectivity();

  Future<void> init() async {
    _offlineBox = await Hive.openBox<dynamic>(boxName);
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Cache data for offline use
  Future<void> cacheData(String key, dynamic data) async {
    try {
      await _offlineBox.put(key, data);
    } catch (e) {
      throw Exception('Failed to cache data: $e');
    }
  }

  /// Get cached data
  dynamic getCachedData(String key) {
    try {
      return _offlineBox.get(key);
    } catch (e) {
      return null;
    }
  }

  /// Check if data is cached
  bool isCached(String key) {
    return _offlineBox.containsKey(key);
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    try {
      await _offlineBox.delete(key);
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  /// Clear all offline data
  Future<void> clearAll() async {
    try {
      await _offlineBox.clear();
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }

  /// Get cache size
  int getCacheSize() {
    int size = 0;
    for (final value in _offlineBox.values) {
      if (value is String) {
        size += value.length;
      }
    }
    return size;
  }

  /// Stream connectivity changes
  Stream<bool> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}

class SyncManager {
  SyncManager({required this.offlineManager});

  final OfflineManager offlineManager;
  final List<SyncTask> _pendingTasks = [];

  /// Add task to sync queue
  void addSyncTask(SyncTask task) {
    _pendingTasks.add(task);
  }

  /// Sync pending tasks when online
  Future<void> syncPendingTasks() async {
    final isOnline = await offlineManager.isOnline();
    if (!isOnline) return;

    for (final task in _pendingTasks) {
      try {
        await task.execute();
        _pendingTasks.remove(task);
      } catch (e) {
        // Keep task in queue for retry
        continue;
      }
    }
  }

  /// Get pending tasks count
  int getPendingTasksCount() => _pendingTasks.length;

  /// Clear pending tasks
  void clearPendingTasks() {
    _pendingTasks.clear();
  }
}

abstract class SyncTask {
  Future<void> execute();
}

class DownloadManager {
  DownloadManager({required this.offlineManager});

  final OfflineManager offlineManager;
  final Map<String, DownloadProgress> _downloads = {};

  /// Start download
  Future<void> startDownload(
    String id,
    String url,
    String savePath, {
    Function(DownloadProgress)? onProgress,
  }) async {
    try {
      _downloads[id] = DownloadProgress(
        id: id,
        url: url,
        savePath: savePath,
        status: DownloadStatus.downloading,
      );

      // Simulate download progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        _downloads[id] = _downloads[id]!.copyWith(progress: i);
        onProgress?.call(_downloads[id]!);
      }

      _downloads[id] = _downloads[id]!.copyWith(
        status: DownloadStatus.completed,
      );

      // Cache download info
      await offlineManager.cacheData('download_$id', _downloads[id]);
    } catch (e) {
      _downloads[id] = _downloads[id]!.copyWith(
        status: DownloadStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Cancel download
  void cancelDownload(String id) {
    _downloads[id] = _downloads[id]!.copyWith(
      status: DownloadStatus.cancelled,
    );
  }

  /// Get download progress
  DownloadProgress? getDownloadProgress(String id) {
    return _downloads[id];
  }

  /// Get all downloads
  List<DownloadProgress> getAllDownloads() {
    return _downloads.values.toList();
  }

  /// Clear completed downloads
  void clearCompletedDownloads() {
    _downloads.removeWhere(
      (_, progress) => progress.status == DownloadStatus.completed,
    );
  }
}

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
}

class DownloadProgress {
  const DownloadProgress({
    required this.id,
    required this.url,
    required this.savePath,
    required this.status,
    this.progress = 0,
    this.error,
  });

  final String id;
  final String url;
  final String savePath;
  final DownloadStatus status;
  final int progress;
  final String? error;

  DownloadProgress copyWith({
    String? id,
    String? url,
    String? savePath,
    DownloadStatus? status,
    int? progress,
    String? error,
  }) {
    return DownloadProgress(
      id: id ?? this.id,
      url: url ?? this.url,
      savePath: savePath ?? this.savePath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}
