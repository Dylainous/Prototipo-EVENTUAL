import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// ── Events ──────────────────────────────────────────────────
abstract class AttendanceEvent extends Equatable {
  @override List<Object?> get props => [];
}
class AttendanceLoadRequested extends AttendanceEvent {
  final String eventoId;
  AttendanceLoadRequested(this.eventoId);
  @override List<Object?> get props => [eventoId];
}
class AttendanceSubmitted extends AttendanceEvent {
  final String eventoId;
  final bool asiste;
  final int numAcompanantes;
  final List<Map<String, dynamic>> acompanantes;
  final String? comentarios;
  AttendanceSubmitted({
    required this.eventoId,
    required this.asiste,
    this.numAcompanantes = 0,
    this.acompanantes = const [],
    this.comentarios,
  });
  @override List<Object?> get props => [eventoId, asiste];
}

// ── States ──────────────────────────────────────────────────
abstract class AttendanceState extends Equatable {
  @override List<Object?> get props => [];
}
class AttendanceInitial extends AttendanceState {}
class AttendanceLoading extends AttendanceState {}
class AttendanceLoaded extends AttendanceState {
  final Map<String, dynamic>? confirmacion;
  AttendanceLoaded(this.confirmacion);
  @override List<Object?> get props => [confirmacion];
}
class AttendanceSuccess extends AttendanceState {
  final String message;
  AttendanceSuccess(this.message);
  @override List<Object?> get props => [message];
}
class AttendanceFailure extends AttendanceState {
  final String error;
  AttendanceFailure(this.error);
  @override List<Object?> get props => [error];
}

// ── BLoC ────────────────────────────────────────────────────
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final ApiClient _api;

  AttendanceBloc(this._api) : super(AttendanceInitial()) {
    on<AttendanceLoadRequested>(_onLoad);
    on<AttendanceSubmitted>(_onSubmit);
  }

  Future<void> _onLoad(AttendanceLoadRequested event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      // El ApiClient ya devuelve el Map, asignamos a "body" y lo usamos directo
      final body = await _api.get('/attendance/${event.eventoId}/mine');
      emit(AttendanceLoaded(body['confirmacion'] as Map<String, dynamic>?));
    } catch (_) {
      emit(AttendanceLoaded(null));
    }
  }

  Future<void> _onSubmit(AttendanceSubmitted event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      // Pasamos los datos y recibimos el Map directamente
      final body = await _api.post('/attendance', {
        'evento_id': event.eventoId,
        'asiste': event.asiste,
        'num_acompanantes': event.numAcompanantes,
        'acompanantes': event.acompanantes,
        'comentarios': event.comentarios,
      });
      
      emit(AttendanceSuccess(body['message'] ?? 'Confirmación registrada'));
    } catch (e) {
      // Limpiamos el texto de la excepción para que el usuario no vea "Exception: "
      emit(AttendanceFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}