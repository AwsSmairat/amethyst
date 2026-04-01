import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/storage/secure_token_storage.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:amethyst/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AmethystApi api,
    required TokenStorage tokenStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage;

  final AmethystApi _api;
  final TokenStorage _tokenStorage;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.login(email: email, password: password);
    final token = data['token'] as String;
    await _tokenStorage.writeToken(token);
    return UserEntity.fromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserEntity> loadCurrentUser() async {
    final data = await _api.me();
    return UserEntity.fromJson(data);
  }

  @override
  Future<void> logout() => _tokenStorage.deleteToken();
}
