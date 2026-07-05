// lib/features/members/data/models/member_model.dart
import '../../domain/entities/member_entity.dart';

class MemberModel extends MemberEntity {
  const MemberModel({
    required super.id,
    required super.cedula,
    required super.nombres,
    required super.apellidos,
    super.telefono,
    super.direccion,
    required super.estado,
    required super.rolId,
    required super.rolNombre,
    required super.fechaIngreso,
  });

  factory MemberModel.fromJson(Map<String, dynamic> j) => MemberModel(
        id: j['id'],
        cedula: j['cedula'],
        nombres: j['nombres'],
        apellidos: j['apellidos'],
        telefono: j['telefono'],
        direccion: j['direccion'],
        estado: j['estado'] ?? 'Activo',
        rolId: j['rol_id'],
        rolNombre: j['rol_nombre'] ?? '',
        fechaIngreso: (j['fecha_ingreso'] ?? '').toString().substring(0, 10),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cedula': cedula,
        'nombres': nombres,
        'apellidos': apellidos,
        'telefono': telefono,
        'direccion': direccion,
        'estado': estado,
        'rol_id': rolId,
        'rol_nombre': rolNombre,
        'fecha_ingreso': fechaIngreso,
      };
}

class RoleModel extends RoleEntity {
  const RoleModel({required super.id, required super.nombre});
  factory RoleModel.fromJson(Map<String, dynamic> j) =>
      RoleModel(id: j['id'], nombre: j['nombre']);
}
