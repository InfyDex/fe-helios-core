import 'dart:convert';

import 'package:http/http.dart' as http;

import 'todo_api_client.dart';
import 'todo_exceptions.dart';
import 'todo_models.dart';

/// Helios Todo microservice (`/todo/v1/...`). Uses [TodoApiClient] + Bearer Helios JWT.
class TodoRepository {
  TodoRepository({
    required TodoApiClient client,
  }) : _client = client;

  final TodoApiClient _client;

  /// `GET /todo/v1/todos`
  Future<List<Todo>> listTodos() async {
    final res = await _client.get('/todos');
    _throwIfBad(res, 'list todos');
    return _parseTodoList(res.body);
  }

  /// `POST /todo/v1/todos`
  Future<Todo> createTodo(String title) async {
    final res = await _client.post('/todos', {'title': title});
    _throwIfBad(res, 'create todo');
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final inner = decoded['todo'] ?? decoded['item'];
      if (inner is Map<String, dynamic>) {
        return Todo.fromJson(inner);
      }
      return Todo.fromJson(decoded);
    }
    throw TodoApiException('create todo: unexpected response shape');
  }

  /// `PATCH /todo/v1/todos/{id}`
  Future<Todo> setDone(String id, bool done) async {
    final res = await _client.patch('/todos/$id', {'done': done});
    _throwIfBad(res, 'update todo');
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final inner = decoded['todo'] ?? decoded['item'];
      if (inner is Map<String, dynamic>) {
        return Todo.fromJson(inner);
      }
      return Todo.fromJson(decoded);
    }
    throw TodoApiException('update todo: unexpected response shape');
  }

  /// `DELETE /todo/v1/todos/{id}`
  Future<void> deleteTodo(String id) async {
    final res = await _client.delete('/todos/$id');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TodoApiException(
        'delete todo: ${res.statusCode} ${res.body}',
        statusCode: res.statusCode,
      );
    }
  }

  void dispose() {
    _client.dispose();
  }

  void _throwIfBad(http.Response res, String op) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw TodoApiException(
      '$op: ${res.statusCode} ${res.body}',
      statusCode: res.statusCode,
    );
  }

  List<Todo> _parseTodoList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded
          .map((e) => Todo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      final raw = decoded['todos'] ?? decoded['items'] ?? decoded['data'];
      if (raw is List) {
        return raw
            .map((e) => Todo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }
}
