import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// ── Events ────────────────────────────────────────────────
abstract class ReportsEvent extends Equatable {
  @override List<Object?> get props => [];
}

class ReportsGenerateParticipation extends ReportsEvent {
  final String? fechaInicio;
  final String? fechaFin;
  final String tipoEvento;
  final String? eventoId;
  ReportsGenerateParticipation({
    this.fechaInicio, this.fechaFin,
    this.tipoEvento = 'Todos', this.eventoId,
  });
  @override List<Object?> get props => [fechaInicio, fechaFin, tipoEvento];
}

class ReportsGenerateHistory extends ReportsEvent {
  final String? fechaInicio;
  final String? fechaFin;
  final String tipoEvento;
  final String estado;
  ReportsGenerateHistory({
    this.fechaInicio, this.fechaFin,
    this.tipoEvento = 'Todos', this.estado = 'Todos',
  });
  @override List<Object?> get props => [fechaInicio, fechaFin, tipoEvento, estado];
}

class ReportsGenerateLiquidations extends ReportsEvent {
  final String? fechaInicio;
  final String? fechaFin;
  final String? eventoId;
  final String estadoLiquidacion;
  ReportsGenerateLiquidations({
    this.fechaInicio, this.fechaFin,
    this.eventoId, this.estadoLiquidacion = 'Todas',
  });
  @override List<Object?> get props => [fechaInicio, fechaFin, estadoLiquidacion];
}

// ── States ────────────────────────────────────────────────
abstract class ReportsState extends Equatable {
  @override List<Object?> get props => [];
}
class ReportsInitial extends ReportsState {}
class ReportsLoading extends ReportsState {}

class ReportsParticipationLoaded extends ReportsState {
  final List<dynamic> eventos;
  final Map<String, dynamic>? resumen;
  final String? mensaje;
  ReportsParticipationLoaded({required this.eventos, this.resumen, this.mensaje});
  @override List<Object?> get props => [eventos, resumen];
}

class ReportsHistoryLoaded extends ReportsState {
  final List<dynamic> eventos;
  final String? firmante;
  final String? mensaje;
  ReportsHistoryLoaded({required this.eventos, this.firmante, this.mensaje});
  @override List<Object?> get props => [eventos];
}

class ReportsLiquidationsLoaded extends ReportsState {
  final List<dynamic> liquidaciones;
  final Map<String, dynamic>? resumen;
  final String? mensaje;
  ReportsLiquidationsLoaded({required this.liquidaciones, this.resumen, this.mensaje});
  @override List<Object?> get props => [liquidaciones, resumen];
}

class ReportsFailure extends ReportsState {
  final String error;
  ReportsFailure(this.error);
  @override List<Object?> get props => [error];
}

// ── BLoC ──────────────────────────────────────────────────
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ApiClient _api;

  ReportsBloc(this._api) : super(ReportsInitial()) {
    on<ReportsGenerateParticipation>(_onParticipation);
    on<ReportsGenerateHistory>(_onHistory);
    on<ReportsGenerateLiquidations>(_onLiquidations);
  }

  String _buildQuery(Map<String, String?> params) {
    final parts = params.entries
        .where((e) => e.value != null && e.value!.isNotEmpty && e.value != 'Todos' && e.value != 'Todas')
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value!)}')
        .toList();
    return parts.isEmpty ? '' : '?${parts.join('&')}';
  }

  Future<void> _onParticipation(
    ReportsGenerateParticipation e, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    try {
      final q = _buildQuery({
        'fecha_inicio': e.fechaInicio,
        'fecha_fin': e.fechaFin,
        'tipo_evento': e.tipoEvento,
        'evento_id': e.eventoId,
      });
      final resp = await _api.get('/reports/participation$q');
      emit(ReportsParticipationLoaded(
        eventos: resp['eventos'] ?? [],
        resumen: resp['resumen'] as Map<String, dynamic>?,
        mensaje: resp['mensaje'],
      ));
    } catch (e) {
      emit(ReportsFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onHistory(
    ReportsGenerateHistory e, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    try {
      final q = _buildQuery({
        'fecha_inicio': e.fechaInicio,
        'fecha_fin': e.fechaFin,
        'tipo_evento': e.tipoEvento,
        'estado': e.estado,
      });
      final resp = await _api.get('/reports/history$q');
      emit(ReportsHistoryLoaded(
        eventos: resp['eventos'] ?? [],
        firmante: resp['firmante'],
        mensaje: resp['mensaje'],
      ));
    } catch (e) {
      emit(ReportsFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLiquidations(
    ReportsGenerateLiquidations e, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    try {
      final q = _buildQuery({
        'fecha_inicio': e.fechaInicio,
        'fecha_fin': e.fechaFin,
        'evento_id': e.eventoId,
        'estado_liquidacion': e.estadoLiquidacion,
      });
      final resp = await _api.get('/reports/liquidations$q');
      emit(ReportsLiquidationsLoaded(
        liquidaciones: resp['liquidaciones'] ?? [],
        resumen: resp['resumen'] as Map<String, dynamic>?,
        mensaje: resp['mensaje'],
      ));
    } catch (e) {
      emit(ReportsFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}