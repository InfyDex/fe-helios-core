import 'package:flutter_test/flutter_test.dart';
import 'package:helios/core/dev/dev_http_logging_client.dart';
import 'package:helios/core/dev/dev_network_log_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('logs request and response', () async {
    final store = DevNetworkLogStore();
    final inner = MockClient((request) async {
      expect(request.url.path, '/core/v1/health');
      return http.Response('ok', 200, headers: {'x-test': '1'});
    });
    final client = DevHttpLoggingClient(
      inner: inner,
      store: store,
      logToConsole: false,
    );
    addTearDown(client.close);

    final res = await client.get(Uri.parse('http://127.0.0.1:9/core/v1/health'));
    expect(res.statusCode, 200);
    expect(res.body, 'ok');

    expect(store.calls, hasLength(1));
    final c = store.calls.single;
    expect(c.method, 'GET');
    expect(c.statusCode, 200);
    expect(c.responseBody, 'ok');
    expect(c.responseHeaders['x-test'], '1');
    expect(c.durationMs, isNotNull);
  });
}
