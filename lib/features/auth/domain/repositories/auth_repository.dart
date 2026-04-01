import 'package:amethyst/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> loadCurrentUser();
  Future<void> logout();
}
