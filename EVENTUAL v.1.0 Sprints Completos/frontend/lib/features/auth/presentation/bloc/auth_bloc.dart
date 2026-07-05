// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// ── Events ──────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String cedula;
  final String password;
  AuthLoginRequested(this.cedula, this.password);
  @override
  List<Object?> get props => [cedula, password];
}

class AuthCheckRequested extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}

// ── States ──────────────────────────────────────────────────
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
class AuthBlocked extends AuthState {
  final String message;
  AuthBlocked(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event, Emitter<AuthState> emit) async {
    final user = await _authRepository.getStoredUser();
    if (user != null && user.token.isNotEmpty) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.login(
      cedula: event.cedula,
      password: event.password,
    );
    if (result.failure == null) {
      emit(AuthAuthenticated(result.user));
    } else {
      final msg = result.failure!.message;
      if (msg.contains('bloqueada')) {
        emit(AuthBlocked(msg));
      } else {
        emit(AuthError(msg));
      }
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
