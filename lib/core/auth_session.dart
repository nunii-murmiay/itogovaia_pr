import 'package:dio/dio.dart';
import 'api_client.dart';

/// Учебная сессия: входим как admin (все CRUD-операции доступны).
class AuthSession {
  AuthSession(this._dio);

  final Dio _dio;
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<void> ensureLibrarian() => ensureLoggedIn();
  Future<void> ensureAdmin() => ensureLoggedIn();

  Future<void> ensureLoggedIn() async {
    if (_accessToken != null) return;
    final response = await guard(() async {
      return _dio.post(
        '/auth/login',
        data: {'username': 'admin', 'password': 'admin123'},
      );
    });
    final data = response.data as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String?;
  }
}
