import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthInterceptor extends Interceptor {
  final FirebaseAuth? _firebaseAuth;

  AuthInterceptor({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';
    options.headers['Accept-Language'] = 'ar';

    // If there's an active Firebase user, we can attach their ID token for authenticated endpoints
    try {
      final user = _firebaseAuth?.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {
      // Continue without token if anonymous or offline
    }

    handler.next(options);
  }
}
