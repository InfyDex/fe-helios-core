import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helios/features/auth/data/helios_core_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HeliosCoreApi', () {
    test('exchangeGoogleIdToken returns user and token on 200', () async {
      final client = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(
          request.url.toString(),
          equals('http://127.0.0.1:9/core/v1/auth/google'),
        );
        final map = jsonDecode(request.body) as Map<String, dynamic>;
        expect(map['idToken'], equals('google-id-token'));
        return http.Response(
          '{"user":{"id":"u1","email":"a@b.com","name":"Ada"},"token":"helios.jwt"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = HeliosCoreApi(
        httpClient: client,
        apiBaseOverride: 'http://127.0.0.1:9',
      );
      addTearDown(api.dispose);
      final result = await api.exchangeGoogleIdToken('google-id-token');
      expect(result.isSuccess, isTrue);
      expect(result.user?.id, equals('u1'));
      expect(result.user?.email, equals('a@b.com'));
      expect(result.user?.name, equals('Ada'));
      expect(result.token, equals('helios.jwt'));
    });

    test('exchangeGoogleIdToken fails on non-2xx', () async {
      final client = MockClient(
        (_) async => http.Response('gone', 502),
      );
      final api = HeliosCoreApi(
        httpClient: client,
        apiBaseOverride: 'http://127.0.0.1:9',
      );
      addTearDown(api.dispose);
      final result = await api.exchangeGoogleIdToken('t');
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('502'));
    });

    test('exchangeGoogleIdToken fails when user or token missing', () async {
      final client = MockClient(
        (_) async => http.Response('{"token":"only"}', 200),
      );
      final api = HeliosCoreApi(
        httpClient: client,
        apiBaseOverride: 'http://127.0.0.1:9',
      );
      addTearDown(api.dispose);
      final result = await api.exchangeGoogleIdToken('t');
      expect(result.isSuccess, isFalse);
    });

    test('healthOk is true on 2xx', () async {
      final client = MockClient(
        (request) async {
          expect(request.method, equals('GET'));
          return http.Response('ok', 204);
        },
      );
      final api = HeliosCoreApi(
        httpClient: client,
        apiBaseOverride: 'http://127.0.0.1:9',
      );
      addTearDown(api.dispose);
      expect(await api.healthOk(), isTrue);
    });

    test('healthOk is false on error status', () async {
      final client = MockClient(
        (_) async => http.Response('err', 500),
      );
      final api = HeliosCoreApi(
        httpClient: client,
        apiBaseOverride: 'http://127.0.0.1:9',
      );
      addTearDown(api.dispose);
      expect(await api.healthOk(), isFalse);
    });
  });
}
