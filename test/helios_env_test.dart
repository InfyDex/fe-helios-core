import 'package:flutter_test/flutter_test.dart';
import 'package:helios/core/env/helios_env.dart';

void main() {
  group('HeliosEnv.joinApiBaseAndPath', () {
    test('strips trailing slashes on base', () {
      expect(
        HeliosEnv.joinApiBaseAndPath('https://api.example/', '/core/v1/health'),
        'https://api.example/core/v1/health',
      );
    });

    test('adds leading slash to path when missing', () {
      expect(
        HeliosEnv.joinApiBaseAndPath('https://api.example', 'core/v1/health'),
        'https://api.example/core/v1/health',
      );
    });

    test('preserves path leading slash', () {
      expect(
        HeliosEnv.joinApiBaseAndPath('http://192.168.1.5:8080', '/core/v1/auth/google'),
        'http://192.168.1.5:8080/core/v1/auth/google',
      );
    });
  });
}
