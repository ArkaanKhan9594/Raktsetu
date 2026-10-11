import 'package:flutter_test/flutter_test.dart';
import 'package:raktsetu/config/app_config.dart';
import 'package:raktsetu/services/api_client.dart';

void main() {
  group('Production Configuration and Security Tests', () {
    test('AppConfig has store-ready metadata and identifier', () {
      expect(AppConfig.applicationId, 'org.raktsetu.blooddonor');
      expect(AppConfig.appName, 'RaktSetu');
      expect(AppConfig.connectTimeout.inSeconds, 15);
      expect(AppConfig.receiveTimeout.inSeconds, 15);
      expect(AppConfig.apiBaseUrl.startsWith('https://'), isTrue);
    });

    test('ApiClient constructs HTTPS endpoints correctly', () {
      final client = ApiClient(baseUrl: 'https://api.raktsetu.org');
      expect(client.baseUrl, 'https://api.raktsetu.org');
    });

    test('Production config validates safely without error for default HTTPS URL', () {
      expect(() => AppConfig.validateProductionConfig(), returnsNormally);
    });
  });
}
