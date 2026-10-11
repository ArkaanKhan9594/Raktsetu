enum BackendType {
  firebase,
  rest,
  mock,
}

/// Central configuration for RaktSetu production deployment.
/// All environment variables are supplied via `--dart-define` flags
/// during build/CI/CD, preventing secrets or localhost addresses
/// from being hardcoded into the mobile binary.
class AppConfig {
  /// Defines which data source powers the app.
  /// Set via `--dart-define=BACKEND_TYPE=firebase` (or `rest` / `mock`).
  static const String _backendTypeRaw = String.fromEnvironment(
    'BACKEND_TYPE',
    defaultValue: 'firebase',
  );

  static BackendType get backendType {
    switch (_backendTypeRaw.toLowerCase()) {
      case 'rest':
        return BackendType.rest;
      case 'mock':
        return BackendType.mock;
      case 'firebase':
      default:
        return BackendType.firebase;
    }
  }

  /// Production REST API base URL.
  /// Set via `--dart-define=API_URL=https://api.raktsetu.org`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.raktsetu.org',
  );

  /// API connection timeout.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// API receive timeout.
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Application identifier matching Google Play / App Store listing.
  static const String applicationId = 'org.raktsetu.blooddonor';

  /// App name for public store listings.
  static const String appName = 'RaktSetu';

  /// Verifies that no development localhost/127.0.0.1 URL is used in production.
  static void validateProductionConfig() {
    if (backendType == BackendType.rest) {
      const isRelease = bool.fromEnvironment('dart.vm.product');
      final uri = Uri.tryParse(apiBaseUrl);
      if (isRelease) {
        if (uri == null || !uri.isScheme('https')) {
          throw StateError(
            'Security Violation: Production API must use HTTPS with a valid SSL certificate. Got: $apiBaseUrl',
          );
        }
        if (apiBaseUrl.contains('localhost') || apiBaseUrl.contains('127.0.0.1')) {
          throw StateError(
            'Configuration Error: Localhost addresses (127.0.0.1/localhost) cannot be used in a production mobile release.',
          );
        }
      }
    }
  }
}
