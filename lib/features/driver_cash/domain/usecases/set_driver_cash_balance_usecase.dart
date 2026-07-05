import 'package:amethyst/features/driver_cash/domain/repositories/driver_cash_repository.dart';

final class SetDriverCashBalanceUseCase {
  const SetDriverCashBalanceUseCase(this._repository);

  final DriverCashRepository _repository;

  Future<void> call({
    required double amount,
    String? note,
  }) =>
      _repository.setBalance(amount: amount, note: note);
}
