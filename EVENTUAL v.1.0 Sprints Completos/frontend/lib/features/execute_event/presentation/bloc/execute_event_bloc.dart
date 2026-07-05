import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// ── Events ────────────────────────────────────────────────
abstract class ExecuteEventEvent extends Equatable {
  @override List<Object?> get props => [];
}
class ExecuteEventLoadActive extends ExecuteEventEvent {}
class ExecuteEventLoadList extends ExecuteEventEvent {
  final String eventoId;
  ExecuteEventLoadList(this.eventoId);
  @override List<Object?> get props => [eventoId];
}
class ExecuteEventLoadSummary extends ExecuteEventEvent {
  final String eventoId;
  ExecuteEventLoadSummary(this.eventoId);
  @override List<Object?> get props => [eventoId];
}
class ExecuteEventRegisterAttendance extends ExecuteEventEvent {
  final String eventoId;
  final String socioId;
  final String tipoRegistro;
  final int numAcompanantes;
  final String? observaciones;
  ExecuteEventRegisterAttendance({
    required this.eventoId,
    required this.socioId,
    this.tipoRegistro = 'Manual',
    this.numAcompanantes = 0,
    this.observaciones,
  });
  @override List<Object?> get props => [eventoId, socioId];
}
class ExecuteEventClose extends ExecuteEventEvent {
  final String eventoId;
  ExecuteEventClose(this.eventoId);
  @override List<Object?> get props => [eventoId];
}

// ── States ────────────────────────────────────────────────
abstract class ExecuteEventState extends Equatable {
  @override List<Object?> get props => [];
}
class ExecuteEventInitial extends ExecuteEventState {}
class ExecuteEventLoading extends ExecuteEventState {}

class ExecuteEventActiveLoaded extends ExecuteEventState {
  final List<dynamic> eventos;
  ExecuteEventActiveLoaded(this.eventos);
  @override List<Object?> get props => [eventos];
}

class ExecuteEventListLoaded extends ExecuteEventState {
  final List<dynamic> confirmados;
  final List<dynamic> noConfirmados;
  final int totalPresentes;
  final int totalConfirmados;
  final String eventoId;
  ExecuteEventListLoaded({
    required this.confirmados,
    required this.noConfirmados,
    required this.totalPresentes,
    required this.totalConfirmados,
    required this.eventoId,
  });
  @override List<Object?> get props => [confirmados, noConfirmados, totalPresentes];
}

class ExecuteEventSummaryLoaded extends ExecuteEventState {
  final Map<String, dynamic> evento;
  final Map<String, dynamic> resumen;
  ExecuteEventSummaryLoaded(this.evento, this.resumen);
  @override List<Object?> get props => [evento, resumen];
}

class ExecuteEventAttendanceSuccess extends ExecuteEventState {
  final String message;
  final int totalPresentes;
  final String eventoId;
  ExecuteEventAttendanceSuccess(this.message, this.totalPresentes, this.eventoId);
  @override List<Object?> get props => [message, totalPresentes];
}

class ExecuteEventCloseSuccess extends ExecuteEventState {
  final String message;
  final double tasaParticipacion;
  ExecuteEventCloseSuccess(this.message, this.tasaParticipacion);
  @override List<Object?> get props => [message];
}

class ExecuteEventFailure extends ExecuteEventState {
  final String error;
  ExecuteEventFailure(this.error);
  @override List<Object?> get props => [error];
}

// ── BLoC ──────────────────────────────────────────────────
class ExecuteEventBloc extends Bloc<ExecuteEventEvent, ExecuteEventState> {
  final ApiClient _api;

  ExecuteEventBloc(this._api) : super(ExecuteEventInitial()) {
    on<ExecuteEventLoadActive>(_onLoadActive);
    on<ExecuteEventLoadList>(_onLoadList);
    on<ExecuteEventLoadSummary>(_onLoadSummary);
    on<ExecuteEventRegisterAttendance>(_onRegisterAttendance);
    on<ExecuteEventClose>(_onClose);
  }

  Future<void> _onLoadActive(
    ExecuteEventLoadActive e, Emitter<ExecuteEventState> emit) async {
    emit(ExecuteEventLoading());
    try {
      final resp = await _api.get('/execute-event/active');
      emit(ExecuteEventActiveLoaded(resp['eventos'] ?? []));
    } catch (e) {
      emit(ExecuteEventFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadList(
    ExecuteEventLoadList e, Emitter<ExecuteEventState> emit) async {
    emit(ExecuteEventLoading());
    try {
      final resp = await _api.get('/execute-event/${e.eventoId}/attendance-list');
      emit(ExecuteEventListLoaded(
        confirmados: resp['confirmados'] ?? [],
        noConfirmados: resp['no_confirmados'] ?? [],
        totalPresentes: resp['total_presentes'] ?? 0,
        totalConfirmados: resp['total_confirmados'] ?? 0,
        eventoId: e.eventoId,
      ));
    } catch (e) {
      emit(ExecuteEventFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadSummary(
    ExecuteEventLoadSummary e, Emitter<ExecuteEventState> emit) async {
    emit(ExecuteEventLoading());
    try {
      final resp = await _api.get('/execute-event/${e.eventoId}/summary');
      emit(ExecuteEventSummaryLoaded(
        resp['evento'] as Map<String, dynamic>,
        resp['resumen'] as Map<String, dynamic>,
      ));
    } catch (e) {
      emit(ExecuteEventFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRegisterAttendance(
    ExecuteEventRegisterAttendance e, Emitter<ExecuteEventState> emit) async {
    emit(ExecuteEventLoading());
    try {
      final resp = await _api.post(
        '/execute-event/${e.eventoId}/register-attendance',
        {
          'socio_id': e.socioId,
          'tipo_registro': e.tipoRegistro,
          'num_acompanantes_presentes': e.numAcompanantes,
          if (e.observaciones != null) 'observaciones': e.observaciones,
        },
      );
      emit(ExecuteEventAttendanceSuccess(
        resp['message'] ?? 'Asistencia registrada',
        resp['total_presentes'] ?? 0,
        e.eventoId,
      ));
    } catch (e) {
      emit(ExecuteEventFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onClose(
    ExecuteEventClose e, Emitter<ExecuteEventState> emit) async {
    emit(ExecuteEventLoading());
    try {
      final resp = await _api.patch('/execute-event/${e.eventoId}/close');
      emit(ExecuteEventCloseSuccess(
        resp['message'] ?? 'Evento cerrado exitosamente',
        (resp['tasa_participacion'] as num?)?.toDouble() ?? 0,
      ));
    } catch (e) {
      emit(ExecuteEventFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}