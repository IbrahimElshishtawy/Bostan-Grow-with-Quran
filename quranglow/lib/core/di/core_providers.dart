import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:quranglow/core/api/api_cache_manager.dart';
import 'package:quranglow/core/api/api_interceptor.dart';
import 'package:quranglow/core/api/fawaz_cdn_source.dart';
import 'package:quranglow/core/api/alquran_cloud_source.dart';
import 'package:quranglow/core/storage/local_storage.dart';
import 'package:quranglow/core/storage/hive_storage_impl.dart';
import 'package:quranglow/core/service/audio/my_audio_handler.dart';
import 'package:quranglow/core/service/audio/audio_service.dart';

final httpClientProvider = Provider<http.Client>((ref) => http.Client());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json', 'User-Agent': 'QuranGlow/1.0'},
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  // Add the universal caching interceptor for instant speed!
  final cacheManager = ApiCacheManager(boxName: 'api_cache');
  dio.interceptors.add(ApiInterceptor(cacheManager: cacheManager));

  return dio;
});

final storageProvider = Provider<LocalStorage>((ref) => HiveStorageImpl());

final fawazProvider = Provider<FawazCdnSource>((ref) {
  final client = ref.watch(httpClientProvider);
  final dio = ref.watch(dioProvider);
  return FawazCdnSource(client, dio);
});

final alQuranProvider = Provider<AlQuranCloudSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AlQuranCloudSource(dio: dio);
});

final audioHandlerProvider = Provider<MyAudioHandler>((ref) {
  return audioHandler;
});

final audioServiceProvider = Provider<MyAudioService>((ref) {
  return MyAudioService(ref.watch(audioHandlerProvider));
});
