import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'todo_exceptions.dart';
import 'todo_models.dart';
import 'todo_repository.dart';

/// Todo list + add; uses [TodoRepository] from [Provider]. No Google Sign-In.
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List<Todo>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = context.read<TodoRepository>();
    try {
      final list = await repo.listTodos();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } on TodoNoTokenException catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Not signed in. Please sign in again.';
      });
      context.go('/login');
    } on TodoApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
      if (e.isUnauthorized && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Sign in again.')),
        );
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _addTodo() async {
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => const _AddTodoDialog(),
    );
    if (title == null || title.trim().isEmpty || !mounted) return;
    final repo = context.read<TodoRepository>();
    try {
      await repo.createTodo(title.trim());
      if (!mounted) return;
      await _load();
    } on TodoApiException catch (e) {
      if (!mounted) return;
      if (e.isUnauthorized) {
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _toggle(Todo t) async {
    final repo = context.read<TodoRepository>();
    final optimistic = !t.done;
    setState(() {
      _items = _items
          ?.map((x) => x.id == t.id ? x.copyWith(done: optimistic) : x)
          .toList();
    });
    try {
      await repo.setDone(t.id, optimistic);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = _items
            ?.map((x) => x.id == t.id ? x.copyWith(done: t.done) : x)
            .toList();
      });
      if (e is TodoApiException && e.isUnauthorized) {
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _delete(Todo t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete todo?'),
        content: Text(t.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = context.read<TodoRepository>();
    try {
      await repo.deleteTodo(t.id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items == null) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_error != null && (_items == null || _items!.isEmpty)) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _load,
            child: const Text('Retry'),
          ),
        ],
      );
    }
    final items = _items ?? [];
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'No todos yet. Tap + to add one.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final t = items[i];
        return ListTile(
          leading: Checkbox(
            value: t.done,
            onChanged: (_) => _toggle(t),
          ),
          title: Text(
            t.title,
            style: t.done
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Theme.of(context).colorScheme.outline,
                  )
                : null,
          ),
          subtitle: Text(
            '${t.createdAt.toLocal()}'.split('.').first,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () => context.push('/todos/${t.id}', extra: t),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(t),
          ),
        );
      },
    );
  }
}

class _AddTodoDialog extends StatefulWidget {
  const _AddTodoDialog();

  @override
  State<_AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<_AddTodoDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New todo'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
