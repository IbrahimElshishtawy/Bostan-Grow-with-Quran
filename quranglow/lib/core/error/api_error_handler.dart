// ignore_for_file: dangling_library_doc_comments

/// API error handling and mapping
import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.originalException,
  });

  final String message;
  final int? statusCode;
  final Exception? originalException;

  @override
  String toString() => message;
}

class ApiErrorHandler {
  static ApiException handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is Exception) {
      return ApiException(message: error.toString(), originalException: error);
    }

    return ApiException(message: 'An unknown error occurred');
  }

  static ApiException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: error.response?.statusCode,
          originalException: error,
        );

      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Request timeout. Please try again.',
          statusCode: error.response?.statusCode,
          originalException: error,
        );

      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Response timeout. Please try again.',
          statusCode: error.response?.statusCode,
          originalException: error,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          originalException: error,
        );

      case DioExceptionType.unknown:
        return ApiException(
          message: 'Network error. Please check your connection.',
          originalException: error,
        );

      default:
        return ApiException(
          message: 'An error occurred: ${error.message}',
          originalException: error,
        );
    }
  }

  static ApiException _handleBadResponse(Response? response) {
    if (response == null) {
      return ApiException(message: 'No response from server');
    }

    final statusCode = response.statusCode ?? 0;
    final message = _getErrorMessage(statusCode, response.data);

    return ApiException(message: message, statusCode: statusCode);
  }

  static String _getErrorMessage(int statusCode, dynamic responseData) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        if (responseData is Map<String, dynamic>) {
          return responseData['message'] as String? ?? 'Error: $statusCode';
        }
        return 'Error: $statusCode';
    }
  }
}

class RetryMechanism {
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    int retryCount = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;

        if (retryCount >= maxRetries) {
          rethrow;
        }

        await Future.delayed(delay * retryCount);
      }
    }
  }
}
