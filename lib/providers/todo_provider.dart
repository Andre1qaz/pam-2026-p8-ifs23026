// lib/providers/todo_provider.dart
// Andre Christian Saragih - ifs23026

import 'dart:io';
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
  TodoStatus      _status       = TodoStatus.initial;
  List<TodoModel> _todos        = [];
  TodoModel?      _selectedTodo;
  String          _errorMessage = '';
  String          _searchQuery  = '';
  TodoFilter      _filter       = TodoFilter.all;

  // ── Pagination State ──────────────────────────
  int  _currentPage   = 1;
  int  _totalPages    = 1;
  int  _total         = 0;
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
    List<TodoModel> filtered;
    switch (_filter) {
      case TodoFilter.done:
        filtered = _todos.where((t) => t.isDone).toList();
      case TodoFilter.pending:
        filtered = _todos.where((t) => !t.isDone).toList();
      case TodoFilter.all:
        filtered = List.of(_todos);
    }
    if (_searchQuery.isEmpty) return filtered;
    return filtered
        .where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  int get totalTodos   => _todos.length;
  int get doneTodos    => _todos.where((t) => t.isDone).length;
  int get pendingTodos => _todos.where((t) => !t.isDone).length;

  // ── Load All Todos (refresh / first page) ────
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

  /// Muat halaman berikutnya (infinite scroll)
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
    required bool   isDone,
  }) async {
    _setStatus(TodoStatus.loading);
    final updateResult = await _repository.updateTodo(
      authToken: authToken, todoId: todoId,
      title: title, description: description, isDone: isDone,
    );
    if (!updateResult.success) {
      _errorMessage = updateResult.message;
      _setStatus(TodoStatus.error);
      return false;
    }

    // Fetch detail & list secara paralel
    final detailResult = await _repository.getTodoById(authToken: authToken, todoId: todoId);
    final listResult   = await _repository.getTodos(
      authToken: authToken,
      page: 1,
      perPage: _todos.length.clamp(1, 100),
    );

    if (detailResult.success && detailResult.data != null) {
      _selectedTodo = detailResult.data;
    }
    if (listResult.success && listResult.data != null) {
      _todos      = listResult.data!.todos;
      _total      = listResult.data!.total;
      _totalPages = listResult.data!.totalPages;
    }

    _setStatus(TodoStatus.success);
    return true;
  }

  // ── Update Cover ──────────────────────────────
  Future<bool> updateCover({
    required String authToken,
    required String todoId,
    File?    imageFile,
    Uint8List? imageBytes,
    String   imageFilename = 'cover.jpg',
  }) async {
    _setStatus(TodoStatus.loading);
    final coverResult = await _repository.updateTodoCover(
      authToken: authToken, todoId: todoId,
      imageFile: imageFile, imageBytes: imageBytes, imageFilename: imageFilename,
    );
    if (!coverResult.success) {
      _errorMessage = coverResult.message;
      _setStatus(TodoStatus.error);
      return false;
    }

    final detailResult = await _repository.getTodoById(authToken: authToken, todoId: todoId);
    final listResult   = await _repository.getTodos(
      authToken: authToken,
      page: 1,
      perPage: _todos.length.clamp(1, 100),
    );

    if (detailResult.success && detailResult.data != null) {
      _selectedTodo = detailResult.data;
    }
    if (listResult.success && listResult.data != null) {
      _todos      = listResult.data!.todos;
      _total      = listResult.data!.total;
      _totalPages = listResult.data!.totalPages;
    }

    _setStatus(TodoStatus.success);
    return true;
  }

  // ── Delete Todo ───────────────────────────────
  Future<bool> removeTodo({required String authToken, required String todoId}) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.deleteTodo(authToken: authToken, todoId: todoId);
    if (result.success) {
      _todos.removeWhere((t) => t.id == todoId);
      _total        = (_total - 1).clamp(0, double.maxFinite.toInt());
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
