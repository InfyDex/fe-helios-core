import 'package:flutter_test/flutter_test.dart';
import 'package:todo/todo.dart';

void main() {
  group('TodoConfig', () {
    test('joinUrl strips base trailing slash', () {
      expect(
        TodoConfig.joinUrl('http://localhost:8081/', '/todo/v1/todos'),
        'http://localhost:8081/todo/v1/todos',
      );
    });
  });
}
