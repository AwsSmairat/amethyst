import 'package:amethyst/features/station_cash/domain/repositories/station_cash_repository.dart';

final class SetStationCashBalanceUseCase {
  const SetStationCashBalanceUseCase(this._repository);

  final StationCashRepository _repository;

  Future<void> call({
    required double amount,
    String? note,
  }) =>
      _repository.setBalance(amount: amount, note: note);
}
