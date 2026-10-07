import 'dart:developer' as dev;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckService {
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // App check web if configured
        return;
      }

      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.deviceCheck,
      );

      dev.log('Firebase App Check activated successfully', name: 'AppCheckService');
    } catch (e) {
      dev.log('App Check initialization failed or skipped: $e', name: 'AppCheckService');
    }
  }
}
