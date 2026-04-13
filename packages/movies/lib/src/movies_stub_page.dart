import 'package:flutter/material.dart';
import 'package:helios_auth_contract/helios_auth_contract.dart';

import 'movies_api_config.dart';

/// Second stub plugin route (optional in spec); uses [HeliosAuth] from host only.
class MoviesStubPage extends StatelessWidget {
  const MoviesStubPage({super.key, required this.auth});

  final HeliosAuth auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movies (stub)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${auth.snapshot.user?.displayLabel ?? "guest"}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Placeholder API: ${MoviesApiConfig.baseUrl}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
