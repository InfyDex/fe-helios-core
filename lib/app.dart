import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:todo/todo.dart';

import 'core/dev/dev_network_log_store.dart';
import 'core/dev/helios_dev_inspector_layer.dart';
import 'features/auth/helios_auth_service.dart';

class HeliosApp extends StatelessWidget {
  const HeliosApp({
    super.key,
    required this.auth,
    required this.router,
    required this.todoRepository,
    required this.navigatorKey,
    this.devNetworkLogStore,
  });

  final HeliosAuthService auth;
  final GoRouter router;
  final TodoRepository todoRepository;
  final GlobalKey<NavigatorState> navigatorKey;

  /// Debug HTTP ring buffer; null in profile/release.
  final DevNetworkLogStore? devNetworkLogStore;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HeliosAuthService>.value(value: auth),
        Provider<TodoRepository>.value(value: todoRepository),
        if (devNetworkLogStore != null)
          ChangeNotifierProvider<DevNetworkLogStore>.value(
            value: devNetworkLogStore!,
          ),
      ],
      child: MaterialApp.router(
        title: 'Helios',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100)),
          useMaterial3: true,
        ),
        routerConfig: router,
        builder: (context, child) {
          var wrapped = child ?? const SizedBox.shrink();
          if (devNetworkLogStore != null) {
            wrapped = HeliosDevInspectorLayer(
              navigatorKey: navigatorKey,
              child: wrapped,
            );
          }
          return wrapped;
        },
      ),
    );
  }
}
