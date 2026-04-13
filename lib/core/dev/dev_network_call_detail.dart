import 'package:flutter/material.dart';

import 'dev_network_call.dart';

/// Full-screen tabbed inspector for a single [DevNetworkCall].
class DevNetworkCallDetailPage extends StatelessWidget {
  const DevNetworkCallDetailPage({super.key, required this.call});

  final DevNetworkCall call;

  @override
  Widget build(BuildContext context) {
    final hasError = call.errorMessage != null;
    final tabs = <Tab>[
      const Tab(text: 'Overview'),
      const Tab(text: 'Req headers'),
      const Tab(text: 'Req body'),
      const Tab(text: 'Res headers'),
      const Tab(text: 'Res body'),
      if (hasError) const Tab(text: 'Error'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${call.method} ${call.statusCode ?? '—'}'),
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(call: call),
            _KeyValueTab(title: 'Request headers', map: call.requestHeaders),
            _BodyTab(
              title: 'Request body',
              body: call.requestBody,
              emptyLabel: '(no body)',
            ),
            _KeyValueTab(title: 'Response headers', map: call.responseHeaders),
            _BodyTab(
              title: 'Response body',
              body: call.responseBody,
              emptyLabel: '(empty)',
            ),
            if (hasError)
              _BodyTab(
                title: 'Error',
                body: call.errorMessage,
                emptyLabel: '(none)',
              ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.call});

  final DevNetworkCall call;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SelectableText('URL', style: t.titleSmall),
        const SizedBox(height: 4),
        SelectableText(call.url, style: t.bodyMedium),
        const SizedBox(height: 16),
        SelectableText('Started', style: t.titleSmall),
        const SizedBox(height: 4),
        SelectableText(call.startedAt.toIso8601String(), style: t.bodyMedium),
        const SizedBox(height: 16),
        SelectableText('Duration', style: t.titleSmall),
        const SizedBox(height: 4),
        SelectableText('${call.durationMs ?? '—'} ms', style: t.bodyMedium),
        const SizedBox(height: 16),
        SelectableText('Status', style: t.titleSmall),
        const SizedBox(height: 4),
        SelectableText('${call.statusCode ?? '—'}', style: t.bodyMedium),
      ],
    );
  }
}

class _KeyValueTab extends StatelessWidget {
  const _KeyValueTab({required this.title, required this.map});

  final String title;
  final Map<String, String> map;

  @override
  Widget build(BuildContext context) {
    if (map.isEmpty) {
      return Center(child: Text('($title: none)'));
    }
    final buf = StringBuffer();
    for (final e in map.entries) {
      buf.writeln('${e.key}: ${e.value}');
    }
    return _SelectableScrollBody(text: buf.toString());
  }
}

class _BodyTab extends StatelessWidget {
  const _BodyTab({
    required this.title,
    required this.body,
    required this.emptyLabel,
  });

  final String title;
  final String? body;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final text = body == null || body!.isEmpty ? emptyLabel : body!;
    return _SelectableScrollBody(text: text);
  }
}

class _SelectableScrollBody extends StatelessWidget {
  const _SelectableScrollBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
