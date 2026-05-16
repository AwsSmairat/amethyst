import 'package:amethyst/core/firebase/firebase_auth_service.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:amethyst/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required FirebaseAuthService authService})
      : _authService = authService;

  final FirebaseAuthService _authService;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) =>
      _authService.login(email: email, password: password);

  @override
  Future<UserEntity> loadCurrentUser() => _authService.loadCurrentUser();

  @override
  Future<void> logout() => _authService.logout();
}
