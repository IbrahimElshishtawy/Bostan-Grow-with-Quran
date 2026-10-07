enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  final Environment environment;
  final String appName;
  final String quranApiBaseUrl;
  final String tafsirApiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableVerboseLogging;
  final bool enableCrashlytics;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.quranApiBaseUrl,
    required this.tafsirApiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.enableVerboseLogging,
    required this.enableCrashlytics,
  });

  static AppConfig current = development;

  static const AppConfig development = AppConfig(
    environment: Environment.development,
    appName: 'بستان (تطوير)',
    quranApiBaseUrl: 'https://api.quran.com/api/v4/',
    tafsirApiBaseUrl: 'https://api.quran.com/api/v4/tafsirs/',
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
    enableVerboseLogging: true,
    enableCrashlytics: false,
  );

  static const AppConfig production = AppConfig(
    environment: Environment.production,
    appName: 'بستان - ارتقِ مع القرآن',
    quranApiBaseUrl: 'https://api.quran.com/api/v4/',
    tafsirApiBaseUrl: 'https://api.quran.com/api/v4/tafsirs/',
    connectTimeout: Duration(seconds: 20),
    receiveTimeout: Duration(seconds: 20),
    enableVerboseLogging: false,
    enableCrashlytics: true,
  );
}
