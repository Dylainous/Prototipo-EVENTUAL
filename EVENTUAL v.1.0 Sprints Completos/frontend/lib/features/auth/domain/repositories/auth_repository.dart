// lib/features/auth/domain/repositories/auth_repository.dart
import '../entities/user_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class AuthRepository {
  Future<({UserEntity user, Failure? failure})> login({
    required String cedula,
    required String password,
  });

  Future<void> logout();
  Future<UserEntity?> getStoredUser();
}
