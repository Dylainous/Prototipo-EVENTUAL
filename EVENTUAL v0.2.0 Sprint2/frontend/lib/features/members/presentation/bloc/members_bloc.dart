// lib/features/members/presentation/bloc/members_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/member_entity.dart';
import '../../data/models/member_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/observer.dart';

// ── Events ──────────────────────────────────────────────────
abstract class MembersEvent extends Equatable {
  @override List<Object?> get props => [];
}
class MembersLoadRequested extends MembersEvent {}
class MembersLoadRolesRequested extends MembersEvent {}
class MemberCreateRequested extends MembersEvent {
  final Map<String, dynamic> data;
  MemberCreateRequested(this.data);
  @override List<Object?> get props => [data];
}
class MemberUpdateRequested extends MembersEvent {
  final String id;
  final Map<String, dynamic> data;
  MemberUpdateRequested(this.id, this.data);
  @override List<Object?> get props => [id, data];
}
class MemberAssignRoleRequested extends MembersEvent {
  final String id;
  final int rolId;
  MemberAssignRoleRequested(this.id, this.rolId);
  @override List<Object?> get props => [id, rolId];
}
class MemberDeactivateRequested extends MembersEvent {
  final String id;
  MemberDeactivateRequested(this.id);
  @override List<Object?> get props => [id];
}

// ── States ──────────────────────────────────────────────────
abstract class MembersState extends Equatable {
  @override List<Object?> get props => [];
}
class MembersInitial extends MembersState {}
class MembersLoading extends MembersState {}
class MembersLoaded extends MembersState {
  final List<MemberEntity> members;
  final List<RoleEntity> roles;
  MembersLoaded(this.members, this.roles);
  @override List<Object?> get props => [members, roles];
}
class MembersOperationSuccess extends MembersState {
  final String message;
  MembersOperationSuccess(this.message);
  @override List<Object?> get props => [message];
}
class MembersError extends MembersState {
  final String message;
  MembersError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────
class MembersBloc extends Bloc<MembersEvent, MembersState> {
  final ApiClient _api;
  List<MemberEntity> _members = [];
  List<RoleEntity> _roles = [];

  MembersBloc(this._api) : super(MembersInitial()) {
    on<MembersLoadRequested>(_onLoad);
    on<MembersLoadRolesRequested>(_onLoadRoles);
    on<MemberCreateRequested>(_onCreate);
    on<MemberUpdateRequested>(_onUpdate);
    on<MemberAssignRoleRequested>(_onAssignRole);
    on<MemberDeactivateRequested>(_onDeactivate);
  }

  Future<void> _onLoad(MembersLoadRequested e, Emitter<MembersState> emit) async {
    emit(MembersLoading());
    try {
      // El ApiClient ya devuelve el Map directamente
      final body = await _api.get(ApiConstants.members);
      _members = (body['members'] as List)
          .map((j) => MemberModel.fromJson(j as Map<String, dynamic>))
          .toList();
      emit(MembersLoaded(_members, _roles));
    } catch (_) {
      // Si el ApiClient lanza una excepción (ej. status != 2xx o error de red), cae aquí
      emit(MembersError('Sin conexión'));
    }
  }

  Future<void> _onLoadRoles(MembersLoadRolesRequested e, Emitter<MembersState> emit) async {
    try {
      final body = await _api.get(ApiConstants.membersRoles);
      _roles = (body['roles'] as List)
          .map((j) => RoleModel.fromJson(j as Map<String, dynamic>))
          .toList();
      emit(MembersLoaded(_members, _roles));
    } catch (_) {}
  }

  Future<void> _onCreate(MemberCreateRequested e, Emitter<MembersState> emit) async {
    emit(MembersLoading());
    try {
      final body = await _api.post(ApiConstants.members, e.data);
      emit(MembersOperationSuccess(body['message'] ?? 'Socio creado exitosamente'));
      add(MembersLoadRequested());
    } catch (_) {
      emit(MembersError('Sin conexión'));
    }
  }

  Future<void> _onUpdate(MemberUpdateRequested e, Emitter<MembersState> emit) async {
    emit(MembersLoading());
    try {
      final body = await _api.put('${ApiConstants.members}/${e.id}', e.data);
      AppEventBus().emit(AppEventBus.memberUpdated, body['member']);
      emit(MembersOperationSuccess(body['message'] ?? 'Socio actualizado'));
      add(MembersLoadRequested());
    } catch (_) {
      emit(MembersError('Sin conexión'));
    }
  }

  Future<void> _onAssignRole(MemberAssignRoleRequested e, Emitter<MembersState> emit) async {
    emit(MembersLoading());
    try {
      final body = await _api.patch(
        '${ApiConstants.members}/${e.id}/role',
        body: {'rol_id': e.rolId},
      );
      AppEventBus().emit(AppEventBus.memberUpdated, body['member']);
      emit(MembersOperationSuccess(body['message'] ?? 'Rol asignado correctamente'));
      add(MembersLoadRequested());
    } catch (_) {
      emit(MembersError('Sin conexión'));
    }
  }

  Future<void> _onDeactivate(MemberDeactivateRequested e, Emitter<MembersState> emit) async {
    emit(MembersLoading());
    try {
      final body = await _api.patch('${ApiConstants.members}/${e.id}/deactivate');
      AppEventBus().emit(AppEventBus.memberDeactivated, e.id);
      emit(MembersOperationSuccess(body['message'] ?? 'Socio desactivado'));
      add(MembersLoadRequested());
    } catch (_) {
      emit(MembersError('Sin conexión'));
    }
  }
}