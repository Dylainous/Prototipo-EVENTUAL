// lib/features/events/domain/entities/event_entity.dart
import 'package:equatable/equatable.dart';

class EventEntity extends Equatable {
  final String id;
  final String nombre;
  final String tipoEvento; // 'Social' | 'Deportivo'
  final String? descripcion;
  final DateTime fecha;
  final String hora;
  final String lugar;
  final String estado;

  const EventEntity({
    required this.id,
    required this.nombre,
    required this.tipoEvento,
    this.descripcion,
    required this.fecha,
    required this.hora,
    required this.lugar,
    required this.estado,
  });

  @override
  List<Object?> get props => [id];
}
