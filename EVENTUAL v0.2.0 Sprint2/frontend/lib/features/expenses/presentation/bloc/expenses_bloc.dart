import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// ── Events ────────────────────────────────────────────────
abstract class ExpensesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ExpensesLoadRequested extends ExpensesEvent {
  final String eventoId;
  ExpensesLoadRequested(this.eventoId);
  @override
  List<Object?> get props => [eventoId];
}

class ExpenseSubmitted extends ExpensesEvent {
  final String eventoId;
  final String categoria;
  final double monto;
  final String fechaGasto;
  final String metodoPago;
  final String descripcion;
  final String responsable;
  final String? proveedor;

  ExpenseSubmitted({
    required this.eventoId,
    required this.categoria,
    required this.monto,
    required this.fechaGasto,
    required this.metodoPago,
    required this.descripcion,
    required this.responsable,
    this.proveedor,
  });

  @override
  List<Object?> get props => [eventoId, monto, categoria];
}

// ── States ────────────────────────────────────────────────
abstract class ExpensesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ExpensesInitial extends ExpensesState {}

class ExpensesLoading extends ExpensesState {}

class ExpensesLoaded extends ExpensesState {
  final List<dynamic> gastos;
  ExpensesLoaded(this.gastos);
  @override
  List<Object?> get props => [gastos];
}

class ExpenseSuccess extends ExpensesState {
  final String message;
  final String? alertaPresupuesto;
  ExpenseSuccess(this.message, {this.alertaPresupuesto});
  @override
  List<Object?> get props => [message];
}

class ExpenseFailure extends ExpensesState {
  final String error;
  ExpenseFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// ── BLoC ──────────────────────────────────────────────────
class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  final ApiClient _api;

  ExpensesBloc(this._api) : super(ExpensesInitial()) {
    on<ExpensesLoadRequested>(_onLoad);
    on<ExpenseSubmitted>(_onSubmit);
  }

  Future<void> _onLoad(
    ExpensesLoadRequested event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(ExpensesLoading());
    try {
      final resp = await _api.get('/expenses/${event.eventoId}');
      emit(ExpensesLoaded(resp['gastos'] ?? []));
    } catch (e) {
      emit(ExpenseFailure(e.toString()));
    }
  }

  Future<void> _onSubmit(
    ExpenseSubmitted event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(ExpensesLoading());
    try {
      final resp = await _api.post('/expenses', {
        'evento_id': event.eventoId,
        'categoria': event.categoria,
        'monto': event.monto,
        'fecha_gasto': event.fechaGasto,
        'metodo_pago': event.metodoPago,
        'descripcion': event.descripcion,
        'responsable': event.responsable,
        if (event.proveedor != null) 'proveedor': event.proveedor,
      });
      emit(ExpenseSuccess(
        resp['message'] ?? 'Gasto registrado exitosamente',
        alertaPresupuesto: resp['alerta_presupuesto'],
      ));
    } catch (e) {
      emit(ExpenseFailure(e.toString()));
    }
  }
}
