import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:todo/todo.dart';

void main() {
  group('TodoRepository', () {
    test('listTodos parses array body', () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], startsWith('Bearer '));
        return http.Response(
          jsonEncode([
            {
              'id': '1',
              'title': 'A',
              'done': false,
              'created_at': '2024-01-02T03:04:05Z',
            },
          ]),
          200,
        );
      });
      final api = TodoApiClient(
        getToken: () async => 'jwt',
        httpClient: client,
        baseUrlOverride: 'http://127.0.0.1:2',
      );
      addTearDown(api.dispose);
      final repo = TodoRepository(client: api);
      addTearDown(repo.dispose);
      final list = await repo.listTodos();
      expect(list.length, 1);
      expect(list.single.title, 'A');
    });

    test('listTodos parses todos wrapper', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'todos': [
              {
                'id': '2',
                'title': 'B',
                'done': true,
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
            ],
          }),
          200,
        ),
      );
      final api = TodoApiClient(
        getToken: () async => 'jwt',
        httpClient: client,
        baseUrlOverride: 'http://127.0.0.1:2',
      );
      addTearDown(api.dispose);
      final repo = TodoRepository(client: api);
      addTearDown(repo.dispose);
      final list = await repo.listTodos();
      expect(list.single.id, '2');
      expect(list.single.done, isTrue);
    });
  });
}
