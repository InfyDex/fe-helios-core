import 'package:flutter/material.dart';
import 'package:helios_auth_contract/helios_auth_contract.dart';

import 'todo_api_config.dart';

/// Stub route proving plugin ↔ host auth wiring. Does **not** use Google
/// Sign-In; receives [HeliosAuth] from the host only.
class TodoStubPage extends StatelessWidget {
  const TodoStubPage({super.key, required this.auth});

  final HeliosAuth auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo (stub)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<HeliosAuthSnapshot>(
          stream: auth.authStateStream,
          initialData: auth.snapshot,
          builder: (context, snap) {
            final user = snap.data?.user;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Signed in as: ${user?.displayLabel ?? "(unknown)"}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Future todo API: ${TodoApiConfig.baseUrl}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    final jwt = await auth.getHeliosJwt();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          jwt == null
                              ? 'No Helios JWT (signed out?)'
                              : 'JWT length: ${jwt.length} (use in Authorization header)',
                        ),
                      ),
                    );
                  },
                  child: const Text('Demo: read Helios JWT'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
