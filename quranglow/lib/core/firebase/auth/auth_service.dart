import 'dart:async';
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  FirebaseAuth get firebaseAuth => _auth;
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  Stream<AppAuthState> get authStateStream {
    return _auth.authStateChanges().map((user) {
      if (user == null) {
        return AppAuthState.unauthenticated();
      } else if (user.isAnonymous) {
        return AppAuthState.anonymous(user);
      } else {
        return AppAuthState.authenticated(user);
      }
    });
  }

  /// Ensure the user is signed in. Defaults to anonymous if no user exists.
  Future<User?> ensureAuthenticated() async {
    try {
      if (_auth.currentUser != null) {
        return _auth.currentUser;
      }
      final cred = await _auth.signInAnonymously();
      return cred.user;
    } catch (e, st) {
      dev.log('Error during ensureAuthenticated: $e', name: 'AuthService', error: e, stackTrace: st);
      return _auth.currentUser;
    }
  }

  /// Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Sign in with Email and Password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign up with Email and Password
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    // If user is currently anonymous, link their account so existing data is preserved!
    if (user != null && user.isAnonymous) {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      return await user.linkWithCredential(credential);
    }

    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Link current anonymous account with an AuthCredential (e.g. Google or Apple)
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No active user found to link.',
      );
    }
    return await user.linkWithCredential(credential);
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
