import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:amethyst/features/auth/domain/repositories/auth_repository.dart';

final class LoadSessionUseCase {
  LoadSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call() => _repository.loadCurrentUser();
}
