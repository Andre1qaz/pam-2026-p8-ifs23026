// lib/core/constants/api_constants.dart
// Andre Christian Saragih - ifs23026

class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      "https://pam-2026-p8-ifs23026-be.11s23026.fun:8080";

  // ── Base Path ─────────────────────────────
  static const String auth  = '/auth';
  static const String users = '/users';
  static const String todos = '/todos';

  // ── Auth ─────────────────────────────────
  static const String authRegister = '$auth/register';
  static const String authLogin    = '$auth/login';
  static const String authLogout   = '$auth/logout';
  static const String authRefresh  = '$auth/refresh-token';

  // ── Users ────────────────────────────────
  static const String usersMe         = '$users/me';
  static const String usersMePassword = '$users/me/password';
  static const String usersMePhoto    = '$users/me/photo';

  // ── Todos ────────────────────────────────
  static String todoById(String id) =>
      '$todos/${id.trim()}';

  static String todoCover(String id) =>
      '$todos/${id.trim()}/cover';
}