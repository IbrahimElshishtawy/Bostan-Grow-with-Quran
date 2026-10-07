import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  initial,
  loading,
  anonymous,
  authenticated,
  unauthenticated,
  error,
}

class AppAuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AppAuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AppAuthState.initial() => const AppAuthState(status: AuthStatus.initial);
  factory AppAuthState.loading() => const AppAuthState(status: AuthStatus.loading);
  factory AppAuthState.anonymous(User user) => AppAuthState(status: AuthStatus.anonymous, user: user);
  factory AppAuthState.authenticated(User user) => AppAuthState(status: AuthStatus.authenticated, user: user);
  factory AppAuthState.unauthenticated() => const AppAuthState(status: AuthStatus.unauthenticated);
  factory AppAuthState.error(String message) => AppAuthState(status: AuthStatus.error, errorMessage: message);

  bool get isAnonymous => user?.isAnonymous ?? false;
  bool get isSignedIn => user != null;
  String? get uid => user?.uid;
}
