import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dev_network_call.dart';
import 'dev_network_call_detail.dart';
import 'dev_network_log_store.dart';

/// Debug-only overlay: floating entry to inspect HTTP traffic (see [main.dart]).
class HeliosDevInspectorLayer extends StatefulWidget {
  const HeliosDevInspectorLayer({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<HeliosDevInspectorLayer> createState() => _HeliosDevInspectorLayerState();
}

class _HeliosDevInspectorLayerState extends State<HeliosDevInspectorLayer> {
  static const double _fabSize = 48;
  static const double _edgeMargin = 8;

  bool _devSheetOpen = false;
  double _fabInsetRight = _edgeMargin;
  double _fabInsetBottom = _edgeMargin;

  void _onFabPanUpdate(DragUpdateDetails d) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final p = mq.padding;
    final minR = p.right + _edgeMargin;
    final maxR = w - p.left - _fabSize - _edgeMargin;
    final minB = p.bottom + _edgeMargin;
    final maxB = h - p.top - _fabSize - _edgeMargin;
    if (maxR < minR || maxB < minB) return;

    setState(() {
      _fabInsetRight = (_fabInsetRight - d.delta.dx).clamp(minR, maxR);
      _fabInsetBottom = (_fabInsetBottom - d.delta.dy).clamp(minB, maxB);
    });
  }

  void _toggleDevSheet(BuildContext materialContext) {
    final navContext = widget.navigatorKey.currentContext ?? materialContext;
    final nav = Navigator.of(navContext, rootNavigator: true);

    if (_devSheetOpen) {
      if (nav.canPop()) {
        nav.pop();
      }
      return;
    }

    setState(() => _devSheetOpen = true);
    showModalBottomSheet<void>(
      context: navContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final h = MediaQuery.sizeOf(sheetContext).height * 0.88;
        return SizedBox(
          height: h,
          child: DefaultTabController(
            length: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                  child: Row(
                    children: [
                      Text(
                        'Dev menu',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          sheetContext.read<DevNetworkLogStore>().clear();
                        },
                        child: const Text('Clear'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  labelColor: Theme.of(sheetContext).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'API calls'),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _DevApiCallsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() => _devSheetOpen = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Avoid [FloatingActionButton] here: it can interact badly when the parent
    // is not a [Scaffold] (splash / material sizing). Use a tight clipped chip.
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        widget.child,
        Positioned(
          right: _fabInsetRight,
          bottom: _fabInsetBottom,
          // Do not use [Tooltip] here: [MaterialApp.router]’s [builder] sits
          // *above* the [Navigator] [Overlay]. [Tooltip] requires an [Overlay]
          // ancestor and throws, which paints Flutter’s red error UI.
          child: GestureDetector(
            onPanUpdate: _onFabPanUpdate,
            child: Semantics(
              button: true,
              label: 'Dev menu, HTTP log (debug build)',
              child: Material(
                elevation: 4,
                shadowColor: Colors.black45,
                shape: const CircleBorder(),
                color: theme.colorScheme.primaryContainer,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _toggleDevSheet(context),
                  child: const SizedBox(
                    width: _fabSize,
                    height: _fabSize,
                    child: Icon(Icons.developer_mode_outlined, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DevApiCallsTab extends StatelessWidget {
  const _DevApiCallsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<DevNetworkLogStore>(
      builder: (context, store, _) {
        final calls = store.calls;
        if (calls.isEmpty) {
          return const Center(
            child: Text('No HTTP calls yet.\nCore + Todo use the logging client.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: calls.length,
          itemBuilder: (context, i) {
            final c = calls[calls.length - 1 - i];
            return _CallTile(call: c);
          },
        );
      },
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.call});

  final DevNetworkCall call;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = call.startedAt;
    final timeStr =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    final status = call.statusCode;
    final subtitle = call.isError
        ? 'Failed — open for full error'
        : '$status · ${call.durationMs ?? '?'} ms';

    Color? statusColor;
    if (call.isError) {
      statusColor = theme.colorScheme.error;
    } else if (status != null) {
      if (status >= 500) {
        statusColor = theme.colorScheme.error;
      } else if (status >= 400) {
        statusColor = theme.colorScheme.tertiary;
      }
    }

    return ListTile(
      dense: true,
      title: Text(
        '${call.method} ${call.url}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$timeStr · $subtitle',
        style: TextStyle(color: statusColor),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _showDetail(context, call),
    );
  }

  void _showDetail(BuildContext context, DevNetworkCall c) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => DevNetworkCallDetailPage(call: c),
      ),
    );
  }
}
