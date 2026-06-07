import 'package:amethyst/features/station_cash/domain/repositories/station_cash_repository.dart';

final class GetStationCashBalanceUseCase {
  const GetStationCashBalanceUseCase(this._repository);

  final StationCashRepository _repository;

  Future<double> call() => _repository.getBalanceAmount();
}
