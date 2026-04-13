import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies/movies.dart';
import 'package:provider/provider.dart';
import 'package:todo/todo.dart';

import '../../features/auth/helios_auth_service.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../shell/home_shell.dart';

GoRouter createAppRouter({
  required GlobalKey<NavigatorState> navigatorKey,
  required HeliosAuthService auth,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/home',
    refreshListenable: auth,
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = auth.snapshot.isLoggedIn;
      final loc = state.uri.path;
      if (!loggedIn && loc != '/login') {
        return '/login';
      }
      if (loggedIn && loc == '/login') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) =>
            state.uri.path == '/' ? '/home' : null,
        routes: [
          ShellRoute(
            builder: (context, state, child) => HomeShellPage(child: child),
            routes: [
              GoRoute(
                path: 'home',
                builder: (context, state) => const HomeOverviewPage(),
              ),
              GoRoute(
                path: 'todo',
                redirect: (context, state) => '/todos',
              ),
              GoRoute(
                path: 'todos',
                builder: (context, state) => const TodoListPage(),
                routes: [
                  GoRoute(
                    path: ':todoId',
                    builder: (context, state) {
                      final id = state.pathParameters['todoId']!;
                      return TodoDetailPage(todoId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'movies',
                builder: (context, state) {
                  final helioAuth = context.read<HeliosAuthService>();
                  return MoviesStubPage(auth: helioAuth);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
