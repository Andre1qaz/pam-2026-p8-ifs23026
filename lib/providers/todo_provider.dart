// lib/providers/todo_provider.dart
// Andre Christian Saragih - ifs23026

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../data/models/todo_model.dart';
import '../data/services/todo_repository.dart';

enum TodoStatus { initial, loading, success, error }

/// Filter jenis todo
enum TodoFilter { all, done, pending }

class TodoProvider extends ChangeNotifier {
  TodoProvider({TodoRepository? repository})
      : _repository = repository ?? TodoRepository();

  final TodoRepository _repository;

  // ── State ────────────────────────────────────
  TodoStatus    _status       = TodoStatus.initial;
  List<TodoModel> _todos      = [];
  TodoModel?    _selectedTodo;
  String        _errorMessage = '';
  String        _searchQuery  = '';
  TodoFilter    _filter       = TodoFilter.all;

  // ── Pagination State ──────────────────────────
  int  _currentPage  = 1;
  int  _totalPages   = 1;
  int  _total        = 0;
  bool _isLoadingMore = false;
  static const int _perPage = 10;

  // ── Getters ──────────────────────────────────
  TodoStatus  get status        => _status;
  TodoModel?  get selectedTodo  => _selectedTodo;
  String      get errorMessage  => _errorMessage;
  TodoFilter  get filter        => _filter;
  bool        get hasMore       => _currentPage < _totalPages;
  bool        get isLoadingMore => _isLoadingMore;
  int         get total         => _total;

  List<TodoModel> get todos {
    List<TodoModel> result = List.unmodifiable(_todos);
    switch (_filter) {
      case TodoFilter.done:
        result = _todos.where((t) => t.isDone).toList();
      case TodoFilter.pending:
        result = _todos.where((t) => !t.isDone).toList();
      case TodoFilter.all:
        result = List.unmodifiable(_todos);
    }
    if (_searchQuery.isEmpty) return result;
    return result
        .where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  int get totalTodos   => _todos.length;
  int get doneTodos    => _todos.where((t) => t.isDone).length;
  int get pendingTodos => _todos.where((t) => !t.isDone).length;

  // ── Load All Todos (refresh / first page) ──
  Future<void> loadTodos({required String authToken, bool reset = true}) async {
    if (reset) {
      _currentPage = 1;
      _todos = [];
    }
    _setStatus(TodoStatus.loading);
    final result = await _repository.getTodos(
      authToken: authToken,
      page:      _currentPage,
      perPage:   _perPage,
    );
    if (result.success && result.data != null) {
      final paginated = result.data!;
      if (reset) {
        _todos = paginated.todos;
      } else {
        _todos.addAll(paginated.todos);
      }
      _totalPages = paginated.totalPages;
      _total      = paginated.total;
      _setStatus(TodoStatus.success);
    } else {
      _errorMessage = result.message;
      _setStatus(TodoStatus.error);
    }
  }

  /// Muat halaman berikutnya (pagination saat scroll ke bawah)
  Future<void> loadMoreTodos({required String authToken}) async {
    if (!hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;
    final result = await _repository.getTodos(
      authToken: authToken,
      page:      _currentPage,
      perPage:   _perPage,
    );

    if (result.success && result.data != null) {
      _todos.addAll(result.data!.todos);
      _totalPages = result.data!.totalPages;
      _total      = result.data!.total;
    } else {
      _currentPage--; // rollback jika gagal
      _errorMessage = result.message;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // ── Load Single Todo ──────────────────────────
  Future<void> loadTodoById({
    required String authToken,
    required String todoId,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.getTodoById(authToken: authToken, todoId: todoId);
    if (result.success && result.data != null) {
      _selectedTodo = result.data;
      _setStatus(TodoStatus.success);
    } else {
      _errorMessage = result.message;
      _setStatus(TodoStatus.error);
    }
  }

  // ── Create Todo ───────────────────────────────
  Future<bool> addTodo({
    required String authToken,
    required String title,
    required String description,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.createTodo(
      authToken: authToken, title: title, description: description,
    );
    if (result.success) {
      await loadTodos(authToken: authToken, reset: true);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Update Todo ───────────────────────────────
  Future<bool> editTodo({
    required String authToken,
    required String todoId,
    required String title,
    required String description,
    required bool isDone,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.updateTodo(
      authToken: authToken, todoId: todoId,
      title: title, description: description, isDone: isDone,
    );
    if (result.success) {
      final results = await Future.wait([
        _repository.getTodoById(authToken: authToken, todoId: todoId),
        _repository.getTodos(authToken: authToken, page: 1, perPage: _todos.length.clamp(1, 100)),
      ]);

      final detailResult = results[0];
      final listResult   = results[1];

      if (detailResult.success && detailResult.data != null) {
        _selectedTodo = detailResult.data as TodoModel;
      }
      if (listResult.success && listResult.data != null) {
        final paged = listResult.data as TodoPaginatedModel;
        _todos      = paged.todos;
        _total      = paged.total;
        _totalPages = paged.totalPages;
      }
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Update Cover ──────────────────────────────
  Future<bool> updateCover({
    required String authToken,
    required String todoId,
    File? imageFile,
    Uint8List? imageBytes,
    String imageFilename = 'cover.jpg',
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.updateTodoCover(
      authToken: authToken, todoId: todoId,
      imageFile: imageFile, imageBytes: imageBytes, imageFilename: imageFilename,
    );
    if (result.success) {
      final results = await Future.wait([
        _repository.getTodoById(authToken: authToken, todoId: todoId),
        _repository.getTodos(authToken: authToken, page: 1, perPage: _todos.length.clamp(1, 100)),
      ]);

      if (results[0].success && results[0].data != null) {
        _selectedTodo = results[0].data as TodoModel;
      }
      if (results[1].success && results[1].data != null) {
        final paged = results[1].data as TodoPaginatedModel;
        _todos      = paged.todos;
        _total      = paged.total;
        _totalPages = paged.totalPages;
      }
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Delete Todo ───────────────────────────────
  Future<bool> removeTodo({required String authToken, required String todoId}) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.deleteTodo(authToken: authToken, todoId: todoId);
    if (result.success) {
      _todos.removeWhere((t) => t.id == todoId);
      _total      = (_total - 1).clamp(0, double.maxFinite.toInt());
      _selectedTodo = null;
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Filter & Search ───────────────────────────
  void setFilter(TodoFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSelectedTodo() {
    _selectedTodo = null;
    notifyListeners();
  }

  void _setStatus(TodoStatus status) {
    _status = status;
    notifyListeners();
  }
}
