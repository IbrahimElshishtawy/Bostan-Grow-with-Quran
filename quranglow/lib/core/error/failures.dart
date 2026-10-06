abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ أثناء الاتصال بالخادم']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'حدث خطأ في قراءة أو كتابة البيانات المحفوظة']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'يرجى التحقق من الاتصال بالإنترنت']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'حدث خطأ في التحقق من المستخدم']);
}
