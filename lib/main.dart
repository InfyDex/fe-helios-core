import 'package:flutter/material.dart';

import 'app.dart';
import 'core/env/helios_env.dart';
import 'core/router/app_router.dart';
import 'features/auth/data/helios_core_api.dart';
import 'features/auth/data/secure_session_store.dart';
import 'features/auth/helios_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HeliosEnv.assertWebClientConfigured();

  final navigatorKey = GlobalKey<NavigatorState>();
  final coreApi = HeliosCoreApi();
  final sessionStore = SecureSessionStore();
  final auth = HeliosAuthService(
    coreApi: coreApi,
    sessionStore: sessionStore,
  );
  await auth.init();

  final router = createAppRouter(
    navigatorKey: navigatorKey,
    auth: auth,
  );

  runApp(HeliosApp(auth: auth, router: router));
}
