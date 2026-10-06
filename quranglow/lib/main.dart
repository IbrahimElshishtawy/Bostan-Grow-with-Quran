import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/firebase_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/storage/cache_manager.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase & Firestore offline persistence
  await FirebaseService.initialize();

  // 2. Initialize SharedPreferences & Storage Services
  final prefs = await SharedPreferences.getInstance();
  final localStorageService = LocalStorageService(prefs);
  final cacheManager = CacheManager(prefs);

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorageService),
        cacheManagerProvider.overrideWithValue(cacheManager),
      ],
      child: const BostanApp(),
    ),
  );
}

class BostanApp extends ConsumerWidget {
  const BostanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
