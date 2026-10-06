class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException([this.message = 'حدث خطأ في استجابة الخادم', this.statusCode]);

  @override
  String toString() => 'ServerException(statusCode: $statusCode, message: $message)';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'انتهت صلاحية الجلسة أو غير مصرح بالدخول']);

  @override
  String toString() => 'UnauthorizedException($message)';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'حدث خطأ في الذاكرة التخزينية']);

  @override
  String toString() => 'CacheException($message)';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'لا يوجد اتصال بالإنترنت']);

  @override
  String toString() => 'NetworkException($message)';
}

class TimeoutAppException implements Exception {
  final String message;
  const TimeoutAppException([this.message = 'استغرق الاتصال وقتاً أطول من المتوقع']);

  @override
  String toString() => 'TimeoutAppException($message)';
}

class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException([this.message = 'حدث خطأ أثناء المصادقة', this.code]);

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

class FormatParsingException implements Exception {
  final String message;
  const FormatParsingException([this.message = 'حدث خطأ في معالجة صيغة البيانات']);

  @override
  String toString() => 'FormatParsingException($message)';
}
