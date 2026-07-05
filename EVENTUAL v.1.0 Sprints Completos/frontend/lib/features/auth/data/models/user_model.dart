// lib/features/auth/data/models/user_model.dart
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.nombres,
    required super.apellidos,
    required super.cedula,
    required super.rol,
    required super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    final user = json['user'] as Map<String, dynamic>;
    return UserModel(
      id: user['id'],
      nombres: user['nombres'],
      apellidos: user['apellidos'],
      cedula: user['cedula'],
      rol: user['rol'],
      token: token,
    );
  }
}
