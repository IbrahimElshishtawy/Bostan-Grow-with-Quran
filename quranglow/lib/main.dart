// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/Quran_Glow_App.dart';
import 'package:quranglow/core/app/app_bootstrap.dart';
import 'package:quranglow/core/app/app_bootstrap_scope.dart';
import 'package:quranglow/core/widgets/restart_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SplashBootstrap.initBinding();
  await AppBootstrap.initialize();
  runApp(
    const RestartApp(
      child: ProviderScope(child: AppBootstrapScope(child: QuranGlowApp())),
    ),
  );
  SplashBootstrap.removeSplash();
}
