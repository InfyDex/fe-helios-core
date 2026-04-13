import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo/todo.dart';

import 'app.dart';
import 'core/dev/dev_http_logging_client.dart';
import 'core/dev/dev_network_log_store.dart';
import 'core/env/helios_env.dart';
import 'core/router/app_router.dart';
import 'features/auth/data/helios_core_api.dart';
import 'features/auth/data/secure_session_store.dart';
import 'features/auth/helios_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HeliosEnv.assertWebClientConfigured();

  final navigatorKey = GlobalKey<NavigatorState>();
  final DevNetworkLogStore? devLog =
      kDebugMode ? DevNetworkLogStore() : null;
  final http.Client coreHttp = devLog != null
      ? DevHttpLoggingClient(inner: http.Client(), store: devLog)
      : http.Client();
  final http.Client todoHttp = devLog != null
      ? DevHttpLoggingClient(inner: http.Client(), store: devLog)
      : http.Client();

  final coreApi = HeliosCoreApi(httpClient: coreHttp);
  final sessionStore = SecureSessionStore();
  final auth = HeliosAuthService(
    coreApi: coreApi,
    sessionStore: sessionStore,
  );
  await auth.init();

  final todoClient = TodoApiClient(
    getToken: auth.getHeliosJwt,
    onUnauthorized: auth.signOut,
    httpClient: todoHttp,
  );
  final todoRepository = TodoRepository(client: todoClient);

  final router = createAppRouter(
    navigatorKey: navigatorKey,
    auth: auth,
  );

  runApp(
    HeliosApp(
      auth: auth,
      router: router,
      todoRepository: todoRepository,
      navigatorKey: navigatorKey,
      devNetworkLogStore: devLog,
    ),
  );
}
