import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/setting/reader_settings.dart';
import 'package:quranglow/core/theme/app_themes.dart';
import 'package:quranglow/core/theme/theme_controller.dart';
import 'package:quranglow/core/widgets/error_boundary.dart';
import 'package:quranglow/core/widgets/restart_app.dart';
import 'package:quranglow/features/splash/presentation/pages/splash_screen.dart';
import 'package:quranglow/features/ui/routes/app_router.dart';

class QuranGlowApp extends ConsumerWidget {
  const QuranGlowApp({super.key});

  static final _delegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const _locales = <Locale>[Locale('en'), Locale('ar')];

  ThemeData _getTheme(AppSettings settings, bool isDark) {
    if (isDark) {
      return buildDarkTheme(
        fontFamily: settings.fontFamily,
        fontScale: settings.fontScale,
      );
    }

    switch (settings.colorScheme) {
      case AppColorScheme.sepia:
        return buildSepiaTheme(
          fontFamily: settings.fontFamily,
          fontScale: settings.fontScale,
        );
      case AppColorScheme.blue:
        return buildBlueTheme(
          fontFamily: settings.fontFamily,
          fontScale: settings.fontScale,
        );
      case AppColorScheme.green:
        return buildLightTheme(
          fontFamily: settings.fontFamily,
          fontScale: settings.fontScale,
        );
    }

    // ignore: dead_code
    return buildLightTheme(
      fontFamily: settings.fontFamily,
      fontScale: settings.fontScale,
    );
  }

  MaterialApp _buildApp({
    required ThemeData theme,
    required ThemeData darkTheme,
    required Widget home,
    ThemeMode? themeMode,
    RouteFactory? onGenerateRoute,
  }) {
    return MaterialApp(
      title: 'بُستان',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      localizationsDelegates: _delegates,
      supportedLocales: _locales,
      onGenerateRoute: onGenerateRoute,
      builder: (context, child) =>
          GlobalErrorBoundary(child: child ?? const SizedBox.shrink()),
      home: home,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return settings.when(
      loading: () => _buildApp(
        theme: buildLightTheme(fontFamily: 'System', fontScale: 1),
        darkTheme: buildDarkTheme(fontFamily: 'System', fontScale: 1),
        home: const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => _buildApp(
        theme: buildLightTheme(fontFamily: 'System', fontScale: 1),
        darkTheme: buildDarkTheme(fontFamily: 'System', fontScale: 1),
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('حدث خطأ في تحميل الإعدادات'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => RestartApp.restartApp(context),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (settings) => _buildApp(
        theme: _getTheme(settings, false),
        darkTheme: _getTheme(settings, true),
        themeMode: settings.themeMode,
        onGenerateRoute: onGenerateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}
