import 'exceptions.dart';

abstract class Failure {
  final String message;
  final int? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;

  factory Failure.fromException(Object error) {
    if (error is ServerException) {
      return ServerFailure(error.message, error.statusCode);
    } else if (error is UnauthorizedException) {
      return UnauthorizedFailure(error.message);
    } else if (error is NetworkException) {
      return NetworkFailure(error.message);
    } else if (error is CacheException) {
      return CacheFailure(error.message);
    } else if (error is TimeoutAppException) {
      return TimeoutFailure(error.message);
    } else if (error is AuthException) {
      return AuthFailure(error.message);
    } else if (error is FormatParsingException) {
      return FormatFailure(error.message);
    }
    return UnknownFailure(error.toString());
  }
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ أثناء الاتصال بالخادم', int? code])
      : super(code: code);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'انتهت صلاحية الجلسة أو غير مصرح بالوصول']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'حدث خطأ في قراءة أو حفظ البيانات محلياً']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'يرجى التحقق من الاتصال بالإنترنت']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'انتهت مهلة انتظار الاستجابة']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'حدث خطأ في التحقق من المستخدم']);
}

class FormatFailure extends Failure {
  const FormatFailure([super.message = 'صيغة البيانات غير صحيحة']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'حدث خطأ غير متوقع']);
}
