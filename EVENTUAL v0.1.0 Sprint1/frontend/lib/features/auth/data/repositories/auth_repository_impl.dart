// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl(this._apiClient);

  @override
  Future<({UserEntity user, Failure? failure})> login({
    required String cedula,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        {'cedula': cedula, 'password': password},
        requiresAuth: false,
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(body, body['token']);
        // Persistir token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', user.token);
        await prefs.setString('user_data', jsonEncode({
          'id': user.id,
          'nombres': user.nombres,
          'apellidos': user.apellidos,
          'cedula': user.cedula,
          'rol': user.rol,
        }));
        return (user: user as UserEntity, failure: null);
      }

      final errorMsg = body['error'] ?? 'Error de autenticación';
      if (response.statusCode == 423) {
        return (
          user: _emptyUser(),
          failure: AuthFailure(errorMsg),
        );
      }
      return (user: _emptyUser(), failure: AuthFailure(errorMsg));
    } catch (e) {
      return (
        user: _emptyUser(),
        failure: NetworkFailure('Sin conexión con el servidor'),
      );
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  @override
  Future<UserEntity?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');
    if (token == null || userData == null) return null;
    final map = jsonDecode(userData) as Map<String, dynamic>;
    return UserModel(
      id: map['id'],
      nombres: map['nombres'],
      apellidos: map['apellidos'],
      cedula: map['cedula'],
      rol: map['rol'],
      token: token,
    );
  }

  UserEntity _emptyUser() => const UserModel(
        id: '', nombres: '', apellidos: '', cedula: '', rol: '', token: '');
}
