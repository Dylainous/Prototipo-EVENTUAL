// lib/features/members/domain/entities/member_entity.dart
import 'package:equatable/equatable.dart';

class MemberEntity extends Equatable {
  final String id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String? telefono;
  final String? direccion;
  final String estado;
  final int rolId;
  final String rolNombre;
  final String fechaIngreso;

  const MemberEntity({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    this.telefono,
    this.direccion,
    required this.estado,
    required this.rolId,
    required this.rolNombre,
    required this.fechaIngreso,
  });

  String get nombreCompleto => '$nombres $apellidos';
  bool get isActivo => estado == 'Activo';

  @override
  List<Object?> get props => [id, cedula];
}

class RoleEntity extends Equatable {
  final int id;
  final String nombre;
  const RoleEntity({required this.id, required this.nombre});
  @override
  List<Object?> get props => [id];
}
