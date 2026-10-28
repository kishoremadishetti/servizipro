/// Supported deployment environments for Servizipro.
enum Environment { test, qa, prod }

/// Holds environment-specific settings (base API URL, display name, etc).
///
/// Initialize once at app start with [EnvironmentConfig.init], then read
/// anywhere via [EnvironmentConfig.instance].
///
/// Switch environments at build/run time with:
///   flutter run --dart-define=ENV=test
///   flutter run --dart-define=ENV=qa
///   flutter run --dart-define=ENV=prod
class EnvironmentConfig {
  final Environment environment;
  final String baseUrl;
  final String appName;

  const EnvironmentConfig._({
    required this.environment,
    required this.baseUrl,
    required this.appName,
  });

  static const EnvironmentConfig _test = EnvironmentConfig._(
    environment: Environment.test,
    baseUrl: 'https://app-srvz-api-bca8auced2gngsdm.centralus-01.azurewebsites.net',
    appName: 'Servizipro (Test)',
  );

  static const EnvironmentConfig _qa = EnvironmentConfig._(
    environment: Environment.qa,
    baseUrl: 'https://qa-api.servizipro.com/api',
    appName: 'Servizipro (QA)',
  );

  static const EnvironmentConfig _prod = EnvironmentConfig._(
    environment: Environment.prod,
    baseUrl: 'https://api.servizipro.com/api',
    appName: 'Servizipro',
  );

  static EnvironmentConfig? _current;

  /// Must be called once (in main()) before [instance] is accessed.
  static void init(Environment env) {
    switch (env) {
      case Environment.test:
        _current = _test;
        break;
      case Environment.qa:
        _current = _qa;
        break;
      case Environment.prod:
        _current = _prod;
        break;
    }
  }

  static EnvironmentConfig get instance {
    final current = _current;
    if (current == null) {
      throw StateError(
        'EnvironmentConfig not initialized. Call EnvironmentConfig.init() in main() first.',
      );
    }
    return current;
  }
}
