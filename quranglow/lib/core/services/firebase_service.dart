import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../firebase/firebase_gateway.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Cloud Firestore with Offline Persistence enabled
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      dev.log('Firebase and Firestore offline persistence initialized successfully', name: 'FirebaseService');

      // Initialize App Check (Section 48)
      try {
        await FirebaseGateway.initializeAppCheck();
      } catch (appCheckError) {
        dev.log('AppCheck init ignored/skipped: $appCheckError', name: 'FirebaseService');
      }
    } catch (e, stack) {
      dev.log('Firebase initialization error: $e', name: 'FirebaseService', error: e, stackTrace: stack);
    }
  }

  /// Ensure the user is signed in anonymously to get a stable, secure unique UID.
  /// If offline, returns existing user if present or waits/falls back.
  Future<User?> ensureAnonymousUser() async {
    try {
      User? currentUser = auth.currentUser;
      if (currentUser != null) {
        return currentUser;
      }
      final userCredential = await auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      dev.log('Anonymous sign-in error (offline or network): $e', name: 'FirebaseService');
      return auth.currentUser;
    }
  }
}
