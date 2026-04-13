import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'todo_exceptions.dart';
import 'todo_models.dart';
import 'todo_repository.dart';

/// Detail for a single [Todo] (passed via [GoRouterState.extra] from the list).
class TodoDetailPage extends StatefulWidget {
  const TodoDetailPage({super.key, required this.todoId});

  final String todoId;

  @override
  State<TodoDetailPage> createState() => _TodoDetailPageState();
}

class _TodoDetailPageState extends State<TodoDetailPage> {
  Todo? _todo;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final extra = GoRouterState.of(context).extra;
    if (extra is Todo && extra.id == widget.todoId) {
      setState(() {
        _todo = extra;
        _loading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _error = 'Open this todo from the list.';
      _loading = false;
    });
  }

  Future<void> _toggle() async {
    final t = _todo;
    if (t == null) return;
    final repo = context.read<TodoRepository>();
    final next = !t.done;
    setState(() => _todo = t.copyWith(done: next));
    try {
      final updated = await repo.setDone(t.id, next);
      if (!mounted) return;
      setState(() => _todo = updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _todo = t);
      if (e is TodoApiException && e.isUnauthorized) {
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Todo')),
        body: Center(child: Text(_error!)),
      );
    }
    final t = _todo!;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(value: t.done, onChanged: (_) => _toggle()),
                Text(t.done ? 'Done' : 'Open'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Created',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text('${t.createdAt.toLocal()}'.split('.').first),
          ],
        ),
      ),
    );
  }
}
