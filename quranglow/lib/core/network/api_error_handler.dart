/// Retry logic with exponential backoff for API calls
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 32),
    this.backoffMultiplier = 2.0,
  });
}

/// Retry helper for API calls with exponential backoff
Future<T> retryWithBackoff<T>({
  required Future<T> Function() operation,
  required RetryConfig config,
}) async {
  int attempt = 0;
  Duration delay = config.initialDelay;

  while (true) {
    try {
      return await operation();
    } catch (error) {
      attempt++;

      if (attempt >= config.maxAttempts) {
        rethrow;
      }

      // Calculate delay with exponential backoff
      delay = Duration(
        milliseconds: (delay.inMilliseconds * config.backoffMultiplier).toInt(),
      );

      // Cap delay at maxDelay
      if (delay > config.maxDelay) {
        delay = config.maxDelay;
      }

      // Wait before retrying
      await Future.delayed(delay);
    }
  }
}

/// Graceful fallback handler
class ApiFallback<T> {
  final Future<T> Function() primary;
  final Future<T> Function() fallback;

  ApiFallback({required this.primary, required this.fallback});

  Future<T> execute() async {
    try {
      return await primary();
    } catch (e) {
      // Fallback to secondary source
      return await fallback();
    }
  }
}

/// API error classification
enum ApiErrorType {
  networkError,
  timeoutError,
  serverError,
  validationError,
  authenticationError,
  unknownError,
}

class ApiError implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiError({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;

  bool get isRetryable {
    return type == ApiErrorType.networkError ||
        type == ApiErrorType.timeoutError ||
        (type == ApiErrorType.serverError &&
            statusCode != null &&
            statusCode! >= 500);
  }

  bool get isAuthError => type == ApiErrorType.authenticationError;
}
