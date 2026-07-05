// lib/features/events/presentation/bloc/events_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/event_entity.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/strategy.dart';

// ── Events ──────────────────────────────────────────────────
abstract class EventsEvent extends Equatable {
  @override List<Object?> get props => [];
}

class EventsLoadRequested extends EventsEvent {
  final EventFilterStrategy? strategy;
  EventsLoadRequested({this.strategy});
  @override List<Object?> get props => [strategy?.label];
}

class EventsFilterChanged extends EventsEvent {
  final EventFilterStrategy strategy;
  EventsFilterChanged(this.strategy);
  @override List<Object?> get props => [strategy.label];
}

class EventsDetailRequested extends EventsEvent {
  final String id;
  EventsDetailRequested(this.id);
  @override List<Object?> get props => [id];
}

// ── States ──────────────────────────────────────────────────
abstract class EventsState extends Equatable {
  @override List<Object?> get props => [];
}
class EventsInitial extends EventsState {}
class EventsLoading extends EventsState {}
class EventsLoaded extends EventsState {
  final List<EventEntity> events;
  final String filterLabel;
  EventsLoaded(this.events, this.filterLabel);
  @override List<Object?> get props => [events, filterLabel];
}
class EventDetailLoaded extends EventsState {
  final EventEntity event;
  EventDetailLoaded(this.event);
  @override List<Object?> get props => [event];
}
class EventsEmpty extends EventsState {}
class EventsError extends EventsState {
  final String message;
  EventsError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final ApiClient _api;

  final EventFilterContext _filterContext =
      EventFilterContext(const AllEventsStrategy());

  EventsBloc(this._api) : super(EventsInitial()) {
    on<EventsLoadRequested>(_onLoad);
    on<EventsFilterChanged>(_onFilterChanged);
    on<EventsDetailRequested>(_onDetailRequested);
  }

  Future<void> _onLoad(EventsLoadRequested e, Emitter<EventsState> emit) async {
    if (e.strategy != null) _filterContext.setStrategy(e.strategy!);
    await _fetchEvents(emit);
  }

  Future<void> _onFilterChanged(
      EventsFilterChanged e, Emitter<EventsState> emit) async {
    _filterContext.setStrategy(e.strategy);
    await _fetchEvents(emit);
  }

  Future<void> _onDetailRequested(
      EventsDetailRequested e, Emitter<EventsState> emit) async {
    emit(EventsLoading());
    try {
      final body = await _api.get('${ApiConstants.events}/${e.id}');
      final ev = _mapEvent(body['evento'] as Map<String, dynamic>);
      emit(EventDetailLoaded(ev));
    } catch (_) {
      emit(EventsError('Sin conexión'));
    }
  }

  Future<void> _fetchEvents(Emitter<EventsState> emit) async {
    emit(EventsLoading());
    try {
      final params = _filterContext.buildParams();
      final queryString = params.isEmpty
          ? ''
          : '?' +
              params.entries
                  .where((e) => e.value != null)
                  .map((e) => '${e.key}=${e.value}')
                  .join('&');

      final res = await _api.get('${ApiConstants.events}$queryString');
      final list = (res['eventos'] as List)
          .map((e) => _mapEvent(e as Map<String, dynamic>))
          .toList();
          
      if (list.isEmpty) {
        emit(EventsEmpty());
      } else {
        emit(EventsLoaded(list, _filterContext.currentLabel));
      }
    } catch (_) {
      emit(EventsError('Sin conexión'));
    }
  }

  EventEntity _mapEvent(Map<String, dynamic> j) => EventEntity(
        id: j['id'],
        nombre: j['nombre'],
        tipoEvento: j['tipo_evento'],
        descripcion: j['descripcion'],
        fecha: DateTime.parse(j['fecha']),
        hora: j['hora'],
        lugar: j['lugar'],
        estado: j['estado'],
      );
}