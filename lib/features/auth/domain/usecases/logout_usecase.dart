import 'package:amethyst/features/auth/domain/repositories/auth_repository.dart';

final class LogoutUseCase {
  LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
