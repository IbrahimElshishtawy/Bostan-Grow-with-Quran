import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firebase_service.dart';
import '../../core/storage/cache_manager.dart';
import '../../core/storage/local_database.dart';
import '../../core/services/local_storage_service.dart';

class BootstrapResult {
  final LocalStorageService localStorageService;
  final CacheManager cacheManager;

  const BootstrapResult({
    required this.localStorageService,
    required this.cacheManager,
  });
}

class AppBootstrap {
  AppBootstrap._();

  static Future<BootstrapResult> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize Firebase, Firestore Persistence, App Check
    await FirebaseService.initialize();

    // 2. Initialize Local Storage (Hive)
    await LocalDatabase.instance.init();

    // 3. SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final localStorageService = LocalStorageService(prefs);
    final cacheManager = CacheManager(prefs);

    return BootstrapResult(
      localStorageService: localStorageService,
      cacheManager: cacheManager,
    );
  }
}
