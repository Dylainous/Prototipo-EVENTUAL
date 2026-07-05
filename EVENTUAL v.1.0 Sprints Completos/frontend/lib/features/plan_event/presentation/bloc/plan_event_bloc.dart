import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// ── Events ────────────────────────────────────────────────
abstract class PlanEventEvent extends Equatable {
  @override List<Object?> get props => [];
}
class PlanEventLoadProposals extends PlanEventEvent {}
class PlanEventApprove extends PlanEventEvent {
  final String propuestaId;
  final String fecha, hora, lugar;
  final double? presupuesto;
  final int? cupoMaximo;
  PlanEventApprove({required this.propuestaId, required this.fecha, required this.hora, required this.lugar, this.presupuesto, this.cupoMaximo});
  @override List<Object?> get props => [propuestaId];
}
class PlanEventReject extends PlanEventEvent {
  final String propuestaId;
  PlanEventReject(this.propuestaId);
  @override List<Object?> get props => [propuestaId];
}

// ── States ────────────────────────────────────────────────
abstract class PlanEventState extends Equatable {
  @override List<Object?> get props => [];
}
class PlanEventInitial extends PlanEventState {}
class PlanEventLoading extends PlanEventState {}
class PlanEventProposalsLoaded extends PlanEventState {
  final List<dynamic> propuestas;
  PlanEventProposalsLoaded(this.propuestas);
  @override List<Object?> get props => [propuestas];
}
class PlanEventSuccess extends PlanEventState {
  final String message;
  PlanEventSuccess(this.message);
  @override List<Object?> get props => [message];
}
class PlanEventFailure extends PlanEventState {
  final String error;
  PlanEventFailure(this.error);
  @override List<Object?> get props => [error];
}

// ── BLoC ──────────────────────────────────────────────────
class PlanEventBloc extends Bloc<PlanEventEvent, PlanEventState> {
  final ApiClient _api;
  PlanEventBloc(this._api) : super(PlanEventInitial()) {
    on<PlanEventLoadProposals>(_onLoad);
    on<PlanEventApprove>(_onApprove);
    on<PlanEventReject>(_onReject);
  }

  Future<void> _onLoad(PlanEventLoadProposals e, Emitter<PlanEventState> emit) async {
    emit(PlanEventLoading());
    try {
      final resp = await _api.get('/plan-event/proposals');
      emit(PlanEventProposalsLoaded(resp['propuestas'] ?? []));
    } catch (e) {
      emit(PlanEventFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onApprove(PlanEventApprove e, Emitter<PlanEventState> emit) async {
    emit(PlanEventLoading());
    try {
      final body = <String, dynamic>{
        'fecha': e.fecha, 'hora': e.hora, 'lugar': e.lugar,
        if (e.presupuesto != null) 'presupuesto_total': e.presupuesto,
        if (e.cupoMaximo != null) 'cupo_maximo': e.cupoMaximo,
      };
      final resp = await _api.post('/plan-event/approve/${e.propuestaId}', body);
      emit(PlanEventSuccess(resp['message'] ?? 'Evento definido correctamente.'));
    } catch (e) {
      emit(PlanEventFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onReject(PlanEventReject e, Emitter<PlanEventState> emit) async {
    emit(PlanEventLoading());
    try {
      final resp = await _api.post('/plan-event/reject/${e.propuestaId}', {});
      emit(PlanEventSuccess(resp['message'] ?? 'Propuesta rechazada.'));
    } catch (e) {
      emit(PlanEventFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}