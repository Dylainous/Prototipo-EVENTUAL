// lib/features/auth/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String nombres;
  final String apellidos;
  final String cedula;
  final String rol;
  final String token;

  const UserEntity({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.cedula,
    required this.rol,
    required this.token,
  });

  String get nombreCompleto => '$nombres $apellidos';

  @override
  List<Object?> get props => [id, cedula, rol];
}
