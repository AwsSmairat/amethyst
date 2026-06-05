import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/prototype/prototype_sample_data.dart';
import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:amethyst/features/auth/domain/repositories/auth_repository.dart';

final class PrototypeAuthRepository implements AuthRepository {
  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    await PrototypeSampleData.ensureLoaded();
    final UserEntity? user = PrototypeSampleData.authenticate(
      email: email,
      password: password,
    );
    if (user == null) {
      throw ApiException(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        code: 'INVALID_CREDENTIALS',
      );
    }
    await PrototypeSession.signIn(user);
    return user;
  }

  @override
  Future<UserEntity> loadCurrentUser() async {
    await PrototypeSampleData.ensureLoaded();
    if (PrototypeSession.current != null) {
      return PrototypeSession.current!;
    }
    final bool restored = await PrototypeSession.restoreFromStorage();
    if (!restored || PrototypeSession.current == null) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    return PrototypeSession.current!;
  }

  @override
  Future<void> logout() async {
    await PrototypeSession.signOut();
  }
}
