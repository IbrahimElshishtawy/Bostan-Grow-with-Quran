import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:quranglow/core/api/api_cache_manager.dart';

/// Dio interceptor for error handling, caching, and retry logic
class ApiInterceptor extends Interceptor {
  ApiInterceptor({
    required this.cacheManager,
    this.maxRetries = 3,
    this.retryDelay = const Duration(milliseconds: 500),
  });

  final ApiCacheManager cacheManager;
  final int maxRetries;
  final Duration retryDelay;
  int _retryCount = 0;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add cache control headers
    options.headers['Cache-Control'] = 'max-age=3600';
    options.headers['Accept-Encoding'] = 'gzip, deflate';

    // Check cache for GET requests
    if (options.method == 'GET') {
      final cacheKey = _getCacheKey(options);
      final cachedResponse = cacheManager.get(cacheKey);

      if (cachedResponse != null) {
        try {
          // Verify the cache is actually valid JSON before delivering it
          final decoded = jsonDecode(cachedResponse);
          return handler.resolve(
            Response(
              requestOptions: options,
              data: decoded,
              statusCode: 200,
            ),
          );
        } catch (e) {
          // Corrupted cache! Remove it and let request flow through to network!
          cacheManager.remove(cacheKey);
        }
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Cache successful GET responses
    if (response.requestOptions.method == 'GET' &&
        response.statusCode == 200) {
      final cacheKey = _getCacheKey(response.requestOptions);
      await cacheManager.set(
        cacheKey,
        jsonEncode(response.data),
        ttl: const Duration(hours: 24),
      );
    }

    _retryCount = 0;
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Retry logic for network errors
    if (_shouldRetry(err) && _retryCount < maxRetries) {
      _retryCount++;
      await Future.delayed(retryDelay * _retryCount);

      try {
        final response = await Dio().request(
          err.requestOptions.path,
          options: Options(
            method: err.requestOptions.method,
            headers: err.requestOptions.headers,
          ),
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
        );
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    _retryCount = 0;
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.unknown ||
        (err.response?.statusCode ?? 0) >= 500;
  }

  String _getCacheKey(RequestOptions options) {
    return '${options.method}:${options.path}:${options.queryParameters}';
  }
}
