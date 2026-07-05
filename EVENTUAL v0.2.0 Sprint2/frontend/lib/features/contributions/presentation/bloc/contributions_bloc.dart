import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// ── Events ────────────────────────────────────────────────
abstract class ContributionsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ContributionsPendingRequested extends ContributionsEvent {}

class ContributionSubmitted extends ContributionsEvent {
  final String socioId;
  final String metodoPago;
  final double monto;
  final String fechaPago;
  final String estado;
  final String? observaciones;
  final String? comprobante;

  ContributionSubmitted({
    required this.socioId,
    required this.metodoPago,
    required this.monto,
    required this.fechaPago,
    required this.estado,
    this.observaciones,
    this.comprobante,
  });

  @override
  List<Object?> get props => [socioId, monto, metodoPago];
}

// ── States ────────────────────────────────────────────────
abstract class ContributionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ContributionsInitial extends ContributionsState {}

class ContributionsLoading extends ContributionsState {}

class ContributionsLoaded extends ContributionsState {
  final List<dynamic> pendientes;
  final double cuotaEstandar;
  final String periodo;

  ContributionsLoaded({
    required this.pendientes,
    required this.cuotaEstandar,
    required this.periodo,
  });

  @override
  List<Object?> get props => [pendientes, periodo];
}

class ContributionSuccess extends ContributionsState {
  final String message;
  ContributionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class ContributionFailure extends ContributionsState {
  final String error;
  ContributionFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// ── BLoC ──────────────────────────────────────────────────
class ContributionsBloc
    extends Bloc<ContributionsEvent, ContributionsState> {
  final ApiClient _api;

  ContributionsBloc(this._api) : super(ContributionsInitial()) {
    on<ContributionsPendingRequested>(_onLoadPending);
    on<ContributionSubmitted>(_onSubmit);
  }

  Future<void> _onLoadPending(
    ContributionsPendingRequested event,
    Emitter<ContributionsState> emit,
  ) async {
    emit(ContributionsLoading());
    try {
      final resp = await _api.get('/contributions/pending');
      emit(ContributionsLoaded(
        pendientes: resp['pendientes'] ?? [],
        cuotaEstandar: (resp['cuota_estandar'] ?? 20.0).toDouble(),
        periodo: resp['periodo'] ?? '',
      ));
    } catch (e) {
      emit(ContributionFailure(e.toString()));
    }
  }

  Future<void> _onSubmit(
    ContributionSubmitted event,
    Emitter<ContributionsState> emit,
  ) async {
    emit(ContributionsLoading());
    try {
      final resp = await _api.post('/contributions', {
        'socio_id': event.socioId,
        'metodo_pago': event.metodoPago,
        'monto': event.monto,
        'fecha_pago': event.fechaPago,
        'estado': event.estado,
        if (event.observaciones != null)
          'observaciones': event.observaciones,
        if (event.comprobante != null) 'comprobante': event.comprobante,
      });
      emit(ContributionSuccess(
          resp['message'] ?? 'Aporte registrado exitosamente'));
    } catch (e) {
      emit(ContributionFailure(e.toString()));
    }
  }
}
