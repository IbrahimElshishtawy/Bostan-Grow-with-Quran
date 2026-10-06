import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class ApiService {
  final Dio dio;

  ApiService({Dio? customDio})
      : dio = customDio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
        logPrint: (obj) => dev.log('$obj', name: 'DioClient'),
      ),
    ]);
  }

  // Generic HTTP methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // --- Specialized Islamic API Calls ---

  /// 1. Prayer Times by City & Country
  Future<Response> getPrayerTimesByCity({
    String city = 'cairo',
    String country = 'egypt',
    int method = 8,
  }) async {
    return await get(
      ApiEndpoints.prayerTimingsByCity,
      queryParameters: {
        'city': city,
        'country': country,
        'method': method,
      },
    );
  }

  /// 2. Holy Quran Surah Text (Alquran Cloud)
  Future<Response> getQuranSurah(int surahNumber) async {
    return await get('${ApiEndpoints.quranSurah}/$surahNumber');
  }

  /// 3. Quran Audio Recitation by Reciter & Chapter (Quran.com v4)
  Future<Response> getChapterRecitations(int reciterId) async {
    return await get('${ApiEndpoints.chapterRecitations}/$reciterId');
  }

  /// 4. Tafsir Moyassar for Surah (QuranEnc)
  Future<Response> getTafsirMoyassar(int surahNumber) async {
    return await get('${ApiEndpoints.tafsirMoyassarSurah}/$surahNumber');
  }

  /// 5. Hadiths Collection
  Future<Response> getHadiths({
    String book = 'abu-dawud',
    int page = 1,
    int limit = 100,
  }) async {
    return await get(
      '${ApiEndpoints.hadithPrimaryBaseUrl}/$book',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  /// 6. Azkar and Adhkar JSON
  Future<Response> getAzkar() async {
    return await get(ApiEndpoints.azkarJsonUrl);
  }

  /// 7. Holy Quran Radio Stations
  Future<Response> getRadioStations() async {
    return await get(ApiEndpoints.radioJsonUrl);
  }
}
