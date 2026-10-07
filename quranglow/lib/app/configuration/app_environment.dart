enum AppFlavor {
  development,
  staging,
  production,
}

class AppEnvironment {
  final AppFlavor flavor;
  final String appTitle;

  const AppEnvironment({
    required this.flavor,
    required this.appTitle,
  });

  static AppEnvironment current = const AppEnvironment(
    flavor: AppFlavor.production,
    appTitle: 'بستان القرآن',
  );

  bool get isDevelopment => flavor == AppFlavor.development;
  bool get isProduction => flavor == AppFlavor.production;
}
