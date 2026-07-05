// lib/core/di/injection.dart
// Inyección de dependencias con get_it (Service Locator)
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../network/api_client.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/members/presentation/bloc/members_bloc.dart';
import '../../features/events/presentation/bloc/events_bloc.dart';
import '../../features/proposals/presentation/bloc/proposals_bloc.dart';

import '../../features/contributions/presentation/bloc/contributions_bloc.dart';
import '../../features/expenses/presentation/bloc/expenses_bloc.dart';
import '../../features/event_registration/presentation/bloc/event_registration_bloc.dart';
// (AttendanceBloc ya fue indicado en el mensaje anterior)
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';

import '../../features/plan_event/presentation/bloc/plan_event_bloc.dart';

import '../../features/broadcast/presentation/bloc/broadcast_bloc.dart';

import '../../features/execute_event/presentation/bloc/execute_event_bloc.dart';

import '../../features/reports/presentation/bloc/reports_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Infraestructura ─────────────────────────────────────
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => ApiClient(sl<http.Client>()));

  // ── Repositorios ─────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<ApiClient>()),
  );

  // ── BLoCs (factory: nueva instancia por ruta) ────────────
  sl.registerFactory(() => AuthBloc(sl<AuthRepository>()));
  sl.registerFactory(() => MembersBloc(sl<ApiClient>()));
  sl.registerFactory(() => EventsBloc(sl<ApiClient>()));
  sl.registerFactory(() => ProposalsBloc(sl<ApiClient>()));
  
  sl.registerFactory(() => AttendanceBloc(sl()));
  sl.registerFactory(() => ContributionsBloc(sl()));
  sl.registerFactory(() => ExpensesBloc(sl()));
  sl.registerFactory(() => EventRegistrationBloc(sl()));

  sl.registerFactory(() => PlanEventBloc(sl()));

  sl.registerFactory(() => BroadcastBloc(sl()));

  sl.registerFactory(() => ExecuteEventBloc(sl()));

  sl.registerFactory(() => ReportsBloc(sl()));
}
