import 'package:amethyst/features/station_cash/domain/entities/station_cash_balance_snapshot.dart';
import 'package:amethyst/features/station_cash/domain/repositories/station_cash_repository.dart';

final class GetStationCashSnapshotUseCase {
  const GetStationCashSnapshotUseCase(this._repository);

  final StationCashRepository _repository;

  Future<StationCashBalanceSnapshot> call() => _repository.getBalanceSnapshot();
}
