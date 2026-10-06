// File generated for Firebase options matching android/app/google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBiYiSrCUNOXa3OBUSrsLA8wFsAXOC76y0',
    appId: '1:382659412362:android:95775f621567a215804873',
    messagingSenderId: '382659412362',
    projectId: 'quran-glow',
    storageBucket: 'quran-glow.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBiYiSrCUNOXa3OBUSrsLA8wFsAXOC76y0',
    appId: '1:382659412362:ios:95775f621567a215804873',
    messagingSenderId: '382659412362',
    projectId: 'quran-glow',
    storageBucket: 'quran-glow.firebasestorage.app',
    iosBundleId: 'com.example.quranglow',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBiYiSrCUNOXa3OBUSrsLA8wFsAXOC76y0',
    appId: '1:382659412362:web:95775f621567a215804873',
    messagingSenderId: '382659412362',
    projectId: 'quran-glow',
    storageBucket: 'quran-glow.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBiYiSrCUNOXa3OBUSrsLA8wFsAXOC76y0',
    appId: '1:382659412362:ios:95775f621567a215804873',
    messagingSenderId: '382659412362',
    projectId: 'quran-glow',
    storageBucket: 'quran-glow.firebasestorage.app',
    iosBundleId: 'com.example.quranglow',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBiYiSrCUNOXa3OBUSrsLA8wFsAXOC76y0',
    appId: '1:382659412362:web:95775f621567a215804873',
    messagingSenderId: '382659412362',
    projectId: 'quran-glow',
    storageBucket: 'quran-glow.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyBiYiSrCUNOXa3OBUSrsLA8wFsAXOC76y0',
    appId: '1:382659412362:web:95775f621567a215804873',
    messagingSenderId: '382659412362',
    projectId: 'quran-glow',
    storageBucket: 'quran-glow.firebasestorage.app',
  );
}
