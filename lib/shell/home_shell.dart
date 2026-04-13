import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/helios_auth_service.dart';

class HomeShellPage extends StatelessWidget {
  const HomeShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<HeliosAuthService>();
    final user = auth.snapshot.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Helios'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  user.displayLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          TextButton(
            onPressed: () async {
              await context.read<HeliosAuthService>().signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _indexForLocation(GoRouterState.of(context).uri.path),
        onDestinationSelected: (i) {
          Navigator.of(context).pop();
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/todos');
            case 2:
              context.go('/movies');
          }
        },
        children: const [
          NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('Home'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: Text('Todos'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: Text('Movies (stub)'),
          ),
        ],
      ),
      body: child,
    );
  }

  static int _indexForLocation(String path) {
    if (path.startsWith('/todos')) return 1;
    if (path.startsWith('/movies')) return 2;
    return 0;
  }
}

class HomeOverviewPage extends StatelessWidget {
  const HomeOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<HeliosAuthService>();
    final user = auth.snapshot.user;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Welcome${user != null ? ', ${user.displayLabel}' : ''}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'You are signed in with Helios Core. Open the menu for Todos '
          '(Helios Todo microservice) or Movies (stub).',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
