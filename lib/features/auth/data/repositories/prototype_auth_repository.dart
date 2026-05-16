import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:amethyst/features/auth/domain/repositories/auth_repository.dart';

final class PrototypeAuthRepository implements AuthRepository {
  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    throw ApiException(
      'Use role preview buttons on the login screen.',
      code: 'UI_ONLY',
    );
  }

  @override
  Future<UserEntity> loadCurrentUser() async {
    final UserEntity? user = PrototypeSession.current;
    if (user == null) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    return user;
  }

  @override
  Future<void> logout() async {
    PrototypeSession.signOut();
  }
}
