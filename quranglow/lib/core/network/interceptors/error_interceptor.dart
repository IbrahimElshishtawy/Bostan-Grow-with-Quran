import 'package:dio/dio.dart';
import '../../error/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const TimeoutAppException('انتهت مهلة انتظار الاتصال، يرجى المحاولة لاحقاً');

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final responseData = err.response?.data;
        String errorMessage = 'حدث خطأ في الخادم ($statusCode)';

        if (responseData is Map && responseData['data'] is String) {
          errorMessage = responseData['data'];
        } else if (responseData is Map && responseData['message'] is String) {
          errorMessage = responseData['message'];
        }

        if (statusCode == 401 || statusCode == 403) {
          throw UnauthorizedException(errorMessage);
        } else {
          throw ServerException(errorMessage, statusCode);
        }

      case DioExceptionType.connectionError:
        throw const NetworkException('تعذر الاتصال بالخادم، يرجى التأكد من اتصال الإنترنت');

      case DioExceptionType.cancel:
        break;

      case DioExceptionType.badCertificate:
        throw const ServerException('شهادة أمان الخادم غير صالحة');

      case DioExceptionType.unknown:
        throw NetworkException(err.message ?? 'حدث خطأ في الشبكة غير معروف');
    }

    handler.next(err);
  }
}
