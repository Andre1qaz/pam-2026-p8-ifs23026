// lib/features/todos/todos_screen.dart
// Andre Christian Saragih - ifs23026

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/todo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    final token = context.read<AuthProvider>().authToken;
    if (token != null) {
      context.read<TodoProvider>().loadTodos(authToken: token, reset: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final token    = context.read<AuthProvider>().authToken;
      final provider = context.read<TodoProvider>();
      if (token != null && provider.hasMore && !provider.isLoadingMore) {
        provider.loadMoreTodos(authToken: token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final token    = context.read<AuthProvider>().authToken ?? '';

    return Scaffold(
      appBar: TopAppBarWidget(
        title: 'Todo Saya',
        withSearch: true,
        searchHint: 'Cari todo...',
        onSearchChanged: (q) => context.read<TodoProvider>().updateSearchQuery(q),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.todosAdd).then((_) => _loadData()),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          // ── Filter Chips ──
          _FilterBar(
            current: provider.filter,
            onChanged: (f) => context.read<TodoProvider>().setFilter(f),
            total:   provider.totalTodos,
            done:    provider.doneTodos,
            pending: provider.pendingTodos,
          ),

          // ── Content ──
          Expanded(
            child: _buildBody(provider, token),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TodoProvider provider, String token) {
    final isFirstLoad = (provider.status == TodoStatus.loading ||
            provider.status == TodoStatus.initial) &&
        provider.todos.isEmpty;

    if (isFirstLoad) return const LoadingWidget(message: 'Memuat todo...');
    if (provider.status == TodoStatus.error) {
      return AppErrorWidget(message: provider.errorMessage, onRetry: _loadData);
    }
    if (provider.todos.isEmpty) return const _EmptyState();

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: provider.todos.length + (provider.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (i == provider.todos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final todo = provider.todos[i];
          return _TodoCard(
            todo: todo,
            onTap: () => context
                .push(RouteConstants.todosDetail(todo.id))
                .then((_) => _loadData()),
            onToggle: () async {
              final success = await provider.editTodo(
                authToken:   token,
                todoId:      todo.id,
                title:       todo.title,
                description: todo.description,
                isDone:      !todo.isDone,
              );
              if (!success && mounted) {
                showAppSnackBar(context,
                    message: provider.errorMessage, type: SnackBarType.error);
              }
            },
          );
        },
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.current,
    required this.onChanged,
    required this.total,
    required this.done,
    required this.pending,
  });

  final TodoFilter               current;
  final ValueChanged<TodoFilter> onChanged;
  final int                      total, done, pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: 'Semua ($total)',
              selected: current == TodoFilter.all,
              onTap: () => onChanged(TodoFilter.all),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Selesai ($done)',
              selected: current == TodoFilter.done,
              onTap: () => onChanged(TodoFilter.done),
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Belum ($pending)',
              selected: current == TodoFilter.pending,
              onTap: () => onChanged(TodoFilter.pending),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  final Color?       color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = color ?? colorScheme.primary;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: activeColor.withValues(alpha: 0.15),
      checkmarkColor: activeColor,
      labelStyle: TextStyle(
        color: selected ? activeColor : null,
        fontWeight: selected ? FontWeight.bold : null,
      ),
      side: BorderSide(
        color: selected ? activeColor : colorScheme.outline.withValues(alpha: 0.5),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada todo.\nKetuk + untuk menambahkan.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Todo Card ─────────────────────────────────────────────────────────────────
class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.onTap,
    required this.onToggle,
  });

  final TodoModel    todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              key: ValueKey(todo.isDone),
              todo.isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: todo.isDone ? Colors.green : colorScheme.outline,
              size: 28,
            ),
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
            color: todo.isDone ? colorScheme.outline : null,
          ),
        ),
        subtitle: Text(
          todo.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: todo.isDone ? colorScheme.outline : null),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }
}
