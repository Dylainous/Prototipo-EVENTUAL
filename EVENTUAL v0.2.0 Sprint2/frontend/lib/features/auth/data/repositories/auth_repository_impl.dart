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
      // El ApiClient ahora devuelve el Map directamente, no hay que hacer jsonDecode aquí
      final body = await _apiClient.post(
        ApiConstants.login,
        {'cedula': cedula, 'password': password},
        requiresAuth: false,
      );

      // Si el ApiClient no lanzó excepción, asumimos un status 2xx
      final user = UserModel.fromJson(body, body['token']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', user.token);
      
      // Aquí seguimos usando dart:convert para jsonEncode
      await prefs.setString('user_data', jsonEncode({
        'id': user.id,
        'nombres': user.nombres,
        'apellidos': user.apellidos,
        'cedula': user.cedula,
        'rol': user.rol,
      }));
      
      return (user: user as UserEntity, failure: null);
      
    } catch (e) {
      // Capturamos la excepción que lanza el nuevo ApiClient (ej. status 423 u otros errores)
      final msg = e.toString().replaceFirst('Exception: ', '');
      return (user: _emptyUser(), failure: AuthFailure(msg));
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
    
    // Aquí también seguimos usando dart:convert para jsonDecode
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
