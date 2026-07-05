// lib/features/proposals/presentation/bloc/proposals_bloc.dart
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/observer.dart'; // Observer pattern

// ── Entity ───────────────────────────────────────────────────
class ProposalEntity {
  final String id;
  final String tipoEvento;
  final String descripcion;
  final String fechaSugerida;
  final String justificacion;
  final String estado;
  final String numeroSeguimiento;
  final String fechaRegistro;

  const ProposalEntity({
    required this.id,
    required this.tipoEvento,
    required this.descripcion,
    required this.fechaSugerida,
    required this.justificacion,
    required this.estado,
    required this.numeroSeguimiento,
    required this.fechaRegistro,
  });

  factory ProposalEntity.fromJson(Map<String, dynamic> j) => ProposalEntity(
        id: j['id'],
        tipoEvento: j['tipo_evento'],
        descripcion: j['descripcion'],
        fechaSugerida: j['fecha_sugerida'],
        justificacion: j['justificacion'] ?? '',
        estado: j['estado'],
        numeroSeguimiento: j['numero_seguimiento'] ?? '',
        fechaRegistro: j['fecha_registro'] ?? '',
      );
}

// ── Events ──────────────────────────────────────────────────
abstract class ProposalsEvent extends Equatable {
  @override List<Object?> get props => [];
}
class ProposalsLoadMine extends ProposalsEvent {}
class ProposalSubmitRequested extends ProposalsEvent {
  final String tipoEvento;
  final String descripcion;
  final String fechaSugerida;
  final String justificacion;
  ProposalSubmitRequested({
    required this.tipoEvento,
    required this.descripcion,
    required this.fechaSugerida,
    required this.justificacion,
  });
  @override List<Object?> get props =>
      [tipoEvento, descripcion, fechaSugerida, justificacion];
}

// ── States ──────────────────────────────────────────────────
abstract class ProposalsState extends Equatable {
  @override List<Object?> get props => [];
}
class ProposalsInitial extends ProposalsState {}
class ProposalsLoading extends ProposalsState {}
class ProposalsLoaded extends ProposalsState {
  final List<ProposalEntity> proposals;
  ProposalsLoaded(this.proposals);
  @override List<Object?> get props => [proposals];
}
class ProposalSubmitSuccess extends ProposalsState {
  final String message;
  final String numeroSeguimiento;
  ProposalSubmitSuccess(this.message, this.numeroSeguimiento);
  @override List<Object?> get props => [message, numeroSeguimiento];
}
class ProposalsError extends ProposalsState {
  final String message;
  ProposalsError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────
class ProposalsBloc extends Bloc<ProposalsEvent, ProposalsState> {
  final ApiClient _api;

  ProposalsBloc(this._api) : super(ProposalsInitial()) {
    on<ProposalsLoadMine>(_onLoadMine);
    on<ProposalSubmitRequested>(_onSubmit);
  }

  Future<void> _onLoadMine(ProposalsLoadMine e, Emitter<ProposalsState> emit) async {
    emit(ProposalsLoading());
    try {
      final res = await _api.get(ApiConstants.myProposals);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['propuestas'] as List)
            .map((j) => ProposalEntity.fromJson(j))
            .toList();
        emit(ProposalsLoaded(list));
      } else {
        emit(ProposalsError('Error al cargar propuestas'));
      }
    } catch (_) {
      emit(ProposalsError('Sin conexión'));
    }
  }

  Future<void> _onSubmit(
      ProposalSubmitRequested e, Emitter<ProposalsState> emit) async {
    emit(ProposalsLoading());
    try {
      final res = await _api.post(ApiConstants.proposals, {
        'tipo_evento': e.tipoEvento,
        'descripcion': e.descripcion,
        'fecha_sugerida': e.fechaSugerida,
        'justificacion': e.justificacion,
      });

      final body = jsonDecode(res.body);
      if (res.statusCode == 201) {
        final propuesta = body['propuesta'] as Map<String, dynamic>;
        final numSeg = propuesta['numero_seguimiento'] ?? '';

        // Observer: emitir evento de propuesta creada para actualizar UI
        AppEventBus().emit(AppEventBus.proposalCreated, propuesta);

        emit(ProposalSubmitSuccess(body['message'] ?? 'Propuesta registrada', numSeg));
      } else {
        final errors = body['errors'] as List?;
        final msg = errors != null
            ? errors.map((e) => e['msg']).join('\n')
            : body['error'] ?? 'Error al enviar propuesta';
        emit(ProposalsError(msg));
      }
    } catch (_) {
      emit(ProposalsError('Sin conexión'));
    }
  }
}
