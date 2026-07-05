// lib/features/events/presentation/bloc/event_registration_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// ── Events ──────────────────────────────────────────────────
abstract class EventRegistrationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class EventRegistrationRequested extends EventRegistrationEvent {
  final String eventoId;
  EventRegistrationRequested(this.eventoId);
  @override
  List<Object?> get props => [eventoId];
}

// ── States ──────────────────────────────────────────────────
abstract class EventRegistrationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EventRegistrationInitial extends EventRegistrationState {}

class EventRegistrationLoading extends EventRegistrationState {}

class EventRegistrationSuccess extends EventRegistrationState {
  final String message;
  final String codigoEvento;
  EventRegistrationSuccess(this.message, this.codigoEvento);
  @override
  List<Object?> get props => [message, codigoEvento];
}

class EventRegistrationFailure extends EventRegistrationState {
  final String error;
  EventRegistrationFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// ── BLoC ────────────────────────────────────────────────────
class EventRegistrationBloc
    extends Bloc<EventRegistrationEvent, EventRegistrationState> {
  final ApiClient _api;

  EventRegistrationBloc(this._api) : super(EventRegistrationInitial()) {
    on<EventRegistrationRequested>(_onRegister);
  }

  Future<void> _onRegister(
    EventRegistrationRequested event,
    Emitter<EventRegistrationState> emit,
  ) async {
    emit(EventRegistrationLoading());
    try {
      // Recibimos el Map directamente desde el ApiClient
      final body = await _api.patch('/events/${event.eventoId}/register');
      
      emit(EventRegistrationSuccess(
        body['message'] ?? 'Evento registrado exitosamente',
        body['codigo_evento'] ?? '',
      ));
    } catch (e) {
      // Formateamos el mensaje de error quitando el prefijo "Exception: "
      emit(EventRegistrationFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}