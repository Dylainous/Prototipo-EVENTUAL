import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// ── Events ────────────────────────────────────────────────
abstract class BroadcastEvent extends Equatable {
  @override List<Object?> get props => [];
}

class BroadcastLoadEvents extends BroadcastEvent {}

class BroadcastLoadTemplate extends BroadcastEvent {
  final String eventoId;
  BroadcastLoadTemplate(this.eventoId);
  @override List<Object?> get props => [eventoId];
}

class BroadcastSubmitted extends BroadcastEvent {
  final String eventoId;
  final String mensaje;
  final List<String> canales;
  final bool esInmediata;
  final String? fechaEnvio;
  final List<int> recordatorios;

  BroadcastSubmitted({
    required this.eventoId,
    required this.mensaje,
    required this.canales,
    required this.esInmediata,
    this.fechaEnvio,
    required this.recordatorios,
  });

  @override List<Object?> get props => [eventoId, mensaje];
}

// ── States ────────────────────────────────────────────────
abstract class BroadcastState extends Equatable {
  @override List<Object?> get props => [];
}

class BroadcastInitial extends BroadcastState {}
class BroadcastLoading extends BroadcastState {}

class BroadcastEventsLoaded extends BroadcastState {
  final List<dynamic> eventos;
  BroadcastEventsLoaded(this.eventos);
  @override List<Object?> get props => [eventos];
}

class BroadcastTemplateLoaded extends BroadcastState {
  final String plantilla;
  final Map<String, dynamic> evento;
  BroadcastTemplateLoaded(this.plantilla, this.evento);
  @override List<Object?> get props => [plantilla, evento];
}

class BroadcastSuccess extends BroadcastState {
  final String message;
  final int sociosNotificados;
  BroadcastSuccess(this.message, this.sociosNotificados);
  @override List<Object?> get props => [message];
}

class BroadcastFailure extends BroadcastState {
  final String error;
  BroadcastFailure(this.error);
  @override List<Object?> get props => [error];
}

// ── BLoC ──────────────────────────────────────────────────
class BroadcastBloc extends Bloc<BroadcastEvent, BroadcastState> {
  final ApiClient _api;

  BroadcastBloc(this._api) : super(BroadcastInitial()) {
    on<BroadcastLoadEvents>(_onLoadEvents);
    on<BroadcastLoadTemplate>(_onLoadTemplate);
    on<BroadcastSubmitted>(_onSubmit);
  }

  Future<void> _onLoadEvents(
    BroadcastLoadEvents event,
    Emitter<BroadcastState> emit,
  ) async {
    emit(BroadcastLoading());
    try {
      final resp = await _api.get('/broadcast/events');
      emit(BroadcastEventsLoaded(resp['eventos'] ?? []));
    } catch (e) {
      emit(BroadcastFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadTemplate(
    BroadcastLoadTemplate event,
    Emitter<BroadcastState> emit,
  ) async {
    emit(BroadcastLoading());
    try {
      final resp = await _api.get('/broadcast/events/${event.eventoId}/template');
      emit(BroadcastTemplateLoaded(
        resp['plantilla'] ?? '',
        resp['evento'] as Map<String, dynamic>,
      ));
    } catch (e) {
      emit(BroadcastFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onSubmit(
    BroadcastSubmitted event,
    Emitter<BroadcastState> emit,
  ) async {
    emit(BroadcastLoading());
    try {
      final body = <String, dynamic>{
        'evento_id': event.eventoId,
        'mensaje': event.mensaje,
        'canales': event.canales,
        'es_inmediata': event.esInmediata,
        'recordatorios': event.recordatorios,
        if (!event.esInmediata && event.fechaEnvio != null)
          'fecha_envio': event.fechaEnvio,
      };
      final resp = await _api.post('/broadcast', body);
      emit(BroadcastSuccess(
        resp['message'] ?? 'Información del evento difundida correctamente.',
        resp['socios_notificados'] ?? 0,
      ));
    } catch (e) {
      emit(BroadcastFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}