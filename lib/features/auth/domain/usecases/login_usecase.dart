import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:amethyst/features/auth/domain/repositories/auth_repository.dart';

final class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}
