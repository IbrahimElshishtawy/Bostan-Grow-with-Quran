/// Enterprise-level error handling and logging
import 'package:flutter/foundation.dart';

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

class AppError {
  AppError({
    required this.message,
    required this.code,
    required this.severity,
    this.stackTrace,
    this.originalException,
    this.context,
  });

  final String message;
  final String code;
  final ErrorSeverity severity;
  final StackTrace? stackTrace;
  final Exception? originalException;
  final Map<String, dynamic>? context;

  String get userMessage => _getUserMessage();
  String get displayMessage => _getDisplayMessage();

  String _getUserMessage() {
    switch (code) {
      case 'network_error':
        return 'Unable to connect. Please check your internet connection.';
      case 'timeout':
        return 'Request timed out. Please try again.';
      case 'not_found':
        return 'The requested resource was not found.';
      case 'unauthorized':
        return 'You are not authorized to perform this action.';
      case 'server_error':
        return 'Server error. Please try again later.';
      case 'location_error':
        return 'Unable to get your location. Please enable location services.';
      case 'compass_error':
        return 'Compass sensor not available on this device.';
      case 'notification_error':
        return 'Unable to send notification. Please check permissions.';
      case 'audio_error':
        return 'Audio playback error. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  String _getDisplayMessage() {
    if (kDebugMode) {
      return '$message\nCode: $code\n${stackTrace ?? ''}';
    }
    return userMessage;
  }

  @override
  String toString() => 'AppError($code): $message';
}

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();

  factory ErrorHandler() {
    return _instance;
  }

  ErrorHandler._internal();

  final List<AppError> _errorLog = [];
  final List<ErrorListener> _listeners = [];

  /// Handle error and notify listeners
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? code,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? context,
  }) {
    final appError = _parseError(
      error,
      stackTrace: stackTrace,
      code: code,
      severity: severity,
      context: context,
    );

    _errorLog.add(appError);
    _notifyListeners(appError);

    if (kDebugMode) {
      debugPrint('ERROR: ${appError.displayMessage}');
    }
  }

  /// Parse error into AppError
  AppError _parseError(
    dynamic error, {
    StackTrace? stackTrace,
    String? code,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? context,
  }) {
    if (error is AppError) {
      return error;
    }

    String message = error.toString();
    String errorCode = code ?? 'unknown_error';

    if (error is Exception) {
      message = error.toString();
      if (message.contains('SocketException')) {
        errorCode = 'network_error';
      } else if (message.contains('TimeoutException')) {
        errorCode = 'timeout';
      } else if (message.contains('404')) {
        errorCode = 'not_found';
      } else if (message.contains('401')) {
        errorCode = 'unauthorized';
      } else if (message.contains('500')) {
        errorCode = 'server_error';
      }
    }

    return AppError(
      message: message,
      code: errorCode,
      severity: severity,
      stackTrace: stackTrace,
      originalException: error is Exception ? error : null,
      context: context,
    );
  }

  /// Add error listener
  void addListener(ErrorListener listener) {
    _listeners.add(listener);
  }

  /// Remove error listener
  void removeListener(ErrorListener listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  void _notifyListeners(AppError error) {
    for (final listener in _listeners) {
      listener.onError(error);
    }
  }

  /// Get error log
  List<AppError> getErrorLog() => List.unmodifiable(_errorLog);

  /// Clear error log
  void clearErrorLog() {
    _errorLog.clear();
  }

  /// Get recent errors
  List<AppError> getRecentErrors({int limit = 10}) {
    return _errorLog.length > limit
        ? _errorLog.sublist(_errorLog.length - limit)
        : _errorLog;
  }
}

abstract class ErrorListener {
  void onError(AppError error);
}

class SilentErrorRecovery {
  /// Attempt to recover from error silently
  static Future<T?> tryRecover<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          return fallbackValue;
        }
        await Future.delayed(retryDelay * retryCount);
      }
    }

    return fallbackValue;
  }

  /// Try operation with fallback
  static T tryOrDefault<T>(
    T Function() operation,
    T defaultValue,
  ) {
    try {
      return operation();
    } catch (e) {
      return defaultValue;
    }
  }
}

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();

  factory LoggingService() {
    return _instance;
  }

  LoggingService._internal();

  final List<LogEntry> _logs = [];

  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Map<String, dynamic>? data,
  }) {
    final entry = LogEntry(
      message: message,
      level: level,
      tag: tag,
      timestamp: DateTime.now(),
      data: data,
    );

    _logs.add(entry);

    if (kDebugMode) {
      debugPrint('[${entry.level.name.toUpperCase()}] ${entry.tag ?? 'APP'}: $message');
      if (data != null) {
        debugPrint('Data: $data');
      }
    }
  }

  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.info, tag: tag, data: data);
  }

  void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.warning, tag: tag, data: data);
  }

  void error(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.error, tag: tag, data: data);
  }

  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.debug, tag: tag, data: data);
  }

  List<LogEntry> getLogs({LogLevel? level}) {
    if (level == null) {
      return List.unmodifiable(_logs);
    }
    return _logs.where((log) => log.level == level).toList();
  }

  void clearLogs() {
    _logs.clear();
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LogEntry {
  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
    this.tag,
    this.data,
  });

  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final String? tag;
  final Map<String, dynamic>? data;

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] ${level.name.toUpperCase()} ${tag ?? 'APP'}: $message';
}
