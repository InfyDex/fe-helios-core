import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'features/auth/helios_auth_service.dart';

class HeliosApp extends StatelessWidget {
  const HeliosApp({
    super.key,
    required this.auth,
    required this.router,
  });

  final HeliosAuthService auth;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HeliosAuthService>.value(
      value: auth,
      child: MaterialApp.router(
        title: 'Helios',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100)),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
