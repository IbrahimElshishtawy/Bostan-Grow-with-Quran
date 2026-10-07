import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/bootstrap/app_bootstrap.dart';
import 'core/providers/core_providers.dart';

Future<void> main() async {
  final bootstrapResult = await AppBootstrap.init();

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(bootstrapResult.localStorageService),
        cacheManagerProvider.overrideWithValue(bootstrapResult.cacheManager),
      ],
      child: const BostanQuranApp(),
    ),
  );
}
